#include "converter.h"
#include "bytecode.h"
#include "da.h"
#include "debug.h"
#include "ffi.h"
#include "memory.h"
#include "opcodes.h"
#include "ops.h"
#include "symbols.h"
#include <assert.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern aint LtagHash(const char *s);

/*
 * Sentinel value for external references (both functions and globals).
 * Address = -index - 1, so index 0 becomes -1, index 1 becomes -2, etc.
 */
#define TO_EXT_REF(idx) (-(idx) - 1)
#define IS_EXT_REF(addr) ((addr) < 0)
#define EXT_REF_INDEX(addr) (-(addr) - 1)

#define GLOBAL_PREFIX "global_"

#define FFI_STUB_SIZE 2

typedef enum {
  INTERNAL, // internal call
  UNIT,     // inter-unit call
  FFI,      // FFI call
} reloc_kind;

typedef enum {
  TARGET_JUMP,    // must not land on function entry or EOF
  TARGET_CALL,    // must land on OP_BEGIN
  TARGET_CLOSURE, // must land on OP_BEGIN or OP_BEGIN_CLOSURE
} target_kind;

typedef struct {
  size_t patch_idx;
  const char *name;
  reloc_kind kind;
} reloc;

typedef struct fixup_node {
  struct fixup_node *next;
  size_t insn_idx;      // Index in code array that needs the jump target
  size_t origin_bc_off; // Source bytecode offset
} fixup_node;

// Metadata for each bytecode offset
typedef struct {
  insn *insn;           // NULL if not visited
  fixup_node *fixups;   // Linked list of forward jumps pointing here
  int32_t resolved_idx; // Index in generated code array (-1 if not visited)
  int32_t stack_depth;  // Expected stack depth (-1 if not visited yet)
  int32_t n_captured;   // n_captured for CLOSURE targets (-1 if not a target)
  int32_t func_idx; // Current function entry offset (-1 outside any function)
} meta_info;

typedef struct {
  insn *code;
  size_t code_len;
  int32_t *bc_to_insn_map;
  reloc *relocs;
  size_t relocs_len;
} decoded;

/*
 * Cache for external C globals..
 * Also used as GC root table.
 */
typedef struct {
  const char *name;
  void *ptr;
} ext_global_entry;

typedef struct {
  struct {
    ext_global_entry *data;
    size_t len;
    size_t cap;
  } entries;
} ext_global_cache;

/*
 * Different states of reachability for stack validation:
 * LIVE: currently decoding sequentially, reachable from previous instruction
 * BARRIER: just emitted JMP or END, so next instruction is reachable but not
 * from previous instruction
 */
typedef enum { LIVE, BARRIER } reach_state;

typedef struct {
  int32_t depth;
  reach_state state;
  int32_t max_depth;
  size_t max_depth_pos;
} stack_validation;

typedef struct {
  int32_t n_locals;
  int32_t n_args;
  int32_t n_captured; // 0 for BEGIN, >0 for BEGIN_CLOSURE
} func_ctx;

typedef struct {
  const bytecode *bc;

  struct {
    insn *data;
    size_t len;
    size_t cap;
  } code;

  byte_reader reader;
  aint *globals;
  size_t global_offset;

  struct {
    reloc *data;
    size_t len;
    size_t cap;
  } relocs;

  int32_t *bc_to_insn_map;
  symbol_table *st;
  ffi_call_table *ffi;
  ext_global_cache *ext_globals;

  stack_validation sv;

  func_ctx func;
  int32_t func_idx; // Current function entry offset (-1 outside any function)
} decode_ctx;

static void decode_ctx_init(decode_ctx *ctx, const bytecode *bc,
                            symbol_table *st, ffi_call_table *ffi,
                            ext_global_cache *ext_globals, aint *globals,
                            size_t global_offset) {
  ctx->bc = bc;

  ctx->globals = globals;
  ctx->global_offset = global_offset;
  ctx->bc_to_insn_map = ALLOC_ARRAY(int32_t, bc->code_size);

  da_init(ctx->code);
  da_init(ctx->relocs);

  ctx->st = st;
  ctx->ffi = ffi;
  ctx->ext_globals = ext_globals;

  ctx->sv = (stack_validation){0};
  ctx->func = (func_ctx){.n_captured = -1};
  ctx->func_idx = -1;

  reader_init(&ctx->reader, bc->code, bc->code_size);
}

static void free_decoded_arr(decoded *arr, size_t n) {
  for (size_t i = 0; i < n; i++) {
    free(arr[i].code);
    free(arr[i].bc_to_insn_map);
    free(arr[i].relocs);
  }
}

static void add_reloc(decode_ctx *ctx, size_t patch_idx, const char *name,
                      reloc_kind kind) {
  reloc s = {.patch_idx = patch_idx, .name = name, .kind = kind};
  da_append(ctx->relocs, s);
}

static fixup_node *add_fixup(meta_info *meta, size_t target_off,
                             size_t insn_idx, size_t origin_bc_off) {
  fixup_node *node = ALLOC(fixup_node);
  node->insn_idx = insn_idx;
  node->origin_bc_off = origin_bc_off;
  node->next = meta[target_off].fixups;
  meta[target_off].fixups = node;
  return node;
}

/*
 * Validate that an internal target is valid: in range, and has a correct
 * opcode.
 */
static bool validate_target_off(const bytecode *bc, int32_t target_off,
                                size_t current_bc_off, target_kind kind) {
  if (target_off < 0 || target_off >= (int32_t)bc->code_size) {
    fprintf(stderr, "Error: target_off=%d out of range at bc_off=%zu\n",
            target_off, current_bc_off);
    return false;
  }

  uint8_t got = bc->code[target_off];
  bool bad;
  switch (kind) {
  case TARGET_JUMP:
    bad = opcode_is_func_begin(got) || got == OP_EOF;
    break;
  case TARGET_CALL:
    bad = got != OP_BEGIN;
    break;
  case TARGET_CLOSURE:
    bad = !opcode_is_func_begin(got);
    break;
  }
  if (bad) {
    fprintf(stderr, "Error: bad target %s at bc_off=%zu, target=%d\n",
            opcode_to_string(got), current_bc_off, target_off);
    return false;
  }
  return true;
}

/*
 * Resolve an external C global -- prefix with "global_", dlsym, cache.
 */
static void *resolve_ext_global_ptr(ext_global_cache *cache, const char *name) {
  for (size_t i = 0; i < cache->entries.len; i++) {
    if (strcmp(cache->entries.data[i].name, name) == 0) {
      return cache->entries.data[i].ptr;
    }
  }

  size_t nlen = strlen(name);
  char prefixed[sizeof(GLOBAL_PREFIX) + nlen];
  memcpy(prefixed, GLOBAL_PREFIX, sizeof(GLOBAL_PREFIX) - 1);
  memcpy(prefixed + sizeof(GLOBAL_PREFIX) - 1, name, nlen + 1);

  void *ptr = dlsym(RTLD_DEFAULT, prefixed);
  if (!ptr) {
    fprintf(stderr, "Error: unresolved global '%s' (tried '%s')\n", name,
            prefixed);
    return NULL;
  }

  ext_global_entry entry = {.name = name, .ptr = ptr};
  da_append(cache->entries, entry);
  return ptr;
}

static aint *resolve_global_ptr(decode_ctx *ctx, int32_t idx,
                                size_t global_base) {
  if (!IS_EXT_REF(idx)) {
    return &ctx->globals[global_base + idx];
  }

  int str_offset = EXT_REF_INDEX(idx);
  const char *glob_name = bytecode_get_string(ctx->bc, str_offset);
  VM_DEBUG("DECODE: external global '%s'\n", glob_name);

  resolved_symbol *sym = symbol_table_find_global(ctx->st, glob_name);
  if (sym) {
    return &ctx->globals[sym->idx];
  }

  return (aint *)resolve_ext_global_ptr(ctx->ext_globals, glob_name);
}

/*
 * Code emission macros - append to code array in context
 */
#define EMIT_FUNC(f) da_append(ctx->code, ((insn){.func = (f)}))
#define EMIT_NUM(n) da_append(ctx->code, ((insn){.num = (n)}))
#define EMIT_ANUM(n) da_append(ctx->code, ((insn){.anum = (n)}))
#define EMIT_STR(s) da_append(ctx->code, ((insn){.str = (s)}))
#define EMIT_TARGET(t) da_append(ctx->code, ((insn){.target = (t)}))
#define EMIT_GLOBAL_PTR(p) da_append(ctx->code, ((insn){.global_ptr = (p)}))
#define EMIT_PTR(p) da_append(ctx->code, ((insn){.ptr = (p)}))

#define ENTRY_STEP_SLOTS 4

static void emit_entry_step(insn *slot, insn *main_begin) {
  slot[0].func = op_call;
  slot[1].target = main_begin;
  slot[2].num = 0;
  // Pop the result of the main unit's BEGIN since we don't do anything
  // with it.
  slot[3].func = op_drop;
}

static bool emit_glo(decode_ctx *ctx, int32_t idx, size_t global_base, fn op) {
  aint *ptr = resolve_global_ptr(ctx, idx, global_base);
  if (!ptr) {
    return false;
  }

  EMIT_FUNC(op);
  EMIT_GLOBAL_PTR(ptr);
  return true;
}

/*
 * Emit target slot for CALL/CLOSURE, handles external and internal targets.
 */
static bool emit_target(decode_ctx *ctx, meta_info *meta, int32_t target_off,
                        size_t current_bc_off, target_kind kind) {
  const bytecode *bc = ctx->bc;
  size_t target_slot = ctx->code.len;

  if (IS_EXT_REF(target_off)) {
    int str_offset = EXT_REF_INDEX(target_off);
    const char *name = bytecode_get_string(bc, str_offset);
    VM_DEBUG("DECODE: %s external target '%s' at bc_off=%zu\n",
             opcode_to_string(bc->code[current_bc_off]), name, current_bc_off);

    resolved_symbol *sym = symbol_table_find_function(ctx->st, name);
    if (sym) {
      add_reloc(ctx, target_slot, name, UNIT);
      EMIT_NUM(
          sym->idx); // placeholder, will be resolved to inter-unit function
    } else {
      size_t idx = ffi_call_table_intern(ctx->ffi, name);
      add_reloc(ctx, target_slot, name, FFI);
      EMIT_NUM(idx); // placeholder, will be resolved to FFI call
    }
  } else {
    if (!validate_target_off(bc, target_off, current_bc_off, kind))
      return false;

    EMIT_NUM(0); // placeholder — will hold code index

    meta_info *tm = &meta[target_off];
    if (target_off < (int32_t)current_bc_off) {
      assert(tm->resolved_idx != -1);
      ctx->code.data[target_slot].num = tm->resolved_idx;
      add_reloc(ctx, target_slot, NULL, INTERNAL);
    } else {
      add_fixup(meta, target_off, target_slot, current_bc_off);
    }
  }
  return true;
}

/*
 * Handle jump target resolution (intra-unit only — these are always local)
 */
static bool handle_jump(decode_ctx *ctx, meta_info *meta,
                        size_t current_bc_off) {
  int32_t target_off = reader_i32(&ctx->reader);
  int32_t depth = ctx->sv.depth;

  if (!validate_target_off(ctx->bc, target_off, current_bc_off, TARGET_JUMP)) {
    return false;
  }

  size_t my_idx = ctx->code.len;
  EMIT_NUM(0); // placeholder — will hold code index

  meta_info *tm = &meta[target_off];
  if (target_off < (int32_t)current_bc_off) {
    // Backward jump — target was already visited by sequential decode
    assert(tm->resolved_idx != -1 &&
           "backward jump target must have been visited");
    if (tm->func_idx != ctx->func_idx) {
      fprintf(
          stderr,
          "Error: backward jump escapes function at bc_off=%zu, target=%d\n",
          current_bc_off, target_off);
      return false;
    }
    ctx->code.data[my_idx].num = tm->resolved_idx;

    add_reloc(ctx, my_idx, NULL, INTERNAL);
    VM_DEBUG("  JUMP: backward to bc_off=%d, (depth=%d, target_depth=%d)\n",
             target_off, depth, tm->stack_depth);
    assert(tm->stack_depth != -1 &&
           "backward jump target must have known stack depth");
    if (tm->stack_depth != depth) {
      fprintf(stderr,
              "Error: Jump stack mismatch at bc_off=%zu (exptected %d, "
              "actual %d)\n",
              current_bc_off, depth, tm->stack_depth);
      return false;
    }
  } else {
    // Forward jump — add fixup
    add_fixup(meta, target_off, my_idx, current_bc_off);
    VM_DEBUG("  JUMP: forward to bc_off=%d, (depth=%d, target_depth=%d)\n",
             target_off, depth, tm->stack_depth);
    if (tm->stack_depth == -1) {
      tm->stack_depth = depth;
    } else if (tm->stack_depth != depth) {
      fprintf(stderr,
              "Error: Jump stack mismatch at bc_off=%zu (expected %d, actual "
              "%d)\n",
              current_bc_off, depth, tm->stack_depth);
      return false;
    }
  }
  return true;
}

static bool validate_closure_captures(meta_info *meta, int32_t target_off,
                                      int32_t n_captured,
                                      size_t current_bc_off) {
  int32_t *expected = &meta[target_off].n_captured;
  if (*expected == -1) {
    *expected = n_captured;
    return true;
  }
  if (*expected != n_captured) {
    fprintf(stderr,
            "Error: mismatched closure arity at bc_off=%zu, target=%d "
            "(expected %d, got %d)\n",
            current_bc_off, target_off, *expected, n_captured);
    return false;
  }
  return true;
}

#define DEPTH_INC(n)                                                           \
  do {                                                                         \
    VM_DEBUG("  DEPTH: %d -> %d (+%d)\n", ctx->sv.depth, ctx->sv.depth + (n),  \
             (n));                                                             \
    ctx->sv.depth += (n);                                                      \
    if (ctx->sv.depth > ctx->sv.max_depth)                                     \
      ctx->sv.max_depth = ctx->sv.depth;                                       \
  } while (0)
#define DEPTH_DEC(n)                                                           \
  do {                                                                         \
    VM_DEBUG("  DEPTH: %d -> %d (-%d)\n", ctx->sv.depth, ctx->sv.depth - (n),  \
             (n));                                                             \
    ctx->sv.depth -= (n);                                                      \
    assert(ctx->sv.depth >= 0 && "stack underflow");                           \
  } while (0)
#define DEPTH_PUSH() DEPTH_INC(1)
#define DEPTH_POP() DEPTH_DEC(1)

#define CHECK_IDX(idx, limit, name)                                            \
  do {                                                                         \
    if ((idx) < 0 || (idx) >= (limit)) {                                       \
      fprintf(stderr, "%s: index %d out of range [0, %d) at bc_off=%zu\n",     \
              name, (int)(idx), (int)(limit), current_bc_off);                 \
      goto cleanup;                                                            \
    }                                                                          \
  } while (0)

static bool decode_internal(decode_ctx *ctx) {

  const bytecode *bc = ctx->bc;
  size_t global_base = ctx->global_offset;

  meta_info *meta = ALLOC_ARRAY(meta_info, bc->code_size);

  // Initialize meta table
  for (size_t i = 0; i < bc->code_size; i++) {
    meta[i].resolved_idx = -1;
    meta[i].stack_depth = -1;
    meta[i].n_captured = -1;
    meta[i].func_idx = -1;
    meta[i].fixups = NULL;
  }

  bool ok = false;

  while (!reader_eof(&ctx->reader)) {
    size_t current_bc_off = reader_pos(&ctx->reader);
    uint8_t opcode = reader_u8(&ctx->reader);

    VM_DEBUG("DECODE: bc_off=%zu %s (0x%02X) depth=%d%s\n", current_bc_off,
             opcode_to_string(opcode), opcode, ctx->sv.depth,
             ctx->sv.state == BARRIER ? " [barrier]" : "");

    // Validate no nested function
    if (opcode_is_func_begin(opcode)) {
      if (ctx->func_idx != -1) {
        fprintf(stderr, "Error: nested function at bc_off=%zu\n",
                current_bc_off);
        goto cleanup;
      }
      ctx->func_idx = (int32_t)current_bc_off;
    }

    meta_info *m = &meta[current_bc_off];
    m->resolved_idx = (int32_t)ctx->code.len;
    m->func_idx = ctx->func_idx;

    // Validate stack depth at intersections
    if (ctx->sv.state == BARRIER) {
      if (m->stack_depth != -1) {
        // Forward jump visited
        VM_DEBUG("  DEPTH: %d -> %d", ctx->sv.depth, m->stack_depth);
        ctx->sv.depth = m->stack_depth;
      } else {
        // No forward jump has targeted this instruction yet. We are starting a
        // new "region" after JMP/END, so there is no previous instruction  to
        // validate against. So set the current decode depth which will be
        // checked by some backward jump. Example (while loop):
        //   JMP cond
        // body:
        //   ...
        // cond:
        //   ...
        //   CJMP_NZ body
        VM_DEBUG("  DEPTH: barrier, keeping stale depth=%d at bc_off=%zu\n",
                 ctx->sv.depth, current_bc_off);
        m->stack_depth = ctx->sv.depth;
      }
      ctx->sv.state = LIVE;
    } else {
      if (m->stack_depth != -1 && m->stack_depth != ctx->sv.depth) {
        fprintf(stderr,
                "Error: Stack mismatch at offset %zu (expected %d, got %d)\n",
                current_bc_off, m->stack_depth, ctx->sv.depth);
        goto cleanup;
      }
      m->stack_depth = ctx->sv.depth;
    }

    // Resolve forward jumps (backpatching) — store as index, record
    // relocation
    fixup_node *f = m->fixups;
    while (f) {
      // Validate jumps
      if (meta[f->origin_bc_off].func_idx != m->func_idx) {
        uint8_t origin_opcode = bc->code[f->origin_bc_off];
        bool is_jump = origin_opcode == OP_JMP || origin_opcode == OP_CJMP_Z ||
                       origin_opcode == OP_CJMP_NZ;
        if (is_jump) {
          fprintf(stderr,
                  "Error: forward jump escapes function at bc_off=%zu -> "
                  "target=%zu\n",
                  f->origin_bc_off, current_bc_off);
          goto cleanup;
        }
      }

      VM_DEBUG("DECODE: Resolving fixup at bc_off=%zu: insn_idx=%zu -> "
               "code_idx=%zu\n",
               current_bc_off, f->insn_idx, ctx->code.len);
      ctx->code.data[f->insn_idx].num = (int32_t)ctx->code.len;
      add_reloc(ctx, f->insn_idx, NULL, INTERNAL);

      fixup_node *next = f->next;
      free(f);
      f = next;
    }
    m->fixups = NULL;

    // Validate no instructions outside function bodies (except EOF)
    if (ctx->func_idx == -1 && opcode != OP_EOF) {
      fprintf(stderr,
              "Error: instruction %s outside function body at bc_off=%zu\n",
              opcode_to_string(opcode), current_bc_off);
      goto cleanup;
    }

    switch (opcode) {
    case OP_CONST:
      DEPTH_PUSH();
      EMIT_FUNC(op_const);
      EMIT_NUM(reader_i32(&ctx->reader));
      break;

    case OP_BINOP_ADD:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_add);
      break;

    case OP_BINOP_SUB:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_sub);
      break;

    case OP_BINOP_MUL:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_mul);
      break;

    case OP_BINOP_DIV:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_div);
      break;

    case OP_BINOP_MOD:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_mod);
      break;

    case OP_BINOP_LT:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_lt);
      break;

    case OP_BINOP_LE:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_le);
      break;

    case OP_BINOP_GT:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_gt);
      break;

    case OP_BINOP_GE:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_ge);
      break;

    case OP_BINOP_EQ:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_eq);
      break;

    case OP_BINOP_NE:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_ne);
      break;

    case OP_BINOP_AND:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_and);
      break;

    case OP_BINOP_OR:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_or);
      break;

    case OP_JMP:
      EMIT_FUNC(op_jmp);
      if (!handle_jump(ctx, meta, current_bc_off)) {
        goto cleanup;
      }
      ctx->sv.state = BARRIER;
      break;

    case OP_CJMP_Z:
      DEPTH_POP();
      EMIT_FUNC(op_cjmp_z);
      if (!handle_jump(ctx, meta, current_bc_off)) {
        goto cleanup;
      }
      break;

    case OP_CJMP_NZ:
      DEPTH_POP();
      EMIT_FUNC(op_cjmp_nz);
      if (!handle_jump(ctx, meta, current_bc_off)) {
        goto cleanup;
      }
      break;

    case OP_DROP:
      DEPTH_POP();
      EMIT_FUNC(op_drop);
      break;

    case OP_DUP:
      DEPTH_PUSH();
      EMIT_FUNC(op_dup);
      break;

    case OP_SWAP:
      DEPTH_DEC(2);
      DEPTH_INC(2);
      EMIT_FUNC(op_swap);
      break;

    case OP_ELEM:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_elem);
      break;

    case OP_STA:
      // TODO:
      DEPTH_DEC(3);
      DEPTH_PUSH();
      EMIT_FUNC(op_sta);
      break;

    case OP_LD_GLO: {
      DEPTH_PUSH();
      int32_t idx = reader_i32(&ctx->reader);
      VM_DEBUG("DECODE: OP_LD_GLO idx=%d\n", idx);
      emit_glo(ctx, idx, global_base, op_ld_glo);
      break;
    }

    case OP_ST_GLO: {
      int32_t idx = reader_i32(&ctx->reader);
      VM_DEBUG("DECODE: OP_ST_GLO idx=%d\n", idx);
      emit_glo(ctx, idx, global_base, op_st_glo);
      break;
    }

    case OP_LD_LOC: {
      DEPTH_PUSH();
      int32_t idx = reader_i32(&ctx->reader);
      CHECK_IDX(idx, ctx->func.n_locals, "LD_LOC");
      EMIT_FUNC(op_ld_loc);
      EMIT_NUM(idx);
      break;
    }

    case OP_ST_LOC: {
      int32_t idx = reader_i32(&ctx->reader);
      CHECK_IDX(idx, ctx->func.n_locals, "ST_LOC");
      EMIT_FUNC(op_st_loc);
      EMIT_NUM(idx);
      break;
    }

    case OP_LD_ARG: {
      DEPTH_PUSH();
      int32_t idx = reader_i32(&ctx->reader);
      CHECK_IDX(idx, ctx->func.n_args, "LD_ARG");
      EMIT_FUNC(op_ld_arg);
      EMIT_NUM(idx);
      break;
    }

    case OP_ST_ARG: {
      int32_t idx = reader_i32(&ctx->reader);
      CHECK_IDX(idx, ctx->func.n_args, "ST_ARG");
      EMIT_FUNC(op_st_arg);
      EMIT_NUM(idx);
      break;
    }

    case OP_LD_CLO: {
      DEPTH_PUSH();
      int32_t idx = reader_i32(&ctx->reader);
      CHECK_IDX(idx, ctx->func.n_captured, "LD_CLO");
      EMIT_FUNC(op_ld_clo);
      EMIT_NUM(idx);
      break;
    }

    case OP_ST_CLO: {
      int32_t idx = reader_i32(&ctx->reader);
      CHECK_IDX(idx, ctx->func.n_captured, "ST_CLO");
      EMIT_FUNC(op_st_clo);
      EMIT_NUM(idx);
      break;
    }

    case OP_STRING: {
      DEPTH_PUSH();
      int32_t str_idx = reader_i32(&ctx->reader);
      EMIT_FUNC(op_string);
      EMIT_STR(bytecode_get_string(bc, str_idx));
      break;
    }

    case OP_BARRAY: {
      int32_t n = reader_i32(&ctx->reader);
      DEPTH_DEC(n);
      DEPTH_PUSH();
      EMIT_FUNC(op_barray);
      EMIT_NUM(n);
      break;
    }

    case OP_SEXP: {
      int32_t tag_idx = reader_i32(&ctx->reader);
      int32_t n_fields = reader_i32(&ctx->reader);
      DEPTH_DEC(n_fields);
      DEPTH_PUSH();
      EMIT_FUNC(op_sexp);
      EMIT_ANUM(LtagHash(bytecode_get_string(bc, tag_idx)));
      EMIT_NUM(n_fields);
      break;
    }

    case OP_TAG: {
      DEPTH_POP();
      DEPTH_PUSH();
      int32_t tag_idx = reader_i32(&ctx->reader);
      int32_t n_fields = reader_i32(&ctx->reader);
      EMIT_FUNC(op_tag);
      EMIT_ANUM(LtagHash(bytecode_get_string(bc, tag_idx)));
      EMIT_NUM(n_fields);
      break;
    }

    case OP_ARRAY: {
      DEPTH_POP();
      DEPTH_PUSH();
      int32_t n = reader_i32(&ctx->reader);
      EMIT_FUNC(op_array);
      EMIT_NUM(n);
      break;
    }

    case OP_FAIL:
    case OP_FAIL_KEEP: {
      int32_t line = reader_i32(&ctx->reader);
      int32_t col = reader_i32(&ctx->reader);
      bool drop_value = opcode == OP_FAIL;
      if (drop_value) {
        DEPTH_POP();
      }
      EMIT_FUNC(op_fail);
      EMIT_NUM(line);
      EMIT_NUM(col);
      EMIT_NUM(drop_value);
      EMIT_STR(ctx->bc->name);
      break;
    }

    case OP_PATT_STR_CMP:
      DEPTH_DEC(2);
      DEPTH_PUSH();
      EMIT_FUNC(op_patt_str_cmp);
      break;

    case OP_PATT_STRING:
      DEPTH_POP();
      DEPTH_PUSH();
      EMIT_FUNC(op_patt_string);
      break;

    case OP_PATT_ARRAY:
      DEPTH_POP();
      DEPTH_PUSH();
      EMIT_FUNC(op_patt_array);
      break;

    case OP_PATT_SEXP:
      DEPTH_POP();
      DEPTH_PUSH();
      EMIT_FUNC(op_patt_sexp);
      break;

    case OP_PATT_BOXED:
      DEPTH_POP();
      DEPTH_PUSH();
      EMIT_FUNC(op_patt_boxed);
      break;

    case OP_PATT_UNBOXED:
      DEPTH_POP();
      DEPTH_PUSH();
      EMIT_FUNC(op_patt_unboxed);
      break;

    case OP_PATT_CLOSURE:
      DEPTH_POP();
      DEPTH_PUSH();
      EMIT_FUNC(op_patt_closure);
      break;

    case OP_BEGIN: {
      int32_t n_args = reader_i32(&ctx->reader);
      int32_t n_locals = reader_i32(&ctx->reader);
      ctx->sv.depth = 0;
      ctx->sv.max_depth = 0;

      ctx->func =
          (func_ctx){.n_args = n_args, .n_locals = n_locals, .n_captured = 0};

      EMIT_FUNC(op_begin);
      EMIT_NUM(n_args);
      EMIT_NUM(n_locals);
      ctx->sv.max_depth_pos = ctx->code.len;
      EMIT_NUM(0); // placeholder for max depth, will be patched

      break;
    }

    case OP_BEGIN_CLOSURE: {
      int32_t n_args = reader_i32(&ctx->reader);
      int32_t n_locals = reader_i32(&ctx->reader);
      int32_t n_captured = reader_i32(&ctx->reader);
      if (!validate_closure_captures(meta, (int32_t)current_bc_off, n_captured,
                                     current_bc_off)) {
        goto cleanup;
      }
      ctx->sv.depth = 0;
      ctx->sv.max_depth = 0;

      ctx->func = (func_ctx){
          .n_args = n_args, .n_locals = n_locals, .n_captured = n_captured};

      EMIT_FUNC(op_begin_closure);
      EMIT_NUM(n_args);
      EMIT_NUM(n_locals);
      ctx->sv.max_depth_pos = ctx->code.len;
      EMIT_NUM(0); // placeholder for max depth, will be patched

      break;
    }

    case OP_CLOSURE: {
      int32_t target_off = reader_i32(&ctx->reader);
      int32_t n_captured = reader_i32(&ctx->reader);

      VM_DEBUG("DECODE: OP_CLOSURE target_raw=0x%x n_captured=%d bc_off=%zu\n",
               target_off, n_captured, current_bc_off);

      // Emit load instructions for each captured variable
      for (int32_t i = 0; i < n_captured; i++) {
        uint8_t type_byte = reader_u8(&ctx->reader);
        int32_t idx = reader_i32(&ctx->reader);

        int designation_type = type_byte & 0xF;
        switch (designation_type) {
        case 0: // Global
          DEPTH_PUSH();
          emit_glo(ctx, idx, global_base, op_ld_glo);
          break;
        case 1: // Local
          CHECK_IDX(idx, ctx->func.n_locals, "CLOSURE desig local");
          DEPTH_PUSH();
          EMIT_FUNC(op_ld_loc);
          EMIT_NUM(idx);
          break;
        case 2: // Arg
          CHECK_IDX(idx, ctx->func.n_args, "CLOSURE desig arg");
          DEPTH_PUSH();
          EMIT_FUNC(op_ld_arg);
          EMIT_NUM(idx);
          break;
        case 3: // Closure var
          if (ctx->func.n_captured != -1)
            CHECK_IDX(idx, ctx->func.n_captured, "CLOSURE desig closure");
          DEPTH_PUSH();
          EMIT_FUNC(op_ld_clo);
          EMIT_NUM(idx);
          break;
        default:
          fprintf(stderr, "Unknown designation type: %d\n", designation_type);
          goto cleanup;
        }
      }

      DEPTH_DEC(n_captured);
      DEPTH_PUSH();

      EMIT_FUNC(op_closure);
      if (!emit_target(ctx, meta, target_off, current_bc_off, TARGET_CLOSURE))
        goto cleanup;
      EMIT_NUM(n_captured);

      // Validate CLOSURE target's n_captured consistency
      if (!IS_EXT_REF(target_off)) {
        if (!validate_closure_captures(meta, target_off, n_captured,
                                       current_bc_off)) {
          goto cleanup;
        }
      }
      break;
    }

    case OP_CALL: {
      int32_t target_off = reader_i32(&ctx->reader);
      int32_t n_args = reader_i32(&ctx->reader);
      DEPTH_DEC(n_args);
      DEPTH_PUSH();

      VM_DEBUG("DECODE: OP_CALL target_off=0x%x n_args=%d "
               "current_bc_off=%zu code_idx=%zu\n",
               target_off, n_args, current_bc_off, ctx->code.len);

      EMIT_FUNC(op_call);
      if (!emit_target(ctx, meta, target_off, current_bc_off, TARGET_CALL))
        goto cleanup;
      EMIT_NUM(n_args);
      break;
    }

    case OP_CALLC: {
      int32_t n_args = reader_i32(&ctx->reader);
      DEPTH_DEC(n_args + 1);
      DEPTH_PUSH();
      EMIT_FUNC(op_callc);
      EMIT_NUM(n_args);
      break;
    }

    case OP_END:
      // depth == 1 <=> return value (?)
      if (ctx->sv.depth != 1) {
        fprintf(stderr, "Error: END with depth = %d at bc_off=%zu\n",
                ctx->sv.depth, current_bc_off);
        goto cleanup;
      }
      EMIT_FUNC(op_end);
      ctx->code.data[ctx->sv.max_depth_pos].num = ctx->sv.max_depth;
      ctx->sv.state = BARRIER;
      ctx->func = (func_ctx){.n_captured = -1};
      ctx->func_idx = -1;
      break;

    case OP_LINE: {
#ifdef DEBUG_PRINT
      int32_t line = reader_i32(&ctx->reader);
      EMIT_FUNC(op_line);
      EMIT_NUM(line);
#else
      reader_skip(&ctx->reader, 4);
#endif
      break;
    }

    case OP_EOF:
      if (ctx->func_idx != -1) {
        fprintf(stderr, "Error: EOF inside function body at bc_off=%zu\n",
                current_bc_off);
        goto cleanup;
      }
      if (current_bc_off + 1 != bc->code_size) {
        fprintf(stderr,
                "Error: EOF opcode before end of bytecode at bc_off=%zu\n",
                current_bc_off);
        goto cleanup;
      }
      break;

    default:
      fprintf(stderr, "Not yet supported opcode 0x%02X at ip=0x%08zx\n", opcode,
              reader_pos(&ctx->reader) - 1);
      goto cleanup;
    }

    if (ctx->sv.depth > ctx->sv.max_depth) {
      ctx->sv.max_depth = ctx->sv.depth;
    }
  }

  // Extract mapping
  for (size_t i = 0; i < bc->code_size; i++) {
    ctx->bc_to_insn_map[i] = meta[i].resolved_idx;
  }

  ok = true;

cleanup:
  // Free temporary metadata and fixup nodes
  for (size_t i = 0; i < bc->code_size; i++) {
    fixup_node *node = meta[i].fixups;
    while (node) {
      fixup_node *next = node->next;
      free(node);
      node = next;
    }
  }
  free(meta);

  return ok;
}

#undef CHECK_IDX
#undef DEPTH_INC
#undef DEPTH_DEC
#undef DEPTH_PUSH
#undef DEPTH_POP
#undef EMIT_FUNC
#undef EMIT_NUM
#undef EMIT_ANUM
#undef EMIT_STR
#undef EMIT_TARGET
#undef EMIT_GLOBAL_PTR
#undef EMIT_PTR

static bool register_public_symbols(symbol_table *st, const bytecode *bc,
                                    size_t code_offset, size_t global_base,
                                    const int32_t *bc_to_insn_map) {
  public_symbol pub;
  bytecode_iterator iter;
  bytecode_pubs_init(&iter, bc);

  while (bytecode_pubs_next(&iter, &pub)) {
    if (pub.code_offset < 0 || (size_t)pub.code_offset >= bc->code_size) {
      fprintf(stderr,
              "Error: public symbol '%s' has out-of-range code_offset %d\n",
              pub.name, pub.code_offset);
      return false;
    }
    if (pub.flag == PUB_FLAG_FUNCTION) {
      // pub.code_offset is the offset in the bytecode, so we use the mapping
      int32_t insn_idx = bc_to_insn_map[pub.code_offset];
      if (insn_idx == -1) {
        fprintf(stderr,
                "Error: public symbol '%s' at bytecode offset %d not decoded\n",
                pub.name, pub.code_offset);
        return false;
      }
      int32_t code_idx = insn_idx + code_offset;
      if (!symbol_table_add_function(st, pub.name, code_idx)) {
        return false;
      }
    } else {
      int32_t global_idx = pub.code_offset + global_base;
      if (!symbol_table_add_global(st, pub.name, global_idx)) {
        return false;
      }
    }
  }

  return true;
}

/*
 * Resolve relocs / placeholders in the final code array after all units are
 * decoded and merged.
 */
static bool resolve_relocs(insn *all_code, decoded *dec, size_t code_offset,
                           size_t ffi_call_offset) {
  for (size_t j = 0; j < dec->relocs_len; j++) {
    reloc rel = dec->relocs[j];
    size_t slot = code_offset + rel.patch_idx;
    int32_t target_idx = all_code[slot].num;
    switch (rel.kind) {
    case INTERNAL: {
      all_code[slot].target = &all_code[code_offset + target_idx];
      break;
    }
    case UNIT: {
      // Validate inter-unit CALL/CLOSURE targets
      insn *target = &all_code[target_idx];
      fn caller = all_code[slot - 1].func;
      assert(caller == op_call || caller == op_closure);
      const char *caller_name = caller == op_call ? "CALL" : "CLOSURE";
      const char *target_name =
          caller == op_call ? "BEGIN" : "BEGIN/BEGIN_CLOSURE";
      bool ok = caller == op_call ? target->func == op_begin
                                  : target->func == op_begin ||
                                        target->func == op_begin_closure;
      if (!ok) {
        fprintf(stderr, "Error: inter-unit %s to non-%s function '%s'\n",
                caller_name, target_name, rel.name);
        return false;
      }
      all_code[slot].target = target;
      break;
    }
    case FFI: {
      all_code[slot].target =
          &all_code[ffi_call_offset + target_idx * FFI_STUB_SIZE];
      break;
    }
    }
  }
  return true;
}

static program *link_program(decoded *dec_arr, size_t n, size_t total_code_len,
                             ffi_call_table *ffi) {
  static insn eof_ip = {.func = op_eof};
  size_t ffi_call_len = ffi_call_table_len(ffi);
  size_t ffi_call_offset = total_code_len;
  size_t all_code_len = ffi_call_offset + ffi_call_len * FFI_STUB_SIZE;

  insn *all_code = ALLOC_ARRAY(insn, all_code_len);
  insn *entry_points = ALLOC_ARRAY(insn, ENTRY_STEP_SLOTS * n + 1);
  // Copy code and resolve relocations
  size_t code_offset = 0;
  for (size_t i = 0; i < n; i++) {
    decoded *dec = &dec_arr[i];

    // Move instructions into final code array
    memcpy(all_code + code_offset, dec->code, dec->code_len * sizeof(insn));
    emit_entry_step(&entry_points[ENTRY_STEP_SLOTS * i],
                    &all_code[code_offset]);
    if (!resolve_relocs(all_code, dec, code_offset, ffi_call_offset)) {
      free(all_code);
      free(entry_points);
      return NULL;
    }

    code_offset += dec->code_len;
  }
  entry_points[ENTRY_STEP_SLOTS * n] = eof_ip;

  ffi_call_iterator ffi_iter;
  ffi_call_table_emit_init(&ffi_iter, ffi);
  ffi_resolved *res;
  size_t ffi_idx = 0;
  while (ffi_call_table_emit_next(&ffi_iter, &res)) {
    all_code[ffi_call_offset + ffi_idx * FFI_STUB_SIZE].func = op_ffi_call;
    all_code[ffi_call_offset + ffi_idx * FFI_STUB_SIZE + 1].ptr = res;
    ffi_idx++;
  }

  program *prog = ALLOC(program);
  prog->code = all_code;
  prog->code_len = all_code_len;
  prog->entry_points = entry_points;
  prog->ffi_data = ffi_call_table_release(ffi);
  prog->ffi_len = ffi_call_len;

  return prog;
}

program *decode(bytecode **bc_arr, size_t n, aint *globals) {
  symbol_table *st = symbol_table_create();
  ffi_call_table *ffi = ffi_call_table_create();
  ext_global_cache ext_globals = {0};
  da_init(ext_globals.entries);

  decoded *dec_arr = ALLOC_ARRAY(decoded, n);
  program *prog = NULL;
  size_t n_decoded = 0;

  size_t total_code_len = 0;
  size_t total_globals = 0;

  for (size_t i = 0; i < n; i++) {
    decode_ctx ctx;
    decode_ctx_init(&ctx, bc_arr[i], st, ffi, &ext_globals, globals,
                    total_globals);
    if (!decode_internal(&ctx)) {
      fprintf(stderr, "Failed to decode %s\n", bc_arr[i]->name);
      free(ctx.bc_to_insn_map);
      goto cleanup;
    }

    dec_arr[i] = (decoded){
        .code = ctx.code.data,
        .code_len = ctx.code.len,
        .bc_to_insn_map = ctx.bc_to_insn_map,
        .relocs = ctx.relocs.data,
        .relocs_len = ctx.relocs.len,
    };
    n_decoded++;

    if (!register_public_symbols(st, bc_arr[i], total_code_len, total_globals,
                                 ctx.bc_to_insn_map)) {
      fprintf(stderr, "Failed to register public symbols for %s\n",
              bc_arr[i]->name);
      goto cleanup;
    }

    total_code_len += ctx.code.len;
    total_globals += bc_arr[i]->globals_count;
  }

  prog = link_program(dec_arr, n, total_code_len, ffi);

cleanup:
  symbol_table_destroy(st);
  ffi_call_table_destroy(ffi);
  da_free(ext_globals.entries);
  free_decoded_arr(dec_arr, n_decoded);
  free(dec_arr);

  return prog;
}

void program_free(program *prog) {
  if (!prog) {
    return;
  }
  free(prog->ffi_data);
  free(prog->code);
  free(prog->entry_points);
  free(prog);
}
