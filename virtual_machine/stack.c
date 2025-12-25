#include "stack.h"
#include <stdio.h>
#include <stdlib.h>

void stack_init(stack_t *s) {
  s->sp = s->data;
}

void stack_push(stack_t *s, int val) {
  if (s->sp >= s->data + STACK_SIZE) {
    fprintf(stderr, "Stack overflow\n");
    exit(1);
  }
  *s->sp++ = val;
}

int stack_pop(stack_t *s) {
  if (s->sp <= s->data) {
    fprintf(stderr, "Cannot pop from an empty stack");
    exit(1);
  }
  return *--s->sp;
}

int stack_peek(const stack_t *s) {
  if (s->sp <= s->data) {
    fprintf(stderr, "Cannot peek from an empty stack");
    exit(1);
  }
  return *(s->sp - 1);
}

void stack_dup(stack_t *s) {
  int top = stack_peek(s);
  stack_push(s, top);
}

void stack_swap(stack_t *s) {
  int y = stack_pop(s);
  int x = stack_pop(s);
  stack_push(s, y);
  stack_push(s, x);
}
