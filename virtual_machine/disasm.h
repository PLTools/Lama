#ifndef DISASM_H
#define DISASM_H

#include "bytecode.h"
#include <stdio.h>

/* Disassemble all public symbols in bc, writing output to f.
   Returns 0 on success, -1 on error. */
int disasm(const bytecode *bc, FILE *f);

/* Disassemble a single function starting at code_offset within bc->code,
   writing output to f. name may be NULL. */
int disasm_func(const bytecode *bc, size_t code_offset, const char *name,
                uint8_t flag, FILE *f);

#endif /* DISASM_H */
