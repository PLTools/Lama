#ifndef ARENA_H
#define ARENA_H

#include <stddef.h>
#include <stdint.h>

typedef struct arena_block {
  struct arena_block *next;
  size_t size; // Total capacity of this block's data region
  size_t used; // Bytes used in this block
  char data[];
} arena_block_t;

typedef struct {
  arena_block_t *block;
  size_t used;
} arena_savepoint_t;

typedef struct {
  arena_block_t *head;    // First block (for traversal / destroy)
  arena_block_t *current; // Current block we're allocating from
  size_t block_size;      // Default size for new blocks
} arena_t;

typedef struct {
  arena_t *main;
  arena_t *tmp;
  arena_t *code; // For now this is only FFI stubs
} memory;

arena_t *arena_create(size_t init_cap);

void *arena_alloc(arena_t *arena, size_t size, size_t align);

char *arena_strdup(arena_t *arena, const char *s);

void arena_destroy(arena_t *arena);

arena_savepoint_t arena_save(arena_t *arena);
void arena_restore(arena_t *arena, arena_savepoint_t sp);

memory *memory_create(size_t main_init_cap, size_t tmp_init_cap);
memory *memory_destroy(memory *mem);

#define ARENA_ALLOC(a, T, n)                                                   \
  ((T *)arena_alloc((a), sizeof(T) * (n), _Alignof(T)))

#define ARENA_NEW(a, T) ARENA_ALLOC(a, T, 1)

#define ARENA_STRDUP(a, s) arena_strdup((a), (s))

#endif // ARENA_H
