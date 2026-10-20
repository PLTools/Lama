#define _POSIX_C_SOURCE 200809L

#include "memory.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void check_ptr(void *ptr, const char *file, int line) {
  if (ptr == NULL) {
    fprintf(stderr, "Out of memory at %s:%d\n", file, line);
    exit(EXIT_FAILURE);
  }
}

void *emalloc(size_t size, const char *file, int line) {
  void *ptr = malloc(size);
  check_ptr(ptr, file, line);
  return ptr;
}

void *erealloc(void *ptr, size_t size, const char *file, int line) {
  void *new_ptr = realloc(ptr, size);
  check_ptr(new_ptr, file, line);
  return new_ptr;
}

char *estrdup(const char *s, const char *file, int line) {
  char *ptr = strdup(s);
  check_ptr(ptr, file, line);
  return ptr;
}
