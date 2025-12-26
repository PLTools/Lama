#ifndef CALL_STACK_H
#define CALL_STACK_H

#include <stddef.h>

#define MAX_CALL_DEPTH 1024

typedef struct {
  int return_ip;
  int base;
  int n_args;
  int n_locals;
} call_frame_t;

typedef struct {
  call_frame_t frames[MAX_CALL_DEPTH];
  int top;
} call_stack_t;

void call_stack_init(call_stack_t *cs);

void call_stack_push(call_stack_t *cs, int return_ip, int base, int n_args,
                     int n_locals);

call_frame_t call_stack_pop(call_stack_t *cs);

call_frame_t call_stack_peek(call_stack_t *cs);

call_frame_t *call_stack_current(call_stack_t *cs);

int call_stack_is_empty(call_stack_t *cs);

#endif
