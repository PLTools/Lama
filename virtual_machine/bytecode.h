#ifndef BYTECODE_NEW_H
#define BYTECODE_NEW_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define PUB_FLAG_FUNCTION 0
#define PUB_FLAG_GLOBAL 1

typedef struct {
  const char *name;    // Direct pointer to string
  int32_t code_offset; // Offset into bytecode section (for functions) or global
                       // index
  int32_t flag;        // PUB_FLAG_FUNCTION or PUB_FLAG_GLOBAL
} public_symbol;

typedef struct {
  public_symbol *data;
  size_t len;
} public_symbols;

typedef struct {
  const char **data;
  size_t len;
} imports;

typedef struct {
  // Memory-mapped file
  void *map_base;
  size_t map_size;

  const char *string_table;
  size_t string_table_size;

  const uint8_t *code;
  size_t code_size;

  public_symbols public_symbols;

  imports imports;

  size_t globals_count;

  const char *name;
} bytecode;

bytecode *bytecode_load(const char *filename);

void bytecode_free(bytecode *bc);

/*
 * Get string from string table by offset
 */
static inline const char *bytecode_get_string(const bytecode *bc,
                                              int32_t offset) {
  if (!bc || offset < 0 || (size_t)offset >= bc->string_table_size) {
    return NULL;
  }
  return bc->string_table + offset;
}

#endif // BYTECODE_NEW_H
