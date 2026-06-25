#ifndef DA_H
#define DA_H

#include "memory.h"

/*
 * Dynamic array macros
 */
#define da_append(xs, x)                                                       \
  do {                                                                         \
    if ((xs).len >= (xs).cap) {                                                \
      (xs).cap = (xs).cap == 0 ? 256 : (xs).cap * 2;                           \
      (xs).data = EREALLOC((xs).data, (xs).cap * sizeof(*(xs).data));          \
      if (!(xs).data) {                                                        \
        perror("realloc");                                                     \
        exit(EXIT_FAILURE);                                                               \
      }                                                                        \
    }                                                                          \
    (xs).data[(xs).len++] = x;                                                 \
  } while (0)

#define da_init(xs)                                                            \
  do {                                                                         \
    (xs).data = NULL;                                                          \
    (xs).len = 0;                                                              \
    (xs).cap = 0;                                                              \
  } while (0)

#define da_free(xs)                                                            \
  do {                                                                         \
    free((xs).data);                                                           \
    (xs).data = NULL;                                                          \
    (xs).len = 0;                                                              \
    (xs).cap = 0;                                                              \
  } while (0)

#endif // DA_H
