#ifndef DISASM_H
#define DISASM_H

#include "bytecode.h"
#include <stdio.h>

void dump_bytecode(FILE *f, const bytecode *bc);

#endif // DISASM_H
