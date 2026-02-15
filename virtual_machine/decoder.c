#include "decoder.h"
#include "da.h"
#include "memory.h"
#include "opcodes.h"
#include "ops.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// TODO: conolidate
#ifdef DEBUG_PRINT
#define VM_DEBUG(fmt, ...) fprintf(stderr, fmt, ##__VA_ARGS__)
#else
#define VM_DEBUG(fmt, ...)
#endif

/*
 * Sentinel value for external references (both functions and globals).
 * Address = -index - 1, so index 0 becomes -1, index 1 becomes -2, etc.
 */
#define TO_EXT_REF(idx) (-(idx) - 1)
#define IS_EXT_REF(addr) ((addr) < 0)
#define EXT_REF_INDEX(addr) (-(addr) - 1)

/*
 * Symbolic stack depth tracking macros used during decoding
 * depth = -1 means unreachable code
 */
#define DEPTH_INC(d, n)                                                        \
  do {                                                                         \
    if ((d) != -1)                                                             \
      (d) += (n);                                                              \
  } while (0)
#define DEPTH_DEC(d, n)                                                        \
  do {                                                                         \
    if ((d) != -1)                                                             \
      (d) -= (n);                                                              \
  } while (0)
#define DEPTH_PUSH(d) DEPTH_INC(d, 1)
#define DEPTH_POP(d) DEPTH_DEC(d, 1)
#define DEPTH_DEAD(d) ((d) = -1)

/*
 * Code emission macros - append to code array in context
 */
#define EMIT_FUNC(ctx, f)                                                      \
  do {                                                                         \
    (ctx)->code[(ctx)->code_len++].func = (f);                                 \
  } while (0)
#define EMIT_NUM(ctx, n)                                                       \
  do {                                                                         \
    (ctx)->code[(ctx)->code_len++].num = (n);                                  \
  } while (0)
#define EMIT_STR(ctx, s)                                                       \
  do {                                                                         \
    (ctx)->code[(ctx)->code_len++].str = (s);                                  \
  } while (0)
#define EMIT_TARGET(ctx, t)                                                    \
  do {                                                                         \
    (ctx)->code[(ctx)->code_len++].target = (t);                               \
  } while (0)

fn decoder_get_op_call(void) { return op_call; }

fn decoder_get_op_call_ffi_stub(void) { return op_call_ffi_stub; }

fn decoder_get_op_callc_ffi_stub(void) { return op_callc_ffi_stub; }

fn decoder_get_op_ld_glo(void) { return op_ld_glo; }

fn decoder_get_op_st_glo(void) { return op_st_glo; }

fn decoder_get_op_ld_glo_ext(void) { return op_ld_glo_ext; }

fn decoder_get_op_st_glo_ext(void) { return op_st_glo_ext; }

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
  const bytecode *bc;
  insn *code;
  size_t code_len;
  byte_reader reader;
  size_t global_offset;

  struct {
    stub *data;
    size_t len;
    size_t cap;
  } stubs;

  struct {
    size_t *data;
    size_t len;
    size_t cap;
  } relocs;

  int32_t *bc_to_insn_map;

} decode_ctx;

decode_ctx *decode_ctx_create(const bytecode *bc, int32_t global_offset) {
  decode_ctx *ctx = ALLOC(decode_ctx);

  ctx->bc = bc;

  ctx->code = NULL;
  ctx->code_len = 0;
  ctx->global_offset = global_offset;
  ctx->bc_to_insn_map = NULL;

  da_init(ctx->stubs);

  da_init(ctx->relocs);

  reader_init(&ctx->reader, bc->code, bc->code_size);

  return ctx;
}

static void add_stub(decode_ctx *ctx, size_t patch_idx, const char *name,
                     stub_kind kind) {
  stub s = {.patch_idx = patch_idx, .name = name, .kind = kind};
  da_append(ctx->stubs, s);
}

static fixup_node *add_fixup(meta_info *meta, size_t target_off,
                             size_t insn_idx) {
  fixup_node *node = ALLOC(fixup_node);
  if (!node)
    return NULL;

  node->insn_idx = insn_idx;
  node->next = meta[target_off].fixups;
  meta[target_off].fixups = node;
  return node;
}

static bool validate_target_off(const bytecode *bc, size_t target_off,
                                size_t current_bc_off, const char *op_name) {
  if (target_off >= bc->code_size) {
    fprintf(
        stderr,
        "Error: %s target_off=%zu out of range (bc_off=%zu, code_size=%zu)\n",
        op_name, target_off, current_bc_off, bc->code_size);
    return false;
  }
  return true;
}

/*
 * Record that code[insn_idx].target holds a code-array index .
 * The linker will convert it to an absolute pointer after copying.
 */
static void emit_target_idx(decode_ctx *ctx, size_t target_code_idx) {
  size_t slot = ctx->code_len;
  ctx->code[ctx->code_len++].num = (int32_t)target_code_idx;
  da_append(ctx->relocs, slot);
}

static bool emit_ld_glo(decode_ctx *ctx, int32_t idx, size_t global_base) {
  const bytecode *bc = ctx->bc;

  if (IS_EXT_REF(idx)) {
    int str_offset = EXT_REF_INDEX(idx);
    const char *glob_name = bytecode_get_string(bc, str_offset);
    VM_DEBUG("DECODE: OP_LD external global '%s' (stub)\n", glob_name);
    EMIT_FUNC(ctx, NULL); // linker will patch this
    size_t patch_idx = ctx->code_len;
    EMIT_NUM(ctx, 0); // placeholder — linker will patch
    add_stub(ctx, patch_idx, glob_name, STUB_GLOBAL_LD);
  } else {
    EMIT_FUNC(ctx, op_ld_glo);
    EMIT_NUM(ctx, global_base + idx);
  }
  return true;
}

static bool emit_st_glo(decode_ctx *ctx, int32_t idx, size_t global_base) {
  const bytecode *bc = ctx->bc;

  if (IS_EXT_REF(idx)) {
    int str_offset = EXT_REF_INDEX(idx);
    const char *glob_name = bytecode_get_string(bc, str_offset);
    VM_DEBUG("DECODE: OP_ST external global '%s' (stub)\n", glob_name);
    EMIT_FUNC(ctx, NULL); // linker will patch this
    size_t patch_idx = ctx->code_len;
    EMIT_NUM(ctx, 0); // placeholder — linker will patch
    add_stub(ctx, patch_idx, glob_name, STUB_GLOBAL_ST);
  } else {
    EMIT_FUNC(ctx, op_st_glo);
    EMIT_NUM(ctx, global_base + idx);
  }
  return true;
}

/*
 * Handle jump target resolution (intra-unit only — these are always local)
 */
static bool handle_jump(decode_ctx *ctx, meta_info *meta, size_t current_bc_off,
                        int32_t depth) {
  int32_t target_off = reader_i32(&ctx->reader);

  if (!validate_target_off(ctx->bc, target_off, current_bc_off, "JUMP")) {
    return false;
  }

  size_t my_idx = ctx->code_len;
  EMIT_NUM(ctx, 0); // placeholder — will hold code index

  meta_info *tm = &meta[target_off];
  if (target_off < (int32_t)current_bc_off && tm->resolved_idx != -1) {
    // Backward jump — already resolved, store as index
    ctx->code[my_idx].num = tm->resolved_idx;
    da_append(ctx->relocs, my_idx);
    if (depth != -1 && tm->stack_depth != -1 && tm->stack_depth != depth) {
      fprintf(stderr, "Error: Loop stack mismatch\n");
      return false;
    }
  } else {
    // Forward jump — add fixup
    if (!add_fixup(meta, target_off, my_idx)) {
      return false;
    }
    if (depth != -1) {
      if (tm->stack_depth == -1)
        tm->stack_depth = depth;
      else if (tm->stack_depth != depth) {
        fprintf(stderr, "Error: Jump stack mismatch\n");
        return false;
      }
    }
  }
  return true;
}

static insn *decode_internal(decode_ctx *ctx) {
  const bytecode *bc = ctx->bc;
  size_t global_base = ctx->global_offset;

  size_t code_cap = bc->code_size * 16; // TODO: estimate better
  insn *code = ALLOC_ARRAY(insn, code_cap);
  ctx->code = code;

  meta_info *meta = ALLOC_ARRAY(meta_info, bc->code_size);

  // Initialize meta table
  for (size_t i = 0; i < bc->code_size; i++) {
    meta[i].resolved_idx = -1;
    meta[i].stack_depth = -1;
    meta[i].fixups = NULL;
  }

  int32_t depth = 0;

  while (!reader_eof(&ctx->reader)) {
    size_t current_bc_off = reader_pos(&ctx->reader);
    uint8_t opcode = reader_u8(&ctx->reader);

    VM_DEBUG("DECODE: visiting bc_off=%zu opcode=%d code_idx=%zu\n",
             current_bc_off, opcode, ctx->code_len);

    meta_info *m = &meta[current_bc_off];
    m->resolved_idx = (int32_t)ctx->code_len;

    // Validate stack depth
    if (depth != -1) {
      if (m->stack_depth != -1 && m->stack_depth != depth) {
        fprintf(stderr,
                "Error: Stack mismatch at offset %zu (expected %d, got %d)\n",
                current_bc_off, m->stack_depth, depth);
        return NULL;
      }
      m->stack_depth = depth;
    } else {
      depth = m->stack_depth;
    }

    // Resolve forward jumps (backpatching) — store as index, record relocation
    for (fixup_node *f = m->fixups; f; f = f->next) {
      VM_DEBUG("DECODE: Resolving fixup at bc_off=%zu: insn_idx=%zu -> "
               "code_idx=%zu\n",
               current_bc_off, f->insn_idx, ctx->code_len);
      ctx->code[f->insn_idx].num = (int32_t)ctx->code_len;
      da_append(ctx->relocs, f->insn_idx);
    }

    switch (opcode) {
    case OP_CONST:
      DEPTH_PUSH(depth);
      EMIT_FUNC(ctx, op_const);
      EMIT_NUM(ctx, reader_i32(&ctx->reader));
      break;

    case OP_BINOP_ADD:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_add);
      break;

    case OP_BINOP_SUB:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_sub);
      break;

    case OP_BINOP_MUL:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_mul);
      break;

    case OP_BINOP_DIV:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_div);
      break;

    case OP_BINOP_MOD:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_mod);
      break;

    case OP_BINOP_LT:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_lt);
      break;

    case OP_BINOP_LE:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_le);
      break;

    case OP_BINOP_GT:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_gt);
      break;

    case OP_BINOP_GE:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_ge);
      break;

    case OP_BINOP_EQ:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_eq);
      break;

    case OP_BINOP_NE:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_ne);
      break;

    case OP_BINOP_AND:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_and);
      break;

    case OP_BINOP_OR:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_or);
      break;

    case OP_JMP:
      EMIT_FUNC(ctx, op_jmp);
      if (!handle_jump(ctx, meta, current_bc_off, depth)) {
        return NULL;
      }
      DEPTH_DEAD(depth);
      break;

    case OP_CJMP_Z:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_cjmp_z);
      if (!handle_jump(ctx, meta, current_bc_off, depth)) {
        return NULL;
      }
      break;

    case OP_CJMP_NZ:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_cjmp_nz);
      if (!handle_jump(ctx, meta, current_bc_off, depth)) {
        return NULL;
      }
      break;

    case OP_DROP:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_drop);
      break;

    case OP_DUP:
      DEPTH_PUSH(depth);
      EMIT_FUNC(ctx, op_dup);
      break;

    case OP_SWAP:
      EMIT_FUNC(ctx, op_swap);
      break;

    case OP_ELEM:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_elem);
      break;

    case OP_STA:
      DEPTH_DEC(depth, 2);
      EMIT_FUNC(ctx, op_sta);
      break;

    case OP_LD: {
      DEPTH_PUSH(depth);
      int32_t idx = reader_i32(&ctx->reader);
      emit_ld_glo(ctx, idx, global_base);
      break;
    }

    case OP_ST: {
      int32_t idx = reader_i32(&ctx->reader);
      emit_st_glo(ctx, idx, global_base);
      break;
    }

    case OP_LD_LOC: {
      DEPTH_PUSH(depth);
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
      DEPTH_PUSH(depth);
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
      DEPTH_PUSH(depth);
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
      DEPTH_PUSH(depth);
      int32_t str_idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_string);
      EMIT_STR(ctx, bytecode_get_string(bc, str_idx));
      break;
    }

    case OP_BARRAY: {
      int32_t n = reader_i32(&ctx->reader);
      DEPTH_DEC(depth, n - 1);
      EMIT_FUNC(ctx, op_barray);
      EMIT_NUM(ctx, n);
      break;
    }

    case OP_SEXP: {
      int32_t tag_idx = reader_i32(&ctx->reader);
      int32_t n_fields = reader_i32(&ctx->reader);
      DEPTH_DEC(depth, n_fields - 1);
      EMIT_FUNC(ctx, op_sexp);
      EMIT_STR(ctx, bytecode_get_string(bc, tag_idx));
      EMIT_NUM(ctx, n_fields);
      break;
    }

    case OP_TAG: {
      int32_t tag_idx = reader_i32(&ctx->reader);
      int32_t n_fields = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_tag);
      EMIT_STR(ctx, bytecode_get_string(bc, tag_idx));
      EMIT_NUM(ctx, n_fields);
      break;
    }

    case OP_ARRAY: {
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
      DEPTH_DEAD(depth);
      break;
    }

    case OP_PATT_STR_CMP:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_patt_str_cmp);
      break;

    case OP_PATT_STRING:
      EMIT_FUNC(ctx, op_patt_string);
      break;

    case OP_PATT_ARRAY:
      EMIT_FUNC(ctx, op_patt_array);
      break;

    case OP_PATT_SEXP:
      EMIT_FUNC(ctx, op_patt_sexp);
      break;

    case OP_PATT_BOXED:
      EMIT_FUNC(ctx, op_patt_boxed);
      break;

    case OP_PATT_UNBOXED:
      EMIT_FUNC(ctx, op_patt_unboxed);
      break;

    case OP_PATT_CLOSURE:
      EMIT_FUNC(ctx, op_patt_closure);
      break;

    case OP_BEGIN:
    case OP_BEGIN_CLOSURE: {
      int32_t n_args = reader_i32(&ctx->reader);
      int32_t n_locals = reader_i32(&ctx->reader);
      depth = 0;
      EMIT_FUNC(ctx, op_begin);
      EMIT_NUM(ctx, n_args);
      EMIT_NUM(ctx, n_locals);
      EMIT_NUM(ctx, 0);
      break;
    }

    case OP_CLOSURE: {
      int32_t target_raw = reader_i32(&ctx->reader);
      int32_t n_captured = reader_i32(&ctx->reader);

      VM_DEBUG("DECODE: OP_CLOSURE target_raw=0x%x n_captured=%d bc_off=%zu\n",
               target_raw, n_captured, current_bc_off);

      bool is_external = IS_EXT_REF(target_raw);

      // Emit load instructions for each captured variable
      for (int32_t i = 0; i < n_captured; i++) {
        uint8_t type_byte = reader_u8(&ctx->reader);
        int32_t idx = reader_i32(&ctx->reader);

        int designation_type = type_byte & 0xF;
        switch (designation_type) {
        case 0: // Global
          DEPTH_PUSH(depth);
          emit_ld_glo(ctx, idx, global_base);
          break;
        case 1: // Local
          DEPTH_PUSH(depth);
          EMIT_FUNC(ctx, op_ld_loc);
          EMIT_NUM(ctx, idx);
          break;
        case 2: // Arg
          DEPTH_PUSH(depth);
          EMIT_FUNC(ctx, op_ld_arg);
          EMIT_NUM(ctx, idx);
          break;
        case 3: // Closure var
          DEPTH_PUSH(depth);
          EMIT_FUNC(ctx, op_ld_clo);
          EMIT_NUM(ctx, idx);
          break;
        default:
          fprintf(stderr, "Unknown designation type: %d\n", designation_type);
          return NULL;
        }
      }

      DEPTH_DEC(depth, n_captured - 1);

      if (is_external) {
        int str_offset = EXT_REF_INDEX(target_raw);
        const char *ext_func_name = bytecode_get_string(bc, str_offset);

        VM_DEBUG("DECODE: OP_CLOSURE external name='%s' (stub)\n",
                 ext_func_name);

        // Emit closure with NULL target placeholder.
        // Linker will resolve to inter-unit function or create FFI stub.
        EMIT_FUNC(ctx, op_closure);
        size_t target_slot = ctx->code_len;
        EMIT_TARGET(ctx, NULL); // placeholder
        EMIT_NUM(ctx, n_captured);

        // Record stub so linker can resolve
        add_stub(ctx, target_slot, ext_func_name, STUB_CLOSURE);
      } else {
        uint32_t target_off = (uint32_t)target_raw;
        if (!validate_target_off(bc, target_off, current_bc_off, "CLOSURE")) {
          return NULL;
        }

        EMIT_FUNC(ctx, op_closure);
        size_t target_slot = ctx->code_len;
        EMIT_NUM(ctx, 0); // placeholder — will hold code index
        EMIT_NUM(ctx, n_captured);

        meta_info *tm = &meta[target_off];
        if (target_off < current_bc_off && tm->resolved_idx != -1) {
          ctx->code[target_slot].num = tm->resolved_idx;
          da_append(ctx->relocs, target_slot);
        } else {
          add_fixup(meta, target_off, target_slot);
        }
      }
      break;
    }

    case OP_CALL: {
      int32_t target_off = reader_i32(&ctx->reader);
      int32_t n_args = reader_i32(&ctx->reader);
      DEPTH_DEC(depth, n_args - 1);

      VM_DEBUG("DECODE: OP_CALL target_off=0x%x n_args=%d "
               "current_bc_off=%zu code_idx=%zu\n",
               target_off, n_args, current_bc_off, ctx->code_len);

      if (IS_EXT_REF(target_off)) {
        int str_offset = EXT_REF_INDEX(target_off);
        const char *func_name = bytecode_get_string(bc, str_offset);

        VM_DEBUG("DECODE: OP_CALL external '%s' (stub)\n", func_name);

        // To be patched by linker
        EMIT_FUNC(ctx, NULL);
        size_t name_slot = ctx->code_len;
        EMIT_TARGET(ctx, NULL);
        EMIT_NUM(ctx, n_args);

        // Record stub — linker decides if it's inter-unit or FFI
        add_stub(ctx, name_slot, func_name, STUB_CALL);
      } else {
        if (!validate_target_off(bc, (uint32_t)target_off, current_bc_off,
                                 "CALL")) {
          return NULL;
        }
        size_t target_slot = ctx->code_len + 1;
        EMIT_FUNC(ctx, op_call);
        EMIT_NUM(ctx, 0); // placeholder — will hold code index
        EMIT_NUM(ctx, n_args);

        meta_info *tm = &meta[(uint32_t)target_off];
        if ((uint32_t)target_off < current_bc_off && tm->resolved_idx != -1) {
          ctx->code[target_slot].num = tm->resolved_idx;
          da_append(ctx->relocs, target_slot);
        } else {
          add_fixup(meta, (uint32_t)target_off, target_slot);
        }
      }
      break;
    }

    case OP_CALLC: {
      int32_t n_args = reader_i32(&ctx->reader);
      DEPTH_DEC(depth, n_args);
      EMIT_FUNC(ctx, op_callc);
      EMIT_NUM(ctx, n_args);
      break;
    }

    case OP_END:
      EMIT_FUNC(ctx, op_end);
      DEPTH_DEAD(depth);
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

    case 0xFF:
    case 0x00:
      break;

    default:
      fprintf(stderr, "Not yet supported opcode 0x%02X at ip=0x%08zx\n", opcode,
              reader_pos(&ctx->reader) - 1);
      free(meta);
      return NULL;
    }
  }

  // Extract mapping
  ctx->bc_to_insn_map = ALLOC_ARRAY(int32_t, bc->code_size);
  for (size_t i = 0; i < bc->code_size; i++) {
    ctx->bc_to_insn_map[i] = meta[i].resolved_idx;
  }

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

  return ctx->code;
}

decoded **decode(bytecode **bc_arr, size_t n) {
  decoded **result = ALLOC_ARRAY(decoded *, n);

  size_t global_offset = 0;

  for (size_t i = 0; i < n; i++) {
    decode_ctx *ctx = decode_ctx_create(bc_arr[i], global_offset);
    insn *code = decode_internal(ctx);
    if (!code) {
      fprintf(stderr, "Failed to decode %s\n", bc_arr[i]->name);
      return NULL;
    }
    decoded *dec = ALLOC(decoded);
    *dec = (decoded){
        .code = code,
        .code_len = ctx->code_len,
        .stubs = ctx->stubs.data,
        .stubs_len = ctx->stubs.len,
        .bc_to_insn_map = ctx->bc_to_insn_map,
        .relocs = ctx->relocs.data,
        .relocs_len = ctx->relocs.len,
    };
    result[i] = dec;
    global_offset += bc_arr[i]->globals_count;
    free(ctx);
  }

  return result;
}

void decoded_free(decoded *dec) {
  if (dec) {
    free(dec->code);
    free(dec->stubs);
    free(dec->bc_to_insn_map);
    free(dec->relocs);
    free(dec);
  }
}
