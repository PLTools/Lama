#include "virt_stack.h"

#include <malloc.h>

virt_stack *vstack_create () { return malloc(sizeof(virt_stack)); }

void vstack_destruct (virt_stack *st) { free(st); }

void vstack_init (virt_stack *st) {
  st->cur          = RUNTIME_VSTACK_SIZE;
  st->buf[st->cur] = 0;
}

void vstack_push (virt_stack *st, size_t value) {
  if (st->cur == 0) { assert(0); }
  --st->cur;
  st->buf[st->cur] = value;
}

size_t vstack_pop (virt_stack *st) {
  if (st->cur == RUNTIME_VSTACK_SIZE) { assert(0); }
  size_t value = st->buf[st->cur];
  ++st->cur;
  return value;
}

void *vstack_top (virt_stack *st) { return st->buf + st->cur; }

size_t vstack_size (virt_stack *st) { return RUNTIME_VSTACK_SIZE - st->cur; }

size_t vstack_kth_from_start (virt_stack *st, size_t k) {
  assert(vstack_size(st) > k);
  return st->buf[RUNTIME_VSTACK_SIZE - 1 - k];
}
