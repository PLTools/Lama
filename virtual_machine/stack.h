#ifndef STACK_H
#define STACK_H

#include <stddef.h>

#define STACK_SIZE 1024

typedef struct {
  int data[STACK_SIZE];
  int *sp;
} stack_t;

void stack_init(stack_t *s);
void stack_push(stack_t *s, int val);
int stack_pop(stack_t *s);
int stack_peek(const stack_t *s);
void stack_dup(stack_t *s);
void stack_swap(stack_t *s);

#endif
