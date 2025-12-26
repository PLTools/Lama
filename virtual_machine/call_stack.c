#include "call_stack.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void call_stack_init(call_stack_t *cs) {
  cs->top = 0;
  memset(cs->frames, 0, sizeof(cs->frames));
}

void call_stack_push(call_stack_t *cs, int return_ip, int base, int n_args,
                     int n_locals) {
  if (cs->top >= MAX_CALL_DEPTH) {
    fprintf(stderr, "Call stack overflow\n");
    exit(1);
  }

  call_frame_t *frame = &cs->frames[cs->top++];
  frame->return_ip = return_ip;
  frame->base = base;
  frame->n_args = n_args;
  frame->n_locals = n_locals;
}

call_frame_t call_stack_pop(call_stack_t *cs) {
  if (cs->top <= 0) {
    fprintf(stderr, "Cannot pop from an empty call stack\n");
    exit(1);
  }

  return cs->frames[--cs->top];
}

call_frame_t call_stack_peek(call_stack_t *cs) {
  if (cs->top <= 0) {
    fprintf(stderr, "Cannot peek from an empty call stack\n");
    exit(1);
  }

  return cs->frames[cs->top - 1];
}

call_frame_t *call_stack_current(call_stack_t *cs) {
  if (cs->top <= 0) {
    return NULL;
  }
  return &cs->frames[cs->top - 1];
}

int call_stack_is_empty(call_stack_t *cs) { return cs->top == 0; }
