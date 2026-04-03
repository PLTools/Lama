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

/*
 * Sentinel value for external references (both functions and globals).
 * Address = -index - 1, so index 0 becomes -1, index 1 becomes -2, etc.
 */
#define TO_EXT_REF(idx) (-(idx) - 1)
#define IS_EXT_REF(addr) ((addr) < 0)
#define EXT_REF_INDEX(addr) (-(addr) - 1)

#define GLOBAL_PREFIX "global_"

/*
 * Code emission macros - append to code array in context
 */
#define EMIT_FUNC(ctx, f) da_append((ctx)->code, ((insn){.func = (f)}))
#define EMIT_NUM(ctx, n) da_append((ctx)->code, ((insn){.num = (n)}))
#define EMIT_STR(ctx, s) da_append((ctx)->code, ((insn){.str = (s)}))
#define EMIT_TARGET(ctx, t) da_append((ctx)->code, ((insn){.target = (t)}))
#define EMIT_GLOBAL_PTR(ctx, p)                                                \
  da_append((ctx)->code, ((insn){.global_ptr = (p)}))
#define EMIT_PTR(ctx, p) da_append((ctx)->code, ((insn){.ptr = (p)}))

#define FFI_STUB_SIZE 2

typedef enum {
  INTERNAL, // internal call
  UNIT,     // inter-unit call
  FFI,      // FFI call
} reloc_kind;

typedef struct {
  size_t patch_idx;
  const char *name;
  reloc_kind kind;
} reloc;

typedef struct fixup_node {
  size_t insn_idx; // Index in code array that needs the jump target
  struct fixup_node *next;
} fixup_node;

// Metadata for each bytecode offset
typedef struct {
  insn *insn;           // NULL if not visited
  int32_t resolved_idx; // Index in generated code array (-1 if not visited)
  int32_t stack_depth;  // Expected stack depth (-1 if not visited yet)
  fixup_node *fixups;   // Linked list of forward jumps pointing here
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
 * DEAD: not reachable from previous instruction
 */
typedef enum { LIVE, BARRIER, DEAD } reach_state;

typedef struct {
  int32_t depth;
  reach_state state;
  int32_t max_depth;
  size_t max_depth_pos;
} stack_validation;

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

  ctx->sv = (stack_validation){
      .depth = 0, .state = LIVE, .max_depth = 0, .max_depth_pos = 0};

  reader_init(&ctx->reader, bc->code, bc->code_size);
}

/*
 * Resolve an external C global -- prefix with "global_", dlsym, cache.
 */
static void *resolve_ext_global(ext_global_cache *cache, const char *name) {
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
                             size_t insn_idx) {
  fixup_node *node = ALLOC(fixup_node);
  node->insn_idx = insn_idx;
  node->next = meta[target_off].fixups;
  meta[target_off].fixups = node;
  return node;
}

static bool validate_target_off(const bytecode *bc, int32_t target_off,
                                size_t current_bc_off, const char *op_name) {
  if (target_off >= (int32_t)bc->code_size) {
    fprintf(
        stderr,
        "Error: %s target_off=%d out of range (bc_off=%zu, code_size=%zu)\n",
        op_name, target_off, current_bc_off, bc->code_size);
    return false;
  }
  return true;
}

static bool emit_ext_glo(decode_ctx *ctx, const char *glob_name, fn op) {
  resolved_symbol *sym = symbol_table_find_global(ctx->st, glob_name);
  if (sym) {
    // Global from another unit
    EMIT_FUNC(ctx, op);
    EMIT_GLOBAL_PTR(ctx, &ctx->globals[sym->idx]);
    return true;
  }
  // C global
  void *ptr = resolve_ext_global(ctx->ext_globals, glob_name);
  if (!ptr) {
    return false;
  }
  EMIT_FUNC(ctx, op);
  EMIT_GLOBAL_PTR(ctx, (aint *)ptr);
  return true;
}

static bool emit_glo(decode_ctx *ctx, int32_t idx, size_t global_base, fn op) {
  if (IS_EXT_REF(idx)) {
    int str_offset = EXT_REF_INDEX(idx);
    const char *glob_name = bytecode_get_string(ctx->bc, str_offset);
    VM_DEBUG("DECODE: external global '%s'\n", glob_name);
    return emit_ext_glo(ctx, glob_name, op);
  }
  EMIT_FUNC(ctx, op);
  EMIT_GLOBAL_PTR(ctx, &ctx->globals[global_base + idx]);
  return true;
}

/*
 * Handle jump target resolution (intra-unit only — these are always local)
 */
static bool handle_jump(decode_ctx *ctx, meta_info *meta,
                        size_t current_bc_off) {
  int32_t target_off = reader_i32(&ctx->reader);
  int32_t depth = ctx->sv.depth;
  reach_state state = ctx->sv.state;

  if (!validate_target_off(ctx->bc, target_off, current_bc_off, "JUMP")) {
    return false;
  }

  size_t my_idx = ctx->code.len;
  EMIT_NUM(ctx, 0); // placeholder — will hold code index

  meta_info *tm = &meta[target_off];
  if (target_off < (int32_t)current_bc_off) {
    // Backward jump — target was already visited by sequential decode
    assert(tm->resolved_idx != -1 &&
           "backward jump target must have been visited");
    ctx->code.data[my_idx].num = tm->resolved_idx;

    add_reloc(ctx, my_idx, NULL, INTERNAL);
    VM_DEBUG("  JUMP: backward to bc_off=%d, (depth=%d, target_depth=%d)\n",
             target_off, depth, tm->stack_depth);
    if (state != DEAD) {
      assert(tm->stack_depth != -1 &&
             "backward jump target must have known stack depth");
      if (tm->stack_depth != depth) {
        fprintf(stderr,
                "Error: Jump stack mismatch at bc_off=%zu (exptected %d, "
                "actual %d)\n",
                current_bc_off, depth, tm->stack_depth);
        return false;
      }
    }
  } else {
    // Forward jump — add fixup
    if (!add_fixup(meta, target_off, my_idx)) {
      return false;
    }
    if (state == DEAD) {
      // Don't set or validate depth at target since it's not reachable from
      // sequential decode
      VM_DEBUG("  JUMP: forward to bc_off=%d (dead, skipping depth)\n",
               target_off);
    } else if (tm->stack_depth == -1) {
      VM_DEBUG("  JUMP: forward to bc_off=%d, (depth=%d, target_depth=%d)\n",
               target_off, depth, tm->stack_depth);
      tm->stack_depth = depth;
    } else if (tm->stack_depth != depth) {
      fprintf(stderr,
              "Error: Jump stack mismatch at bc_off=%zu (expected %d, actual "
              "%d)\n",
              current_bc_off, depth, tm->stack_depth);
      return false;
    } else {
      VM_DEBUG("  JUMP: forward to bc_off=%d, (depth=%d, target_depth=%d)\n",
               target_off, depth, tm->stack_depth);
    }
  }
  return true;
}

#define DEPTH_INC(sv, n)                                                       \
  do {                                                                         \
    if ((sv).state != DEAD) {                                                  \
      VM_DEBUG("  DEPTH: %d -> %d (+%d)\n", (sv).depth, (sv).depth + (n),      \
               (n));                                                           \
      (sv).depth += (n);                                                       \
      if ((sv).depth > (sv).max_depth)                                         \
        (sv).max_depth = (sv).depth;                                           \
    }                                                                          \
  } while (0)
#define DEPTH_DEC(sv, n)                                                       \
  do {                                                                         \
    if ((sv).state != DEAD) {                                                  \
      VM_DEBUG("  DEPTH: %d -> %d (-%d)\n", (sv).depth, (sv).depth - (n),      \
               (n));                                                           \
      (sv).depth -= (n);                                                       \
      assert((sv).depth >= 0 && "stack underflow");                            \
    }                                                                          \
  } while (0)
#define DEPTH_PUSH(sv) DEPTH_INC(sv, 1)
#define DEPTH_POP(sv) DEPTH_DEC(sv, 1)

static bool decode_internal(decode_ctx *ctx) {

  const bytecode *bc = ctx->bc;
  size_t global_base = ctx->global_offset;

  meta_info *meta = ALLOC_ARRAY(meta_info, bc->code_size);

  // Initialize meta table
  for (size_t i = 0; i < bc->code_size; i++) {
    meta[i].resolved_idx = -1;
    meta[i].stack_depth = -1;
    meta[i].fixups = NULL;
  }

  EMIT_FUNC(ctx, op_init);
  EMIT_NUM(ctx, 0); // placeholder for op_eof

  bool ok = false;

  while (!reader_eof(&ctx->reader)) {
    size_t current_bc_off = reader_pos(&ctx->reader);
    uint8_t opcode = reader_u8(&ctx->reader);

    VM_DEBUG("DECODE: bc_off=%zu %s (0x%02X) depth=%d\n", current_bc_off,
             opcode_to_string(opcode), opcode, ctx->sv.depth,
             ctx->sv.state == BARRIER ? " [barrier]"
             : ctx->sv.state == DEAD  ? " [dead]"
                                      : "");

    meta_info *m = &meta[current_bc_off];
    m->resolved_idx = (int32_t)ctx->code.len;

    // Validate stack depth at intersections
    if (ctx->sv.state == DEAD) {
      if (m->stack_depth != -1) {
        // Forward jump visited
        VM_DEBUG("  DEPTH: %d -> %d", ctx->sv.depth, m->stack_depth);
        ctx->sv.depth = m->stack_depth;
        ctx->sv.state = LIVE;
      } else {
        // No forward jump
        VM_DEBUG("  DEPTH: dead, skipping at bc_off=%zu\n", current_bc_off);
        m->stack_depth = -1; // unvisited
      }
    } else if (ctx->sv.state == BARRIER) {
      if (m->stack_depth != -1) {
        // Forward jump visited
        VM_DEBUG("  DEPTH: %d -> %d", ctx->sv.depth, m->stack_depth);
        ctx->sv.depth = m->stack_depth;
      } else {
        // No forward jump
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

    switch (opcode) {
    case OP_CONST:
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_const);
      EMIT_NUM(ctx, reader_i32(&ctx->reader));
      break;

    case OP_BINOP_ADD:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_add);
      break;

    case OP_BINOP_SUB:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_sub);
      break;

    case OP_BINOP_MUL:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_mul);
      break;

    case OP_BINOP_DIV:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_div);
      break;

    case OP_BINOP_MOD:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_mod);
      break;

    case OP_BINOP_LT:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_lt);
      break;

    case OP_BINOP_LE:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_le);
      break;

    case OP_BINOP_GT:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_gt);
      break;

    case OP_BINOP_GE:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_ge);
      break;

    case OP_BINOP_EQ:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_eq);
      break;

    case OP_BINOP_NE:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_ne);
      break;

    case OP_BINOP_AND:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_and);
      break;

    case OP_BINOP_OR:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_or);
      break;

    case OP_JMP:
      EMIT_FUNC(ctx, op_jmp);
      if (!handle_jump(ctx, meta, current_bc_off)) {
        goto cleanup;
      }
      if (ctx->sv.state != DEAD) {
        ctx->sv.state = BARRIER;
      }
      break;

    case OP_CJMP_Z:
      DEPTH_POP(ctx->sv);
      EMIT_FUNC(ctx, op_cjmp_z);
      if (!handle_jump(ctx, meta, current_bc_off)) {
        goto cleanup;
      }
      break;

    case OP_CJMP_NZ:
      DEPTH_POP(ctx->sv);
      EMIT_FUNC(ctx, op_cjmp_nz);
      if (!handle_jump(ctx, meta, current_bc_off)) {
        goto cleanup;
      }
      break;

    case OP_DROP:
      DEPTH_POP(ctx->sv);
      EMIT_FUNC(ctx, op_drop);
      break;

    case OP_DUP:
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_dup);
      break;

    case OP_SWAP:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_INC(ctx->sv, 2);
      EMIT_FUNC(ctx, op_swap);
      break;

    case OP_ELEM:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_elem);
      break;

    case OP_STA:
      // TODO:
      DEPTH_DEC(ctx->sv, 3);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_sta);
      break;

    case OP_LD: {
      DEPTH_PUSH(ctx->sv);
      int32_t idx = reader_i32(&ctx->reader);
      VM_DEBUG("DECODE: OP_LD global idx=%d\n", idx);
      emit_glo(ctx, idx, global_base, op_ld_glo);
      break;
    }

    case OP_ST: {
      int32_t idx = reader_i32(&ctx->reader);
      VM_DEBUG("DECODE: OP_ST global idx=%d\n", idx);
      emit_glo(ctx, idx, global_base, op_st_glo);
      break;
    }

    case OP_LD_LOC: {
      DEPTH_PUSH(ctx->sv);
      int32_t idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_ld_loc);
      EMIT_NUM(ctx, idx);
      break;
    }

    case OP_ST_LOC: {
      int32_t idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_st_loc);
      EMIT_NUM(ctx, idx);
      break;
    }

    case OP_LD_ARG: {
      DEPTH_PUSH(ctx->sv);
      int32_t idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_ld_arg);
      EMIT_NUM(ctx, idx);
      break;
    }

    case OP_ST_ARG: {
      int32_t idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_st_arg);
      EMIT_NUM(ctx, idx);
      break;
    }

    case OP_LD_CLO: {
      DEPTH_PUSH(ctx->sv);
      int32_t idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_ld_clo);
      EMIT_NUM(ctx, idx);
      break;
    }

    case OP_ST_CLO: {
      int32_t idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_st_clo);
      EMIT_NUM(ctx, idx);
      break;
    }

    case OP_STRING: {
      DEPTH_PUSH(ctx->sv);
      int32_t str_idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_string);
      EMIT_STR(ctx, bytecode_get_string(bc, str_idx));
      break;
    }

    case OP_BARRAY: {
      int32_t n = reader_i32(&ctx->reader);
      DEPTH_DEC(ctx->sv, n);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_barray);
      EMIT_NUM(ctx, n);
      break;
    }

    case OP_SEXP: {
      int32_t tag_idx = reader_i32(&ctx->reader);
      int32_t n_fields = reader_i32(&ctx->reader);
      DEPTH_DEC(ctx->sv, n_fields);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_sexp);
      EMIT_STR(ctx, bytecode_get_string(bc, tag_idx));
      EMIT_NUM(ctx, n_fields);
      break;
    }

    case OP_TAG: {
      DEPTH_POP(ctx->sv);
      DEPTH_PUSH(ctx->sv);
      int32_t tag_idx = reader_i32(&ctx->reader);
      int32_t n_fields = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_tag);
      EMIT_STR(ctx, bytecode_get_string(bc, tag_idx));
      EMIT_NUM(ctx, n_fields);
      break;
    }

    case OP_ARRAY: {
      DEPTH_POP(ctx->sv);
      DEPTH_PUSH(ctx->sv);
      int32_t n = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_array);
      EMIT_NUM(ctx, n);
      break;
    }

    case OP_FAIL: {
      int32_t line = reader_i32(&ctx->reader);
      int32_t col = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_fail);
      EMIT_NUM(ctx, line);
      EMIT_NUM(ctx, col);
      ctx->sv.state = DEAD;
      break;
    }

    case OP_PATT_STR_CMP:
      DEPTH_DEC(ctx->sv, 2);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_patt_str_cmp);
      break;

    case OP_PATT_STRING:
      DEPTH_POP(ctx->sv);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_patt_string);
      break;

    case OP_PATT_ARRAY:
      DEPTH_POP(ctx->sv);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_patt_array);
      break;

    case OP_PATT_SEXP:
      DEPTH_POP(ctx->sv);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_patt_sexp);
      break;

    case OP_PATT_BOXED:
      DEPTH_POP(ctx->sv);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_patt_boxed);
      break;

    case OP_PATT_UNBOXED:
      DEPTH_POP(ctx->sv);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_patt_unboxed);
      break;

    case OP_PATT_CLOSURE:
      DEPTH_POP(ctx->sv);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_patt_closure);
      break;

    case OP_BEGIN:
    case OP_BEGIN_CLOSURE: {
      int32_t n_args = reader_i32(&ctx->reader);
      int32_t n_locals = reader_i32(&ctx->reader);
      ctx->sv.depth = 0;
      ctx->sv.max_depth = 0;
      EMIT_FUNC(ctx, op_begin);
      EMIT_NUM(ctx, n_args);
      EMIT_NUM(ctx, n_locals);
      ctx->sv.max_depth_pos = ctx->code.len;
      EMIT_NUM(ctx, 0); // placeholder for max depth, will be patched

      break;
    }

    case OP_CLOSURE: {
      int32_t target_off = reader_i32(&ctx->reader);
      int32_t n_captured = reader_i32(&ctx->reader);

      VM_DEBUG("DECODE: OP_CLOSURE target_raw=0x%x n_captured=%d bc_off=%zu\n",
               target_off, n_captured, current_bc_off);

      bool is_external = IS_EXT_REF(target_off);

      // Emit load instructions for each captured variable
      for (int32_t i = 0; i < n_captured; i++) {
        uint8_t type_byte = reader_u8(&ctx->reader);
        int32_t idx = reader_i32(&ctx->reader);

        int designation_type = type_byte & 0xF;
        switch (designation_type) {
        case 0: // Global
          DEPTH_PUSH(ctx->sv);
          emit_glo(ctx, idx, global_base, op_ld_glo);
          break;
        case 1: // Local
          DEPTH_PUSH(ctx->sv);
          EMIT_FUNC(ctx, op_ld_loc);
          EMIT_NUM(ctx, idx);
          break;
        case 2: // Arg
          DEPTH_PUSH(ctx->sv);
          EMIT_FUNC(ctx, op_ld_arg);
          EMIT_NUM(ctx, idx);
          break;
        case 3: // Closure var
          DEPTH_PUSH(ctx->sv);
          EMIT_FUNC(ctx, op_ld_clo);
          EMIT_NUM(ctx, idx);
          break;
        default:
          fprintf(stderr, "Unknown designation type: %d\n", designation_type);
          goto cleanup;
        }
      }

      DEPTH_DEC(ctx->sv, n_captured);
      DEPTH_PUSH(ctx->sv);

      EMIT_FUNC(ctx, op_closure);

      size_t target_slot = ctx->code.len;
      if (is_external) {
        int str_offset = EXT_REF_INDEX(target_off);
        const char *ext_func_name = bytecode_get_string(bc, str_offset);

        VM_DEBUG("DECODE: OP_CLOSURE external name='%s' (stub)\n",
                 ext_func_name);

        resolved_symbol *sym =
            symbol_table_find_function(ctx->st, ext_func_name);
        if (sym) {
          add_reloc(ctx, target_slot, ext_func_name, UNIT);
          EMIT_NUM(
              ctx,
              sym->idx); // placeholder, will be resolved to inter-unit function
        } else {
          size_t idx = ffi_call_table_intern(ctx->ffi, ext_func_name);
          add_reloc(ctx, target_slot, ext_func_name, FFI);
          EMIT_NUM(ctx, idx); // placeholder, will be resolved to FFI call
        }

        EMIT_NUM(ctx, n_captured);

      } else {
        if (!validate_target_off(bc, target_off, current_bc_off, "CLOSURE")) {
          goto cleanup;
        }

        EMIT_NUM(ctx, 0); // placeholder — will hold code index
        EMIT_NUM(ctx, n_captured);

        meta_info *tm = &meta[target_off];
        if (target_off < (int32_t)current_bc_off) {
          assert(tm->resolved_idx != -1 &&
                 "backward closure target must have been visited");

          ctx->code.data[target_slot].num = tm->resolved_idx;
          add_reloc(ctx, target_slot, NULL, INTERNAL);
        } else {
          add_fixup(meta, target_off, target_slot);
        }
      }
      break;
    }

    case OP_CALL: {
      int32_t target_off = reader_i32(&ctx->reader);
      int32_t n_args = reader_i32(&ctx->reader);
      DEPTH_DEC(ctx->sv, n_args);
      DEPTH_PUSH(ctx->sv);

      VM_DEBUG("DECODE: OP_CALL target_off=0x%x n_args=%d "
               "current_bc_off=%zu code_idx=%zu\n",
               target_off, n_args, current_bc_off, ctx->code.len);
      bool is_external = IS_EXT_REF(target_off);

      EMIT_FUNC(ctx, op_call);

      size_t target_slot = ctx->code.len;
      if (is_external) {
        int str_offset = EXT_REF_INDEX(target_off);
        const char *ext_func_name = bytecode_get_string(bc, str_offset);

        VM_DEBUG("DECODE: OP_CALL external '%s' (stub)\n", ext_func_name);

        resolved_symbol *sym =
            symbol_table_find_function(ctx->st, ext_func_name);

        if (sym) {
          add_reloc(ctx, target_slot, ext_func_name, UNIT);
          EMIT_NUM(
              ctx,
              sym->idx); // placeholder, will be resolved to inter-unit function
        } else {
          size_t idx = ffi_call_table_intern(ctx->ffi, ext_func_name);
          add_reloc(ctx, target_slot, ext_func_name, FFI);
          EMIT_NUM(ctx, idx); // placeholder, will be resolved to FFI call
        }
        EMIT_NUM(ctx, n_args);

      } else {
        if (!validate_target_off(bc, (uint32_t)target_off, current_bc_off,
                                 "CALL")) {
          goto cleanup;
        }
        EMIT_NUM(ctx, 0); // placeholder — will hold code index
        EMIT_NUM(ctx, n_args);

        meta_info *tm = &meta[target_off];
        if (target_off < (int32_t)current_bc_off) {
          assert(tm->resolved_idx != -1 &&
                 "backward call target must have been visited");

          ctx->code.data[target_slot].num = tm->resolved_idx;
          add_reloc(ctx, target_slot, NULL, INTERNAL);
        } else {
          add_fixup(meta, (uint32_t)target_off, target_slot);
        }
      }
      break;
    }

    case OP_CALLC: {
      int32_t n_args = reader_i32(&ctx->reader);
      DEPTH_DEC(ctx->sv, n_args + 1);
      DEPTH_PUSH(ctx->sv);
      EMIT_FUNC(ctx, op_callc);
      EMIT_NUM(ctx, n_args);
      break;
    }

    case OP_END:
      // depth == 1 <=> return value (?)
      if (ctx->sv.state != DEAD && ctx->sv.depth != 1) {
        fprintf(stderr, "Error: END with depth = %d at bc_off=%zu\n",
                ctx->sv.depth, current_bc_off);
        goto cleanup;
      }
      EMIT_FUNC(ctx, op_end);
      if (ctx->sv.state != DEAD) {
        ctx->code.data[ctx->sv.max_depth_pos].num = ctx->sv.max_depth;
        ctx->sv.state = BARRIER;
      }
      break;

    case OP_LINE: {
#ifdef DEBUG_PRINT
      int32_t line = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_line);
      EMIT_NUM(ctx, line);
#else
      reader_skip(&ctx->reader, 4);
#endif
      break;
    }

    case OP_EOF:
      break;

    default:
      fprintf(stderr, "Not yet supported opcode 0x%02X at ip=0x%08zx\n", opcode,
              reader_pos(&ctx->reader) - 1);
      goto cleanup;
    }

    if (ctx->sv.state != DEAD && ctx->sv.depth > ctx->sv.max_depth) {
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

#undef DEPTH_INC
#undef DEPTH_DEC
#undef DEPTH_PUSH
#undef DEPTH_POP

static void register_public_symbols(symbol_table *st, const bytecode *bc,
                                    size_t code_offset, size_t global_base,
                                    const int32_t *bc_to_insn_map) {
  public_symbol pub;
  bytecode_iterator iter;
  bytecode_pubs_init(&iter, bc);

  while (bytecode_pubs_next(&iter, &pub)) {
    if (pub.flag == PUB_FLAG_FUNCTION) {
      // pub.code_offset is the offset in the bytecode, so we use the mapping
      int32_t insn_idx = bc_to_insn_map[pub.code_offset];
      if (insn_idx == -1) {
        fprintf(stderr,
                "Error: public symbol '%s' at bytecode offset %d not decoded\n",
                pub.name, pub.code_offset);
        exit(EXIT_FAILURE);
      }
      int32_t code_idx = insn_idx + code_offset;
      symbol_table_add_function(st, pub.name, code_idx);
    } else {
      int32_t global_idx = pub.code_offset + global_base;
      symbol_table_add_global(st, pub.name, global_idx);
    }
  }
}

/*
 * Resolve relocs / placeholders in the final code array after all units are
 * decoded and merged.
 */
static void resolve_relocs(insn *all_code, decoded *dec, size_t code_offset,
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
      all_code[slot].target = &all_code[target_idx];
      break;
    }
    case FFI: {
      all_code[slot].target =
          &all_code[ffi_call_offset + target_idx * FFI_STUB_SIZE];
      break;
    }
    }
  }
}

static program *link_program(decoded *dec_arr, size_t n, size_t total_code_len,
                             size_t total_globals, ffi_call_table *ffi) {
  size_t ffi_call_len = ffi_call_table_len(ffi);

  size_t eof_offset = total_code_len;
  size_t ffi_call_offset = eof_offset + 1;
  size_t all_code_len = ffi_call_offset + ffi_call_len * FFI_STUB_SIZE;

  insn *all_code = ALLOC_ARRAY(insn, all_code_len);
  insn **entry_points = ALLOC_ARRAY(insn *, n);

  all_code[eof_offset].func = op_eof;
  // Copy code and resolve relocations
  size_t code_offset = 0;
  for (size_t i = 0; i < n; i++) {
    decoded *dec = &dec_arr[i];

    // Move instructions into final code array
    memcpy(all_code + code_offset, dec->code, dec->code_len * sizeof(insn));
    entry_points[i] = &all_code[code_offset];
    resolve_relocs(all_code, dec, code_offset, ffi_call_offset);

    all_code[code_offset + 1].target = &all_code[eof_offset];

    code_offset += dec->code_len;
  }

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
  prog->total_globals = total_globals;
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

    register_public_symbols(st, bc_arr[i], total_code_len, total_globals,
                            ctx.bc_to_insn_map);

    total_code_len += ctx.code.len;
    total_globals += bc_arr[i]->globals_count;
  }

  prog = link_program(dec_arr, n, total_code_len, total_globals, ffi);

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
