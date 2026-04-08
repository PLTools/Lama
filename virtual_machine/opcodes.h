#ifndef OPCODES_H
#define OPCODES_H

#include <stdbool.h>
#include <stdint.h>

typedef enum {
  OP_BINOP_ADD = 0x01,
  OP_BINOP_SUB = 0x02,
  OP_BINOP_MUL = 0x03,
  OP_BINOP_DIV = 0x04,
  OP_BINOP_MOD = 0x05,
  OP_BINOP_LT = 0x06,
  OP_BINOP_LE = 0x07,
  OP_BINOP_GT = 0x08,
  OP_BINOP_GE = 0x09,
  OP_BINOP_EQ = 0x0A,
  OP_BINOP_NE = 0x0B,
  OP_BINOP_AND = 0x0C,
  OP_BINOP_OR = 0x0D,
  OP_CONST = 0x10,
  OP_STRING = 0x11,
  OP_SEXP = 0x12,
  OP_STA = 0x14,
  OP_JMP = 0x15,
  OP_END = 0x16,
  OP_DROP = 0x18,
  OP_DUP = 0x19,
  OP_SWAP = 0x1A,
  OP_ELEM = 0x1B,
  OP_LD_GLO = 0x20,
  OP_LD_LOC = 0x21,
  OP_LD_ARG = 0x22,
  OP_LD_CLO = 0x23,
  OP_ST_GLO = 0x40,
  OP_ST_LOC = 0x41,
  OP_ST_ARG = 0x42,
  OP_ST_CLO = 0x43,
  OP_CJMP_Z = 0x50,
  OP_CJMP_NZ = 0x51,
  OP_BEGIN = 0x52,
  OP_BEGIN_CLOSURE = 0x53,
  OP_CLOSURE = 0x54,
  OP_CALLC = 0x55,
  OP_CALL = 0x56,
  OP_TAG = 0x57,
  OP_ARRAY = 0x58,
  OP_FAIL = 0x59,
  OP_FAIL_KEEP = 0x5A,
  OP_LINE = 0x5B,
  OP_PATT_STR_CMP = 0x60,
  OP_PATT_STRING = 0x61,
  OP_PATT_ARRAY = 0x62,
  OP_PATT_SEXP = 0x63,
  OP_PATT_BOXED = 0x64,
  OP_PATT_UNBOXED = 0x65,
  OP_PATT_CLOSURE = 0x66,
  OP_BARRAY = 0x74,
  OP_EOF = 0xFF,
} opcode_t;

const char *opcode_to_string(uint8_t opcode);

static inline bool opcode_is_func_begin(uint8_t opcode) {
  return opcode == OP_BEGIN || opcode == OP_BEGIN_CLOSURE;
}

#endif
