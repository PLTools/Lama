#ifndef STACK_H
#define STACK_H

#include <stddef.h>
#include "../runtime/runtime_common.h"

#define STACK_SIZE 1024

typedef struct {
  aint data[STACK_SIZE];
  aint *sp;
} stack_t;

void stack_init(stack_t *s);
void stack_push(stack_t *s, aint val);
aint stack_pop(stack_t *s);
aint stack_peek(const stack_t *s);
void stack_dup(stack_t *s);
void stack_swap(stack_t *s);

#endif
