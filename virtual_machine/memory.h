#ifndef MEMORY_H
#define MEMORY_H

#include <stddef.h>

void *emalloc(size_t size, const char *file, int line);
void *erealloc(void *ptr, size_t size, const char *file, int line);
char *estrdup(const char *s, const char *file, int line);

#define EMALLOC(size) emalloc((size), __FILE__, __LINE__)
#define EREALLOC(ptr, size) erealloc((ptr), (size), __FILE__, __LINE__)
#define ESTRDUP(s) estrdup((s), __FILE__, __LINE__)

#define ALLOC(type) ((type *)emalloc(sizeof(type), __FILE__, __LINE__))

#define ALLOC_ARRAY(type, count)                                               \
  ((type *)emalloc(sizeof(type) * (count), __FILE__, __LINE__))

#endif
