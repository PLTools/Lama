#ifndef READER_H
#define READER_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

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

#endif // READER_H
