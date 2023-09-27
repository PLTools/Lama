#include "gc.h"
#include "runtime_common.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef DEBUG_VERSION

// function from runtime that maps string to int value
extern int LtagHash (char *s);

extern void *Bsexp (int n, ...);
extern void *Barray (int bn, ...);
extern void *Bstring (void *);
extern void *Bclosure (int bn, void *entry, ...);

extern size_t __gc_stack_top, __gc_stack_bottom;

void test_correct_structure_sizes (void) {
  // something like induction base
  assert((array_size(0) == get_header_size(ARRAY)));
  assert((string_size(0) == get_header_size(STRING) + 1));   // +1 is because of  '\0'
  assert((sexp_size(0) == get_header_size(SEXP) + MEMBER_SIZE));
  assert((closure_size(0) == get_header_size(CLOSURE)));

  // just check correctness for some small sizes
  for (int k = 1; k < 20; ++k) {
    assert((array_size(k) == get_header_size(ARRAY) + MEMBER_SIZE * k));
    assert((string_size(k) == get_header_size(STRING) + k + 1));
    assert((sexp_size(k) == get_header_size(SEXP) + MEMBER_SIZE * (k + 1)));
    assert((closure_size(k) == get_header_size(CLOSURE) + MEMBER_SIZE * k));
  }
}

void no_gc_tests (void) { test_correct_structure_sizes(); }

// unfortunately there is no generic function pointer that can hold pointer to function with arbitrary signature
extern size_t call_runtime_function (void *virt_stack_pointer, void *function_pointer,
                                     size_t num_args, ...);

#  include "virt_stack.h"

virt_stack *init_test () {
  __init();
  virt_stack *st = vstack_create();
  vstack_init(st);
  __gc_stack_bottom = (size_t)vstack_top(st);
  return st;
}

void cleanup_test (virt_stack *st) {
  vstack_destruct(st);
  __shutdown();
}

void force_gc_cycle (virt_stack *st) {
  __gc_stack_top = (size_t)vstack_top(st) - 4;
  gc_alloc(0);
  __gc_stack_top = 0;
}

void test_simple_string_alloc (void) {
  virt_stack *st = init_test();

  for (int i = 0; i < 5; ++i) { vstack_push(st, BOX(i)); }

  vstack_push(st, call_runtime_function(vstack_top(st) - 4, Bstring, 1, "abc"));

  const int N = 10;
  int       ids[N];
  size_t    alive = objects_snapshot(ids, N);
  assert((alive == 1));

  cleanup_test(st);
}

void test_simple_array_alloc (void) {
  virt_stack *st = init_test();

  // allocate array [ BOX(1) ] and push it onto the stack
  vstack_push(st, call_runtime_function(vstack_top(st) - 4, Barray, 2, BOX(1), BOX(1)));

  const int N = 10;
  int       ids[N];
  size_t    alive = objects_snapshot(ids, N);
  assert((alive == 1));

  cleanup_test(st);
}

void test_simple_sexp_alloc (void) {
  virt_stack *st = init_test();

  // allocate sexp with one boxed field and push it onto the stack
  // calling runtime function Bsexp(BOX(2), BOX(1), LtagHash("test"))
  vstack_push(
      st, call_runtime_function(vstack_top(st) - 4, Bsexp, 3, BOX(2), BOX(1), LtagHash("test")));

  const int N = 10;
  int       ids[N];
  size_t    alive = objects_snapshot(ids, N);
  assert((alive == 1));

  cleanup_test(st);
}

void test_simple_closure_alloc (void) {
  virt_stack *st = init_test();

  // allocate closure with boxed captured value and push it onto the stack
  vstack_push(st, call_runtime_function(vstack_top(st) - 4, Bclosure, 3, BOX(1), NULL, BOX(1)));

  const int N = 10;
  int       ids[N];
  size_t    alive = objects_snapshot(ids, N);
  assert((alive == 1));

  cleanup_test(st);
}

void test_single_object_allocation_with_collection_virtual_stack (void) {
  virt_stack *st = init_test();

  vstack_push(st,
              call_runtime_function(
                  vstack_top(st) - 4, Bstring, 1, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"));

  const int N = 10;
  int       ids[N];
  size_t    alive = objects_snapshot(ids, N);
  assert((alive == 1));

  cleanup_test(st);
}

void test_garbage_is_reclaimed (void) {
  virt_stack *st = init_test();

  call_runtime_function(vstack_top(st) - 4, Bstring, 1, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");

  force_gc_cycle(st);

  const int N = 10;
  int       ids[N];
  size_t    alive = objects_snapshot(ids, N);
  assert((alive == 0));

  cleanup_test(st);
}

void test_alive_are_not_reclaimed (void) {
  virt_stack *st = init_test();

  vstack_push(st,
              call_runtime_function(
                  vstack_top(st) - 4, Bstring, 1, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"));

  force_gc_cycle(st);

  const int N = 10;
  int       ids[N];
  size_t    alive = objects_snapshot(ids, N);
  assert((alive == 1));

  cleanup_test(st);
}

void test_small_tree_compaction (void) {
  virt_stack *st = init_test();
  // this one will increase heap size
  call_runtime_function(vstack_top(st) - 4, Bstring, 1, "aaaaaaaaaaaaaaaaaaaaaa");

  vstack_push(st, call_runtime_function(vstack_top(st) - 4, Bstring, 1, "left-s"));
  vstack_push(st, call_runtime_function(vstack_top(st) - 4, Bstring, 1, "right-s"));
  vstack_push(st,
              call_runtime_function(vstack_top(st) - 4,
                                    Bsexp,
                                    4,
                                    BOX(3),
                                    vstack_kth_from_start(st, 0),
                                    vstack_kth_from_start(st, 1),
                                    LtagHash("tree")));
  force_gc_cycle(st);
  const int SZ = 10;
  int       ids[SZ];
  size_t    alive = objects_snapshot(ids, SZ);
  assert((alive == 3));

  // check that order is indeed preserved
  for (int i = 0; i < alive - 1; ++i) { assert((ids[i] < ids[i + 1])); }
  cleanup_test(st);
}

extern size_t cur_id;

size_t generate_random_obj_forest (virt_stack *st, int cnt, int seed) {
  srand(seed);
  int    cur_sz = 0;
  size_t alive  = 0;
  while (cnt) {
    --cnt;
    if (cur_sz == 0) {
      vstack_push(st, BOX(1));
      ++cur_sz;
      continue;
    }

    size_t pos[2] = {rand() % vstack_size(st), rand() % vstack_size(st)};
    size_t field[2];
    for (int t = 0; t < 2; ++t) { field[t] = vstack_kth_from_start(st, pos[t]); }
    size_t obj;

    if (rand() % 2) {
      obj = call_runtime_function(
          vstack_top(st) - 4, Bsexp, 4, BOX(3), field[0], field[1], LtagHash("test"));
    } else {
      obj = BOX(1);
    }
    // whether object is stored on stack
    if (rand() % 2 != 0) {
      vstack_push(st, obj);
      if ((obj & 1) == 0) { ++alive; }
    }
    ++cur_sz;
  }
  force_gc_cycle(st);
  return alive;
}

void run_stress_test_random_obj_forest (int seed) {
  virt_stack *st = init_test();

  const int SZ = 100000;

  size_t expectedAlive = generate_random_obj_forest(st, SZ, seed);

  int    ids[SZ];
  size_t alive = objects_snapshot(ids, SZ);
  assert(alive == expectedAlive);

  // check that order is indeed preserved
  for (int i = 0; i < alive - 1; ++i) { assert((ids[i] < ids[i + 1])); }

  cleanup_test(st);
}

#endif

#include <time.h>

int main (int argc, char **argv) {
#ifdef DEBUG_VERSION
  no_gc_tests();

  test_simple_string_alloc();
  test_simple_array_alloc();
  test_simple_sexp_alloc();
  test_simple_closure_alloc();
  test_single_object_allocation_with_collection_virtual_stack();
  test_garbage_is_reclaimed();
  test_alive_are_not_reclaimed();
  test_small_tree_compaction();

  time_t start, end;
  double diff;
  time(&start);
  // stress test
  for (int s = 0; s < 100; ++s) { run_stress_test_random_obj_forest(s); }
  time(&end);
  diff = difftime(end, start);
  printf("Stress tests took %.2lf seconds to complete\n", diff);
#endif
}
