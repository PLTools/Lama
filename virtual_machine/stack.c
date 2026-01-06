/*
 * Data stack implementation for the Lama VM.
 * Handles operand storage for expressions and parameters.
 * Integrated with the garbage collector for root scanning.
 */

#include "stack.h"
#include <stdio.h>
#include <stdlib.h>

extern size_t __gc_stack_top, __gc_stack_bottom;

void stack_init(stack_t *s) {
  // mandated by gc
  s->sp = s->data + STACK_SIZE - 1;
  __gc_stack_bottom = ((size_t)(s->data + STACK_SIZE));
  __gc_stack_top = (size_t)s->sp & ~0xFUL;
}

void stack_push(stack_t *s, aint val) {
  if (s->sp <= s->data) {
    fprintf(stderr, "Stack overflow\n");
    exit(1);
  }
  *s->sp-- = val;
  if (((size_t)s->sp & 0xF) == 0) {
    __gc_stack_top = (size_t)s->sp;
  }
}

aint stack_pop(stack_t *s) {
  if (s->sp >= s->data + STACK_SIZE - 1) {
    fprintf(stderr, "Cannot pop from an empty stack\n");
    exit(1);
  }
  aint val = *++s->sp;
  return val;
}

aint stack_peek(const stack_t *s) {
  if (s->sp >= s->data + STACK_SIZE - 1) {
    fprintf(stderr, "Cannot peek from an empty stack\n");
    exit(1);
  }
  return *(s->sp + 1);
}

void stack_dup(stack_t *s) {
  aint top = stack_peek(s);
  stack_push(s, top);
}

void stack_swap(stack_t *s) {
  aint y = stack_pop(s);
  aint x = stack_pop(s);
  stack_push(s, y);
  stack_push(s, x);
}
