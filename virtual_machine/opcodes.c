/*
 * Utility functions for Lama VM opcodes.
 * Provides debugging support, such as converting opcode values to string
 * representations.
 */

#include "opcodes.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

const char *opcode_to_string(uint8_t opcode) {
  switch (opcode) {
  case OP_BINOP_ADD:
    return "BINOP_ADD";
  case OP_BINOP_SUB:
    return "BINOP_SUB";
  case OP_BINOP_MUL:
    return "BINOP_MUL";
  case OP_BINOP_DIV:
    return "BINOP_DIV";
  case OP_BINOP_MOD:
    return "BINOP_MOD";
  case OP_BINOP_LT:
    return "BINOP_LT";
  case OP_BINOP_LE:
    return "BINOP_LE";
  case OP_BINOP_GT:
    return "BINOP_GT";
  case OP_BINOP_GE:
    return "BINOP_GE";
  case OP_BINOP_EQ:
    return "BINOP_EQ";
  case OP_BINOP_NE:
    return "BINOP_NE";
  case OP_BINOP_AND:
    return "BINOP_AND";
  case OP_BINOP_OR:
    return "BINOP_OR";
  case OP_CONST:
    return "CONST";
  case OP_STRING:
    return "STRING";
  case OP_SEXP:
    return "SEXP";
  case OP_STA:
    return "STA";
  case OP_JMP:
    return "JMP";
  case OP_END:
    return "END";
  case OP_RET:
    return "RET";
  case OP_DROP:
    return "DROP";
  case OP_DUP:
    return "DUP";
  case OP_SWAP:
    return "SWAP";
  case OP_ELEM:
    return "ELEM";
  case OP_LD:
    return "LD";
  case OP_LD_LOC:
    return "LD_LOC";
  case OP_LD_ARG:
    return "LD_ARG";
  case OP_LD_CLO:
    return "LD_CLO";
  case OP_ST:
    return "ST";
  case OP_ST_LOC:
    return "ST_LOC";
  case OP_ST_ARG:
    return "ST_ARG";
  case OP_ST_CLO:
    return "ST_CLO";
  case OP_CJMP_Z:
    return "CJMP_Z";
  case OP_CJMP_NZ:
    return "CJMP_NZ";
  case OP_BEGIN:
    return "BEGIN";
  case OP_BEGIN_CLOSURE:
    return "BEGIN_CLOSURE";
  case OP_CLOSURE:
    return "CLOSURE";
  case OP_CALLC:
    return "CALLC";
  case OP_CALL:
    return "CALL";
  case OP_TAG:
    return "TAG";
  case OP_ARRAY:
    return "ARRAY";
  case OP_FAIL:
    return "FAIL";
  case OP_LINE:
    return "LINE";
  case OP_PATT_STR_CMP:
    return "PATT_STR_CMP";
  case OP_PATT_STRING:
    return "PATT_STRING";
  case OP_PATT_ARRAY:
    return "PATT_ARRAY";
  case OP_PATT_SEXP:
    return "PATT_SEXP";
  case OP_PATT_BOXED:
    return "PATT_BOXED";
  case OP_PATT_UNBOXED:
    return "PATT_UNBOXED";
  case OP_PATT_CLOSURE:
    return "PATT_CLOSURE";
  case OP_READ:
    return "READ";
  case OP_WRITE:
    return "WRITE";
  case OP_LENGTH:
    return "LENGTH";
  case OP_LSTRING:
    return "LSTRING";
  case OP_BARRAY:
    return "BARRAY";
  default:
    fprintf(stderr, "Unknown opcode: 0x%02X\n", opcode);
    exit(1);
  }
}
