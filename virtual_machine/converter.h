#ifndef CONVERTER_H
#define CONVERTER_H

#include "../runtime/runtime_common.h"
#include "bytecode.h"
#include "insn.h"
#include "reader.h"
#include <stddef.h>
#include <stdint.h>

typedef struct {
  insn *code;
  size_t code_len;
  size_t total_globals;
  insn **entry_points;
  void *ffi_data;
  size_t ffi_len;
} program;

program *decode(bytecode **bc_arr, size_t n, aint *globals);
void program_free(program *prog);

#endif // CONVERTER_H
