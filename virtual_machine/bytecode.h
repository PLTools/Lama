#ifndef BYTECODE_H
#define BYTECODE_H

#include "reader.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define PUB_FLAG_FUNCTION 0
#define PUB_FLAG_GLOBAL 1

typedef struct {
  const char *name;    // Direct pointer to string
  int32_t code_offset; // Offset into bytecode section (for functions) or global
                       // index
  uint8_t flag;        // PUB_FLAG_FUNCTION or PUB_FLAG_GLOBAL
} public_symbol;

typedef struct {
  // Memory-mapped file
  const uint8_t *map_base;
  size_t map_size;

  int32_t version;

  const char *string_table;
  size_t string_table_size;

  const uint8_t *code;
  size_t code_size;

  const uint8_t *pubs;
  size_t pubs_len;

  const uint8_t *imports;
  size_t imports_len;

  size_t globals_count;

  const char *name;
} bytecode;

bytecode *bytecode_load_fd(int fd);
bytecode *bytecode_load(const char *filename);

void bytecode_free(bytecode *bc);

typedef struct {
  byte_reader reader;
  const char *string_table;
  size_t string_table_size;
  size_t len;
  size_t curr;
} bytecode_iterator;

size_t bytecode_count_globals(bytecode **bc_arr, size_t n);

void bytecode_pubs_init(bytecode_iterator *iter, const bytecode *bc);
bool bytecode_pubs_next(bytecode_iterator *iter, public_symbol *out);

void bytecode_imports_init(bytecode_iterator *iter, const bytecode *bc);
bool bytecode_imports_next(bytecode_iterator *iter, const char **out_name);
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

#endif // BYTECODE_H
