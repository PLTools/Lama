#ifndef DEBUG_H
#define DEBUG_H

#include <stdio.h>

#ifdef DEBUG_PRINT
#define VM_DEBUG(fmt, ...) fprintf(stderr, fmt, ##__VA_ARGS__)
#else
#define VM_DEBUG(fmt, ...)
#endif

#endif // DEBUG_H
