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
  OP_DROP = 0x18,
  OP_DUP = 0x19,
  OP_SWAP = 0x1A,
  OP_LD = 0x20,
  OP_ST = 0x40,
  OP_BEGIN = 0x52,
  OP_BEGIN_CLOSURE = 0x53,
  OP_LINE = 0x5A,
  OP_READ = 0x70,
  OP_WRITE = 0x71,
  OP_STOP = 0xFF,
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
static int stack[STACK_SIZE];
static int sp = 0;

static void push(int val) {
  if (sp >= STACK_SIZE) {
    fprintf(stderr, "Stack overflow\n");
    exit(1);
  }
  stack[sp++] = val;
}

static int pop(void) {
  if (sp <= 0) {
    fprintf(stderr, "Cannot pop from an empty stack");
    exit(1);
  }
  return stack[--sp];
}

static int peek(void) {
  if (sp <= 0) {
    fprintf(stderr, "Cannot peek from an empty stack");
    exit(1);
  }
  return stack[sp - 1];
}

void run(bytecode *bc) {
  int *globals = malloc(sizeof(int) * bc->globals_count);
  int ip = bc->entry_point;

  while (ip < bc->code_size) {
    uint8_t opcode = bc->code[ip++];
    int l = opcode & 0xF;

    switch (opcode) {
    case OP_CONST: {
      int n = read_i32(bc->code, ip);
      ip += 4;
      push(n);
      break;
    }
    case OP_BINOP_ADD:
    case OP_BINOP_SUB:
    case OP_BINOP_MUL:
    case OP_BINOP_DIV:
    case OP_BINOP_MOD: {
      int y = pop();
      int x = pop();
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
      push(result);
      break;
    }
    case OP_LD: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      push(globals[idx]);
      break;
    }
    case OP_ST: {
      int idx = read_i32(bc->code, ip);
      ip += 4;
      int val = pop();
      globals[idx] = val;
      push(val);
      break;
    }
    case OP_DROP:
      pop();
      break;
    case OP_DUP: {
      int x = peek();
      push(x);
      break;
    }
    case OP_SWAP: {
      int y = pop();
      int x = pop();
      push(y);
      push(x);
      break;
    }
    case OP_BEGIN:
    case OP_BEGIN_CLOSURE:
      // TODO: skip for now
      ip += 8;
      break;
    case OP_READ: {
      int x;
      // TODO: scanf ?
      if (scanf("%d", &x) != 1) {
        fprintf(stderr, "Failed to read\n");
        goto end;
      }
      push(x);
      break;
    }
    case OP_WRITE: {
      int x = pop();
      printf("%d\n", x);
      push(x);
      break;
    }
    case OP_END:
    case OP_STOP:
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
