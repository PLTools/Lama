#ifndef ARENA_H
#define ARENA_H

#include <stddef.h>
#include <stdint.h>

typedef struct arena_block {
  struct arena_block *next;
  size_t size; // Total capacity of this block's data region
  size_t used; // Bytes used in this block
  char data[];
} arena_block;

typedef struct {
  arena_block *block;
  size_t used;
} arena_savepoint;

typedef struct {
  arena_block *head;    // First block (for traversal / destroy)
  arena_block *current; // Current block we're allocating from
  size_t block_size;      // Default size for new blocks
} arena;

typedef struct {
  arena *main;
  arena *tmp;
  arena *code; // For now this is only FFI stubs
} memory;

arena *arena_create(size_t init_cap);

void *arena_alloc(arena *arena, size_t size, size_t align);

char *arena_strdup(arena *arena, const char *s);

void arena_destroy(arena *arena);

arena_savepoint arena_save(arena *arena);
void arena_restore(arena *arena, arena_savepoint sp);

memory *memory_create(size_t main_init_cap, size_t tmp_init_cap);
memory *memory_destroy(memory *mem);

#define ARENA_ALLOC(a, T, n)                                                   \
  ((T *)arena_alloc((a), sizeof(T) * (n), _Alignof(T)))

#define ARENA_NEW(a, T) ARENA_ALLOC(a, T, 1)

#define ARENA_STRDUP(a, s) arena_strdup((a), (s))

#endif // ARENA_H
