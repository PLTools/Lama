#include "arena.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MIN_BLOCK_SIZE 4096

static arena_block *block_create(size_t data_size) {
  arena_block *b = malloc(sizeof(arena_block) + data_size);
  if (!b) {
    perror("arena: block_create malloc");
    exit(1);
  }
  b->next = NULL;
  b->size = data_size;
  b->used = 0;
  return b;
}

arena *arena_create(size_t init_cap) {
  arena *a = malloc(sizeof(arena));
  if (!a) {
    perror("arena: arena_create malloc");
    exit(1);
  }

  size_t cap = init_cap < MIN_BLOCK_SIZE ? MIN_BLOCK_SIZE : init_cap;
  arena_block *b = block_create(cap);
  a->head = b;
  a->current = b;
  a->block_size = cap;
  return a;
}

void *arena_alloc(arena *arena, size_t size, size_t align) {
  assert((align & (align - 1)) == 0);

  arena_block *blk = arena->current;

  // Align within current block
  size_t mask = align - 1;
  uintptr_t base = (uintptr_t)(blk->data + blk->used);
  size_t padding = (align - (base & mask)) & mask;
  size_t needed = padding + size;

  if (blk->used + needed <= blk->size) {
    void *ptr = blk->data + blk->used + padding;
    blk->used += needed;
    return ptr;
  }

  // New block must be large enough for this request (including worst-case
  // alignment padding) and at least as big as the default block_size.
  size_t new_cap = arena->block_size;
  size_t alloc_need = size + align; // worst-case with alignment
  if (new_cap < alloc_need)
    new_cap = alloc_need;

  arena_block *nb = block_create(new_cap);
  blk->next = nb;
  arena->current = nb;

  // Align within the fresh block (used == 0, so padding is usually 0)
  base = (uintptr_t)(nb->data);
  padding = (align - (base & mask)) & mask;

  void *ptr = nb->data + padding;
  nb->used = padding + size;
  return ptr;
}

// TODO: cleanup macro?
arena_savepoint arena_save(arena *arena) {
  arena_savepoint sp = {.block = arena->current,
                          .used = arena->current->used};
  return sp;
};

void arena_restore(arena *arena, arena_savepoint sp) {
  if (!arena || !sp.block)
    return;

  arena_block *b = arena->head;

  // Walk to the savepoint block
  while (b && b != sp.block) {
    b->used = 0;
    b = b->next;
  }
  // Restore usage
  b->used = sp.used;

  arena_block *to_free = b->next;
  b->next = NULL;

  while (to_free) {
    arena_block *next = to_free->next;
    free(to_free);
    to_free = next;
  }

  arena->current = b;
}

memory *memory_create(size_t main_init_cap, size_t tmp_init_cap) {
  memory *mem = malloc(sizeof(memory));
  if (!mem) {
    perror("memory_create malloc");
    exit(1);
  }
  mem->main = arena_create(main_init_cap);
  mem->tmp = arena_create(tmp_init_cap);
  mem->code = arena_create(4096);
  return mem;
}

memory *memory_destroy(memory *mem) {
  if (!mem)
    return NULL;

  if (mem->main)
    arena_destroy(mem->main);
  if (mem->tmp)
    arena_destroy(mem->tmp);
  if (mem->code)
    arena_destroy(mem->code);
  free(mem);
  return NULL;
}

char *arena_strdup(arena *arena, const char *s) {
  if (!s)
    return NULL;

  size_t len = strlen(s) + 1;
  char *dst = (char *)arena_alloc(arena, len, 1);
  memcpy(dst, s, len);
  return dst;
}

void arena_destroy(arena *arena) {
  if (!arena)
    return;

  arena_block *b = arena->head;
  while (b) {
    arena_block *next = b->next;
    free(b);
    b = next;
  }
  free(arena);
}
