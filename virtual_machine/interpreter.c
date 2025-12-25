#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "bytecode.h"
#include "opcodes.h"
#include "stack.h"

typedef struct frame {
  struct frame *parent;
  int return_ip;
  int n_args;
  int n_locals;
  int locals[];
} frame;

static frame *current_frame = NULL;
static int return_ip = -1;

static frame *frame_create(frame *parent, int ret_ip, int n_args, int n_locals) {
  int total_locals = n_args + n_locals;
  frame *f = malloc(sizeof(frame) + total_locals * sizeof(int));
  f->parent = parent;
  f->return_ip = ret_ip;
  f->n_args = n_args;
  f->n_locals = n_locals;
  memset(f->locals, 0, total_locals * sizeof(int));
  return f;
}

static int *frame_local(frame *f, int idx) {
  return &f->locals[idx];
}

static int *frame_arg(frame *f, int idx) {
  return &f->locals[f->n_locals + idx];
}

static void frame_drop(frame *f) {
  free(f);
}

void run(bytecode *bc) {
  stack_t stack;
  stack_init(&stack);
  int *globals = malloc(sizeof(int) * bc->globals_count);
  int ip = bc->entry_point;

  while (ip < bc->code_size) {
    uint8_t opcode = bc->code[ip++];
    int l = opcode & 0xF;

    // printf("ip=%d opcode=0x%02X\n", ip, opcode);

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
    case OP_BINOP_MOD: {
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
      }
      stack_push(&stack, result);
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
      stack_push(&stack, *frame_local(current_frame, idx));
      break;
    }
    case OP_LD_ARG: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      stack_push(&stack, *frame_arg(current_frame, idx));
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
      int val = stack_pop(&stack);
      *frame_local(current_frame, idx) = val;
      stack_push(&stack, val);
      break;
    }
    case OP_ST_ARG: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      int val = stack_pop(&stack);
      *frame_arg(current_frame, idx) = val;
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
      frame *new_frame = frame_create(current_frame, return_ip, n_args, n_locals);
      for (int i = n_args - 1; i >= 0; i--) {
        *frame_arg(new_frame, i) = stack_pop(&stack);
      }
      current_frame = new_frame;
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
      if (current_frame == NULL) {
        goto end;
      }
      int ret_ip = current_frame->return_ip;
      frame *parent = current_frame->parent;
      frame_drop(current_frame);
      current_frame = parent;
      if (ret_ip < 0) {
        goto end;
      }
      ip = ret_ip;
      break;
    }
    case OP_READ: {
      int x;
      // TODO: scanf ?
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
      fprintf(stderr, "Not yet supported opcode 0x%02X at ip=%d\n", opcode, ip);
      goto end;
    }
  }

end:
  while (current_frame) {
    frame *parent = current_frame->parent;
    frame_drop(current_frame);
    current_frame = parent;
  }
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
