#include "bytecode.h"
#include "call_stack.h"
#include "opcodes.h"
#include "stack.h"
#include <stdio.h>
#include <stdlib.h>

static inline int *get_local(stack_t *stack, call_frame_t *frame, int idx) {
  return &stack->data[frame->base + frame->n_args + idx];
}

static inline int *get_arg(stack_t *stack, call_frame_t *frame, int idx) {
  return &stack->data[frame->base + idx];
}

void run(bytecode *bc) {
  stack_t stack;
  call_stack_t call_stack;
  stack_init(&stack);
  call_stack_init(&call_stack);

  int *globals = malloc(sizeof(int) * bc->globals_count);

  int ip = bc->entry_point;
  int return_ip = -1;

  while (ip < bc->code_size) {
    uint8_t opcode = bc->code[ip++];
    int l = opcode & 0xF;

    // printf("ip=0x%08X opcode=0x%02X\n", ip-1, opcode);

    switch (opcode) {
    case OP_CONST: {
      int n = read_i32(bc->code, ip);
      ip += 4;
      stack_push(&stack, n);
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
    case OP_BINOP_GE: {
      int y = stack_pop(&stack);
      int x = stack_pop(&stack);
      int result;
      switch (l) {
      case 1:
        result = x + y;
        break;
      case 2:
        result = x - y;
        break;
      case 3:
        result = x * y;
        break;
      case 4:
        if (y == 0) {
          fprintf(stderr, "Division by zero\n");
          goto end;
        }
        result = x / y;
        break;
      case 5:
        if (y == 0) {
          fprintf(stderr, "Division by zero\n");
          goto end;
        }
        result = x % y;
        break;
      case 6: 
        result = x < y;
        break;
      case 7:
        result = x <= y;
        break;
      case 8:
        result = x > y;
        break;
      case 9:
        result = x >= y;
        break;
      case 10:
        result = x == y;
        break;
      case 11:
        result = x != y;
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
      int val = stack_pop(&stack);
      if (val == 0) {
        ip = addr;
      }
      break;
    }
    case OP_CJMP_NZ: {
      int addr = read_i32(bc->code, ip);
      ip += 4;
      int val = stack_pop(&stack);
      if (val != 0) {
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
      int val = stack_pop(&stack);
      globals[idx] = val;
      stack_push(&stack, val);
      break;
    }
    case OP_ST_LOC: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      call_frame_t *frame = call_stack_current(&call_stack);
      int val = stack_pop(&stack);
      *get_local(&stack, frame, idx) = val;
      stack_push(&stack, val);
      break;
    }
    case OP_ST_ARG: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      call_frame_t *frame = call_stack_current(&call_stack);
      int val = stack_pop(&stack);
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

      int base = (stack.sp - stack.data) - n_args;

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
        int returns_start = frame.base + frame.n_args + frame.n_locals;
        int n_returns = current_top - returns_start;

        if (n_returns <= 0) {  
          n_returns = 0;
        } else {
            for (int i = 0; i < n_returns; i++) {
                stack.data[frame.base + i] = stack.data[returns_start + i];
            }
        }

        stack.sp = stack.data + frame.base + n_returns;
        if (frame.return_ip < 0) {
            goto end;
        }
        ip = frame.return_ip;
        break;
    }

    case OP_READ: {
      int x;
      if (scanf("%d", &x) != 1) {
        fprintf(stderr, "Failed to read\n");
        goto end;
      }
      stack_push(&stack, x);
      break;
    }
    case OP_WRITE: {
      int x = stack_pop(&stack);
      printf("%d\n", x);
      stack_push(&stack, x);
      break;
    }
    case OP_HALT:
      goto end;
    case OP_LINE:
      ip += 4;
      break;
    default:
      fprintf(stderr, "Not yet supported opcode 0x%02X at ip=0x%08x\n", opcode, ip-1);
      goto end;
    }
  }

end:
  free(globals);
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
