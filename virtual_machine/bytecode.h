#ifndef BYTECODE_NEW_H
#define BYTECODE_NEW_H

#include "arena.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define PUB_FLAG_FUNCTION 0
#define PUB_FLAG_GLOBAL 1

typedef struct {
  const uint8_t *data;
  size_t size;
  size_t pos;
} byte_reader;

static inline void reader_init(byte_reader *r, const uint8_t *data,
                               size_t size) {
  r->data = data;
  r->size = size;
  r->pos = 0;
}

/*
 * Read 32-bit little-endian integer and advance position
 */
static inline int32_t reader_i32(byte_reader *r) {
  if (r->pos + 4 > r->size) {
    return 0; // TODO: better error handling
  }
  const uint8_t *p = r->data + r->pos;
  r->pos += 4;
  return (int32_t)(p[0] | (p[1] << 8) | (p[2] << 16) | (p[3] << 24));
}

static inline uint8_t reader_u8(byte_reader *r) {
  if (r->pos >= r->size) {
    return 0;
  }
  return r->data[r->pos++];
}

static inline void reader_skip(byte_reader *r, size_t n) {
  r->pos += n;
  if (r->pos > r->size) {
    r->pos = r->size;
  }
}

static inline void reader_seek(byte_reader *r, size_t pos) {
  r->pos = pos;
  if (r->pos > r->size) {
    r->pos = r->size;
  }
}

static inline size_t reader_pos(const byte_reader *r) { return r->pos; }

static inline bool reader_eof(const byte_reader *r) {
  return r->pos >= r->size;
}

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
  char *module_name;
} bytecode;

bytecode *load_bytecode(const char *filename, memory *mem);

void free_bytecode(bytecode *bc);

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
