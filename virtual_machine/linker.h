#ifndef LINKER_H
#define LINKER_H

#include "bytecode.h"
#include "decoder.h"
#include "insn.h"
#include <stddef.h>

typedef struct {
  insn *code;
  size_t code_len;
  size_t total_globals;
  insn **entry_points; // Entry point for each unit (pointer into code)
  size_t entry_points_len;
} program;

program *link(bytecode **bc_arr, decoded **dec_arr, size_t n);

void prog_free(program *prog);

#endif // LINKER_H
