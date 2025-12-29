#include "../runtime/gc.h"
#include "../runtime/runtime_common.h"
#include "bytecode.h"
#include "call_stack.h"
#include "opcodes.h"
#include "stack.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef DEBUG_PRINT
#define STACK_PEEK_SIZE 5
#define VM_DEBUG(fmt, ...) fprintf(stderr, fmt, ##__VA_ARGS__)
#define VM_TRACE_OP(opcode, ip)                                                \
  fprintf(stderr, "ip: 0x%08X opcode: %s (0x%02X)\n", (ip),                    \
          opcode_to_string(opcode), (opcode))
#define VM_TRACE_STACK(stack)                                                  \
  do {                                                                         \
    long sp_idx = (stack)->sp - (stack)->data;                                 \
    fprintf(stderr, "stack [sp=%p, idx=%ld]: ", (stack)->sp, sp_idx);          \
    for (int i = 1; i <= STACK_PEEK_SIZE; i++) {                               \
      if (sp_idx + i < STACK_SIZE) {                                           \
        fprintf(stderr, "%ld ", (long)(stack)->data[sp_idx + i]);              \
      }                                                                        \
    }                                                                          \
    fprintf(stderr, "\n");                                                     \
  } while (0)
#define VM_TRACE_CALL(fmt, ...) fprintf(stderr, "[CALL] " fmt, ##__VA_ARGS__)
#define VM_ASSERT(cond, msg)                                                   \
  do {                                                                         \
    if (!(cond)) {                                                             \
      fprintf(stderr, "Assert failed: %s at %s:%d\n", msg, __FILE__,           \
              __LINE__);                                                       \
      exit(1);                                                                 \
    }                                                                          \
  } while (0)
#else
#define VM_DEBUG(fmt, ...)
#define VM_TRACE_OP(opcode, ip)
#define VM_TRACE_STACK(stack)
#define VM_TRACE_CALL(fmt, ...)
#define VM_ASSERT(cond, msg)
#endif

static aint pending_closure = 0;

void *__start_custom_data;
void *__stop_custom_data;

extern void __init(void);

extern aint Lread(void);
extern aint Lwrite(aint n);
extern aint Ls__Infix_43(void *p, void *q);
extern aint Ls__Infix_45(void *p, void *q);
extern aint Ls__Infix_42(void *p, void *q);
extern aint Ls__Infix_47(void *p, void *q);
extern aint Ls__Infix_37(void *p, void *q);
extern aint Ls__Infix_60(void *p, void *q);
extern aint Ls__Infix_6061(void *p, void *q);
extern aint Ls__Infix_62(void *p, void *q);
extern aint Ls__Infix_6261(void *p, void *q);
extern aint Ls__Infix_6161(void *p, void *q);
extern aint Ls__Infix_3361(void *p, void *q);
extern aint Ls__Infix_3838(void *p, void *q);
extern aint Ls__Infix_3333(void *p, void *q);

extern aint Llength(void *p);
extern void *Lstring(aint *args);
extern aint LtagHash(char *s);
extern void *Barray(aint *args, aint bn);
extern void *Bsexp(aint *args, aint bn);
extern void *Bclosure(aint *args, aint bn);
extern void *Bstring(aint *args);
extern void *Belem(void *p, aint i);
extern void *Bsta(void *x, aint i, void *v);

extern aint Btag(void *d, aint t, aint n);
extern aint Barray_patt(void *d, aint n);
extern aint Bstring_patt(void *x, void *y);
extern aint Bclosure_tag_patt(void *x);
extern aint Bboxed_patt(void *x);
extern aint Bunboxed_patt(void *x);
extern aint Barray_tag_patt(void *x);
extern aint Bstring_tag_patt(void *x);
extern aint Bsexp_tag_patt(void *x);

static inline aint *get_local(stack_t *stack, call_frame_t *frame, int idx) {
  return &stack->data[frame->base - frame->n_args - idx];
}

static inline aint *get_arg(stack_t *stack, call_frame_t *frame, int idx) {
  return &stack->data[frame->base - idx];
}

static inline aint *get_closure_var(call_frame_t *frame, int idx) {
  data *closure_data = TO_DATA(frame->closure);
  aint *contents = (aint *)closure_data->contents;
  // +1 because contents[0] is the entry point
  return &contents[idx + 1];
}

static aint read_designation(stack_t *stack, call_frame_t *frame, aint *globals,
                             const uint8_t *code, int *ip_ptr) {
  uint8_t type_byte = code[(*ip_ptr)++];
  int idx = read_i32(code, *ip_ptr);
  *ip_ptr += 4;

  int designation_type = type_byte & 0xF;
  switch (designation_type) {
  case 0:
    return globals[idx];
  case 1:
    return *get_local(stack, frame, idx);
  case 2:
    return *get_arg(stack, frame, idx);
  case 3:
    return *get_closure_var(frame, idx);
  default:
    fprintf(stderr, "Unknown designation type: %d\n", designation_type);
    exit(1);
  }
}

void run(bytecode *bc) {
  stack_t stack;
  call_stack_t call_stack;
  stack_init(&stack);
  call_stack_init(&call_stack);

  // gc initialization
  __init();

  aint *globals = stack.data;
  // space for globals
  // TODO: might not be the place to store globals
  for (int i = 0; i < bc->globals_count; i++) {
    stack_push(&stack, 0);
  }

  int ip = bc->entry_point;
  int return_ip = -1;

  while (ip < bc->code_size) {
    uint8_t opcode = bc->code[ip++];
    int l = opcode & 0xF;

    VM_TRACE_OP(opcode, ip - 1);
    VM_TRACE_STACK(&stack);

    switch (opcode) {
    case OP_CONST: {
      int n = read_i32(bc->code, ip);
      ip += 4;
      VM_DEBUG("CONST: %d\n", n);
      stack_push(&stack, BOX(n));
      break;
    }
    case OP_BINOP_ADD:
    case OP_BINOP_SUB:
    case OP_BINOP_MUL:
    case OP_BINOP_DIV:
    case OP_BINOP_MOD:
    case OP_BINOP_EQ:
    case OP_BINOP_NE:
    case OP_BINOP_LT:
    case OP_BINOP_LE:
    case OP_BINOP_GT:
    case OP_BINOP_GE:
    case OP_BINOP_AND:
    case OP_BINOP_OR: {
      aint y = stack_pop(&stack);
      aint x = stack_pop(&stack);
      aint result;
      switch (l) {
      case 1: // +
        result = Ls__Infix_43((void *)x, (void *)y);
        break;
      case 2: // -
        result = Ls__Infix_45((void *)x, (void *)y);
        break;
      case 3: // *
        result = Ls__Infix_42((void *)x, (void *)y);
        break;
      case 4: // /
        if (UNBOX(y) == 0) {
          fprintf(stderr, "Division by zero\n");
          goto end;
        }
        result = Ls__Infix_47((void *)x, (void *)y);
        break;
      case 5: // %
        if (UNBOX(y) == 0) {
          fprintf(stderr, "Division by zero\n");
          goto end;
        }
        result = Ls__Infix_37((void *)x, (void *)y);
        break;
      case 6: // <
        result = Ls__Infix_60((void *)x, (void *)y);
        break;
      case 7: // <=
        result = Ls__Infix_6061((void *)x, (void *)y);
        break;
      case 8: // >
        result = Ls__Infix_62((void *)x, (void *)y);
        break;
      case 9: // >=
        result = Ls__Infix_6261((void *)x, (void *)y);
        break;
      case 10: // ==
        result = Ls__Infix_6161((void *)x, (void *)y);
        break;
      case 11: // !=
        result = Ls__Infix_3361((void *)x, (void *)y);
        break;
      case 12: // &&
        result = Ls__Infix_3838((void *)x, (void *)y);
        break;
      case 13: // !!
        result = Ls__Infix_3333((void *)x, (void *)y);
        break;
      }
      stack_push(&stack, result);
      break;
    }
    case OP_JMP: {
      int addr = read_i32(bc->code, ip);
      ip = addr;
      break;
    }
    case OP_CJMP_Z: {
      int addr = read_i32(bc->code, ip);
      ip += 4;
      aint val = stack_pop(&stack);
      if (UNBOX(val) == 0) {
        ip = addr;
      }
      break;
    }
    case OP_CJMP_NZ: {
      int addr = read_i32(bc->code, ip);
      ip += 4;
      aint val = stack_pop(&stack);
      if (UNBOX(val) != 0) {
        ip = addr;
      }
      break;
    }
    // TODO: unify ld and st
    case OP_LD: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      aint val = globals[idx];
      VM_DEBUG("LD global[%d] = %ld\n", idx, val);
      stack_push(&stack, val);
      break;
    }
    case OP_LD_LOC: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      call_frame_t *frame = call_stack_current(&call_stack);
      aint val = *get_local(&stack, frame, idx);
      VM_DEBUG("LD_LOC local[%d] = %ld\n", idx, val);
      stack_push(&stack, val);
      break;
    }
    case OP_LD_ARG: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      call_frame_t *frame = call_stack_current(&call_stack);
      aint val = *get_arg(&stack, frame, idx);
      VM_DEBUG("LD_ARG arg[%d] = %ld\n", idx, val);
      stack_push(&stack, val);
      break;
    }
    case OP_LD_CLO: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      call_frame_t *frame = call_stack_current(&call_stack);
      aint val = *get_closure_var(frame, idx);
      VM_DEBUG("LD_CLO closure[%d] = %ld\n", idx, val);
      stack_push(&stack, val);
      break;
    }
    case OP_ST: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      aint val = stack_pop(&stack);
      VM_DEBUG("ST global[%d] = %ld\n", idx, val);
      globals[idx] = val;
      stack_push(&stack, val);
      break;
    }
    case OP_ST_LOC: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      call_frame_t *frame = call_stack_current(&call_stack);
      aint val = stack_pop(&stack);
      VM_DEBUG("ST_LOC local[%d] = %ld\n", idx, val);
      *get_local(&stack, frame, idx) = val;
      stack_push(&stack, val);
      break;
    }
    case OP_ST_ARG: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      call_frame_t *frame = call_stack_current(&call_stack);
      aint val = stack_pop(&stack);
      VM_DEBUG("ST_ARG arg[%d] = %ld\n", idx, val);
      *get_arg(&stack, frame, idx) = val;
      stack_push(&stack, val);
      break;
    }
    case OP_ST_CLO: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      call_frame_t *frame = call_stack_current(&call_stack);
      aint val = stack_pop(&stack);
      VM_DEBUG("ST_CLO closure[%d] = %ld\n", idx, val);
      *get_closure_var(frame, idx) = val;
      stack_push(&stack, val);
      break;
    }
    case OP_DROP:
      stack_pop(&stack);
      break;
    case OP_DUP:
      stack_dup(&stack);
      break;
    case OP_SWAP:
      stack_swap(&stack);
      break;
    // TODO: possibly unify as well
    case OP_BEGIN: {
      int n_args = read_i32(bc->code, ip);
      ip += 4;
      int n_locals = read_i32(bc->code, ip);
      ip += 4;
      VM_TRACE_CALL("BEGIN n_args=%d n_locals=%d\n", n_args, n_locals);

      // base points to arg0 (highest address of args)
      int base = (stack.sp - stack.data) + n_args;

      // space for locals
      for (int i = 0; i < n_locals; i++) {
        stack_push(&stack, 0);
      }

      call_stack_push(&call_stack, return_ip, base, n_args, n_locals, 0);
      break;
    }
    case OP_BEGIN_CLOSURE: {
      int n_args = read_i32(bc->code, ip);
      ip += 4;
      int n_locals = read_i32(bc->code, ip);
      ip += 4;
      VM_TRACE_CALL("BEGIN_CLOSURE n_args=%d n_locals=%d\n", n_args, n_locals);

      // CALLC already shifted args and removed closure from stack
      int base = (stack.sp - stack.data) + n_args;
      aint closure = pending_closure;

      // space for locals
      for (int i = 0; i < n_locals; i++) {
        stack_push(&stack, 0);
      }

      call_stack_push(&call_stack, return_ip, base, n_args, n_locals, closure);
      break;
    }
    case OP_CLOSURE: {
      // addr:32 n_captured:32 [type:8 idx:32]...
      int addr = read_i32(bc->code, ip);
      ip += 4;
      int n_captured = read_i32(bc->code, ip);
      ip += 4;

      VM_DEBUG("CLOSURE addr=0x%08X n_captured=%d\n", addr, n_captured);

      aint args[n_captured + 1];
      args[0] = BOX(addr);

      for (int i = 0; i < n_captured; i++) {
        aint val = read_designation(&stack, call_stack_current(&call_stack),
                                    globals, bc->code, &ip);
        VM_DEBUG("Captured[%d] = %ld\n", i, val);
        args[i + 1] = val;
      }

      void *closure = Bclosure(args, BOX(n_captured + 1));
      stack_push(&stack, (aint)closure);
      break;
    }
    case OP_CALLC: {
      int n_args = read_i32(bc->code, ip);
      ip += 4;

      // stack: [... closure arg0 arg1 ... argN-1]
      int base = (stack.sp - stack.data) + n_args + 1;
      aint closure = stack.data[base];

      // save closure for BEGIN_CLOSURE to retrieve
      pending_closure = closure;

      // shift args over closure slot, removing closure from stack
      for (int i = 0; i < n_args; i++) {
        stack.data[base - i] = stack.data[base - i - 1];
      }
      stack.sp++;

      aint entry_point = UNBOX(((aint *)closure)[0]);
      VM_TRACE_CALL("CALLC n_args=%d closure=0x%lx entry=0x%lx\n", n_args,
                    closure, entry_point);
      return_ip = ip;
      ip = entry_point;
      break;
    }
    case OP_CALL: {
      int addr = read_i32(bc->code, ip);
      ip += 4;
      // discarding n_args
      ip += 4;
      VM_TRACE_CALL("CALL addr=0x%08X\n", addr);
      return_ip = ip;
      ip = addr;
      break;
    }
    case OP_RET:
    case OP_END: {
      if (call_stack_is_empty(&call_stack)) {
        goto end;
      }
      call_frame_t frame = call_stack_pop(&call_stack);

      int current_top = stack.sp - stack.data;
      int returns_start = frame.base - frame.n_args - frame.n_locals;
      int n_returns = returns_start - current_top;

      if (n_returns <= 0) {
        n_returns = 0;
      } else {
        for (int i = 0; i < n_returns; i++) {
          // TODO: make stack function for this
          stack.data[frame.base - i] = stack.data[returns_start - i];
        }
      }

      // sp points to empty slot below the return values
      stack.sp = stack.data + frame.base - n_returns;
      if (frame.return_ip < 0) {
        goto end;
      }
      ip = frame.return_ip;
      break;
    }

    case OP_READ: {
      stack_push(&stack, Lread());
      break;
    }
    case OP_WRITE: {
      aint val = stack_pop(&stack);
      stack_push(&stack, Lwrite(val));
      break;
    }
    case OP_STRING: {
      // push string from string table onto stack
      int str_offset = read_i32(bc->code, ip);
      ip += 4;
      const char *src = bc->string_table + str_offset;
      void *str = Bstring((void *)&src);
      stack_push(&stack, (aint)str);
      break;
    }
    case OP_ELEM: {
      // [top --> index, array] -> [element]
      aint idx = stack_pop(&stack);
      aint arr = stack_pop(&stack);
      void *elem = Belem((void *)arr, idx);
      stack_push(&stack, (aint)elem);
      break;
    }
    case OP_STA: {
      // TODO: support string (two operands)
      aint val = stack_pop(&stack);
      aint idx = stack_pop(&stack);
      aint arr = stack_pop(&stack);
      Bsta((void *)arr, idx, (void *)val);
      stack_push(&stack, val);
      break;
    }
    case OP_LENGTH: {
      aint val = stack_pop(&stack);
      aint len = Llength((void *)val);
      stack_push(&stack, len);
      break;
    }
    case OP_LSTRING: {
      aint val = stack_pop(&stack);
      void *str = Lstring(&val);
      stack_push(&stack, (aint)str);
      break;
    }
    case OP_BARRAY: {
      int n = read_i32(bc->code, ip);
      ip += 4;
      aint args[n];
      for (int i = n - 1; i >= 0; i--) {
        args[i] = stack_pop(&stack);
      }
      void *arr = Barray(args, BOX(n));
      stack_push(&stack, (aint)arr);
      break;
    }
    case OP_SEXP: {
      int tag_offset = read_i32(bc->code, ip);
      ip += 4;
      int n_fields = read_i32(bc->code, ip);
      ip += 4;
      const char *tag_str = bc->string_table + tag_offset;
      aint tag_hash = LtagHash((char *)tag_str);
      aint args[n_fields + 1];
      for (int i = n_fields - 1; i >= 0; i--) {
        args[i] = stack_pop(&stack);
      }
      args[n_fields] = tag_hash;

      void *s = Bsexp(args, BOX(n_fields + 1));
      stack_push(&stack, (aint)s);
      break;
    }
    case OP_TAG: {
      int tag_offset = read_i32(bc->code, ip);
      ip += 4;
      int n_fields = read_i32(bc->code, ip);
      ip += 4;
      const char *tag_str = bc->string_table + tag_offset;
      aint tag_hash = LtagHash((char *)tag_str);
      aint val = stack_pop(&stack);
      aint result = Btag((void *)val, tag_hash, BOX(n_fields));
      stack_push(&stack, result);
      break;
    }
    case OP_ARRAY: {
      int n = read_i32(bc->code, ip);
      ip += 4;
      aint val = stack_pop(&stack);
      aint result = Barray_patt((void *)val, BOX(n));
      stack_push(&stack, result);
      break;
    }
    case OP_FAIL: {
      int line = read_i32(bc->code, ip);
      ip += 4;
      int col = read_i32(bc->code, ip);
      ip += 4;
      fprintf(stderr, "Match failure at line %d, column %d\n", line, col);
      goto end;
    }
    case OP_PATT_STR_CMP: {
      aint y = stack_pop(&stack);
      aint x = stack_pop(&stack);
      aint result = Bstring_patt((void *)x, (void *)y);
      stack_push(&stack, result);
      break;
    }
    case OP_PATT_STRING: {
      aint val = stack_pop(&stack);
      aint result = Bstring_tag_patt((void *)val);
      stack_push(&stack, result);
      break;
    }
    case OP_PATT_ARRAY: {
      aint val = stack_pop(&stack);
      aint result = Barray_tag_patt((void *)val);
      stack_push(&stack, result);
      break;
    }
    case OP_PATT_SEXP: {
      aint val = stack_pop(&stack);
      aint result = Bsexp_tag_patt((void *)val);
      stack_push(&stack, result);
      break;
    }
    case OP_PATT_BOXED: {
      aint val = stack_pop(&stack);
      aint result = Bboxed_patt((void *)val);
      stack_push(&stack, result);
      break;
    }
    case OP_PATT_UNBOXED: {
      aint val = stack_pop(&stack);
      aint result = Bunboxed_patt((void *)val);
      stack_push(&stack, result);
      break;
    }
    case OP_PATT_CLOSURE: {
      aint val = stack_pop(&stack);
      aint result = Bclosure_tag_patt((void *)val);
      stack_push(&stack, result);
      break;
    }
    case OP_HALT:
      goto end;
    case OP_LINE:
      ip += 4;
      break;
    default:
      fprintf(stderr, "Not yet supported opcode 0x%02X at ip=0x%08x\n", opcode,
              ip - 1);
      goto end;
    }
  }

end:
}

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stderr, "Usage: %s <bytecode.bc>\n", argv[0]);
    return 1;
  }

  bytecode *bc = load_bytecode(argv[1]);
  if (!bc) {
    return 1;
  }

  run(bc);

  free_bytecode(bc);
  return 0;
}
