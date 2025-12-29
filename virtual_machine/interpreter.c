#include "../runtime/gc.h"
#include "../runtime/runtime_common.h"
#include "bytecode.h"
#include "call_stack.h"
#include "opcodes.h"
#include "stack.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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
extern void *Bstring(aint *args);
extern void *Belem(void *p, aint i);
extern void *Bsta(void *x, aint i, void *v);

static inline aint *get_local(stack_t *stack, call_frame_t *frame, int idx) {
  return &stack->data[frame->base - frame->n_args - idx];
}

static inline aint *get_arg(stack_t *stack, call_frame_t *frame, int idx) {
  return &stack->data[frame->base - idx];
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

    // printf("ip=0x%08X opcode=0x%02X\n", ip-1, opcode);
    // printf("stack pointer: %p\n", stack.sp);

    switch (opcode) {
    case OP_CONST: {
      int n = read_i32(bc->code, ip);
      ip += 4;
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
    case OP_LD: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      stack_push(&stack, globals[idx]);
      break;
    }
    case OP_LD_LOC: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      call_frame_t *frame = call_stack_current(&call_stack);
      stack_push(&stack, *get_local(&stack, frame, idx));
      break;
    }
    case OP_LD_ARG: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      call_frame_t *frame = call_stack_current(&call_stack);
      stack_push(&stack, *get_arg(&stack, frame, idx));
      break;
    }
    case OP_ST: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      aint val = stack_pop(&stack);
      globals[idx] = val;
      stack_push(&stack, val);
      break;
    }
    case OP_ST_LOC: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      call_frame_t *frame = call_stack_current(&call_stack);
      aint val = stack_pop(&stack);
      *get_local(&stack, frame, idx) = val;
      stack_push(&stack, val);
      break;
    }
    case OP_ST_ARG: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      call_frame_t *frame = call_stack_current(&call_stack);
      aint val = stack_pop(&stack);
      *get_arg(&stack, frame, idx) = val;
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
    case OP_BEGIN: {
      int n_args = read_i32(bc->code, ip);
      ip += 4;
      int n_locals = read_i32(bc->code, ip);
      ip += 4;

      // base points to arg0 (highest address of args)
      int base = (stack.sp - stack.data) + n_args;

      // space for locals
      for (int i = 0; i < n_locals; i++) {
        stack_push(&stack, 0);
      }

      call_stack_push(&call_stack, return_ip, base, n_args, n_locals);
      break;
    }
    case OP_BEGIN_CLOSURE:
      // TODO: skip for now
      ip += 8;
      break;
    case OP_CALL: {
      int addr = read_i32(bc->code, ip);
      ip += 4;
      // discarding n_args
      ip += 4;
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
      // [index, array] -> [element]
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
