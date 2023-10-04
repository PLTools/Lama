//
// Created by egor on 24.04.23.
//

#ifndef LAMA_RUNTIME_VIRT_STACK_H
#define LAMA_RUNTIME_VIRT_STACK_H
#define RUNTIME_VSTACK_SIZE 100000

#include <assert.h>
#include <stddef.h>

struct {
  size_t buf[RUNTIME_VSTACK_SIZE + 1];
  size_t cur;
} typedef virt_stack;

virt_stack *vstack_create ();

void vstack_destruct (virt_stack *st);

void vstack_init (virt_stack *st);

void vstack_push (virt_stack *st, size_t value);

size_t vstack_pop (virt_stack *st);

void *vstack_top (virt_stack *st);

size_t vstack_size (virt_stack *st);

size_t vstack_kth_from_start (virt_stack *st, size_t k);

#endif   //LAMA_RUNTIME_VIRT_STACK_H
