#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
  OP_BINOP_ADD = 0x01,
  OP_BINOP_SUB = 0x02,
  OP_BINOP_MUL = 0x03,
  OP_BINOP_DIV = 0x04,
  OP_BINOP_MOD = 0x05,
  OP_CONST = 0x10,
  OP_END = 0x16,
  OP_RET = 0x17,
  OP_DROP = 0x18,
  OP_DUP = 0x19,
  OP_SWAP = 0x1A,
  OP_LD = 0x20,
  OP_LD_LOC = 0x21,
  OP_LD_ARG = 0x22,
  OP_ST = 0x40,
  OP_ST_LOC = 0x41,
  OP_ST_ARG = 0x42,
  OP_BEGIN = 0x52,
  OP_BEGIN_CLOSURE = 0x53,
  OP_CALL = 0x56,
  OP_LINE = 0x5A,
  OP_READ = 0x70,
  OP_WRITE = 0x71,
  OP_HALT = 0xFF,
} opcode_t;

typedef struct {
  const uint8_t *code;
  int code_size;
  int entry_point;
  int globals_count;
} bytecode;

static inline int read_i32(const uint8_t data[], int offset) {
  return data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16) |
         (data[offset + 3] << 24);
}

#define HEADER_SIZE 12
#define PUB_ENTRY_SIZE 8

static int find_entry_point(const uint8_t *data, int pubs_offset, int num_pubs,
                            const uint8_t *string_table, const char *name) {
  for (int i = 0; i < num_pubs; i++) {
    int entry_offset = pubs_offset + i * PUB_ENTRY_SIZE;
    int name_offset = read_i32(data, entry_offset);
    char *f_name = (char *)(string_table + name_offset);
    int address = read_i32(data, entry_offset + 4);
    if (strcmp(f_name, name) == 0) {
      return address;
    }
  }
  return -1;
}

bytecode *load_bytecode(const char *filename) {
  FILE *f = fopen(filename, "rb");
  if (!f) {
    perror("fopen");
    return NULL;
  }

  fseek(f, 0, SEEK_END);
  long size = ftell(f);
  rewind(f);

  uint8_t *data = malloc(size);

  if (!data) {
    fclose(f);
    return NULL;
  }

  if (fread(data, 1, size, f) != size) {
    perror("fread");
    fclose(f);
    free(data);
    return NULL;
  }
  fclose(f);

  int st_size = read_i32(data, 0);
  int globals_count = read_i32(data, 4);
  int num_pubs = read_i32(data, 8);
  int num_imports = read_i32(data, 12);
  int num_ext_fixups = read_i32(data, 16);

  int pubs_offset = HEADER_SIZE;
  int st_offset = pubs_offset + num_pubs * PUB_ENTRY_SIZE;
  int code_offset = st_offset + st_size;
  int code_size = size - code_offset;

  uint8_t *string_table = data + st_offset;
  int main_entry_point =
      find_entry_point(data, pubs_offset, num_pubs, string_table, "main");

  bytecode *bc = malloc(sizeof(bytecode));
  bc->code = malloc(code_size);
  memcpy(bc->code, data + code_offset, code_size);
  bc->code_size = code_size;
  bc->entry_point = main_entry_point;
  bc->globals_count = globals_count;

  free(data);
  return bc;
}

#define STACK_SIZE 1024

static inline void push(int **sp, int val) {
  *(*sp)++ = val;
}

static inline int pop(int **sp) {
  return *--(*sp);
}

static inline int peek(int **sp) {
  return *(*sp - 1);
}

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
  int stack[STACK_SIZE];
  int *sp = stack;
  int *globals = malloc(sizeof(int) * bc->globals_count);
  int ip = bc->entry_point;
  int pending_args = 0;

  while (ip < bc->code_size) {
    uint8_t opcode = bc->code[ip++];
    int l = opcode & 0xF;

    printf("ip=%d opcode=0x%02X\n", ip, opcode);

    switch (opcode) {
    case OP_CONST: {
      int n = read_i32(bc->code, ip);
      ip += 4;
      push(&sp, n);
      break;
    }
    case OP_BINOP_ADD:
    case OP_BINOP_SUB:
    case OP_BINOP_MUL:
    case OP_BINOP_DIV:
    case OP_BINOP_MOD: {
      int y = pop(&sp);
      int x = pop(&sp);
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
      push(&sp, result);
      break;
    }
    case OP_LD: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      push(&sp, globals[idx]);
      break;
    }
    case OP_LD_LOC: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      push(&sp, *frame_local(current_frame, idx));
      break;
    }
    case OP_LD_ARG: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      push(&sp, *frame_arg(current_frame, idx));
      break;
    }
    case OP_ST: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      int val = pop(&sp);
      globals[idx] = val;
      push(&sp, val);
      break;
    }
    case OP_ST_LOC: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      int val = pop(&sp);
      *frame_local(current_frame, idx) = val;
      push(&sp, val);
      break;
    }
    case OP_ST_ARG: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      int val = pop(&sp);
      *frame_arg(current_frame, idx) = val;
      push(&sp, val);
      break;
    }
    case OP_DROP:
      pop(&sp);
      break;
    case OP_DUP:
      push(&sp, peek(&sp));
      break;
    case OP_SWAP: {
      int y = pop(&sp);
      int x = pop(&sp);
      push(&sp, y);
      push(&sp, x);
      break;
    }
    case OP_BEGIN: {
      int n_args = read_i32(bc->code, ip);
      ip += 4;
      int n_locals = read_i32(bc->code, ip);
      ip += 4;
      frame *new_frame = frame_create(current_frame, return_ip, n_args, n_locals);
      for (int i = n_args - 1; i >= 0; i--) {
        *frame_arg(new_frame, i) = pop(&sp);
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
      push(&sp, x);
      break;
    }
    case OP_WRITE: {
      int x = pop(&sp);
      printf("%d\n", x);
      push(&sp, x);
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

  free(bc->code);
  free(bc);
  return 0;
}
