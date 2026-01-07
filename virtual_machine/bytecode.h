#ifndef BYTECODE_H
#define BYTECODE_H

#include <stdint.h>
#include <stddef.h>

typedef struct {
  const uint8_t *code;
  int code_size;
  int entry_point;
  int globals_count;
  int *public_symbols;
  int public_symbols_count;
  const char *string_table;
  void *map_base;
  size_t map_size;
} bytecode;

int read_i32(const uint8_t data[], int offset);
bytecode *load_bytecode(const char *filename);
void free_bytecode(bytecode *bc);

#endif
