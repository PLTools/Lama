#ifndef STACK_VALIDATION_H
#define STACK_VALIDATION_H

#include <stdint.h>
#include <stdlib.h>

#ifdef DEBUG_PRINT
#define VM_DEBUG(fmt, ...) fprintf(stderr, fmt, ##__VA_ARGS__)
#else
#define VM_DEBUG(fmt, ...)
#endif

/*
 * Different states of reachability for stack validation:
 * LIVE: currently decoding sequentially, reachable from previous instruction
 * BARRIER: just emitted JMP or END, so next instruction is reachable but not
 * from previous instruction
 * DEAD: not reachable from previous instruction
 */
typedef enum { LIVE, BARRIER, DEAD } reach_state;

typedef struct {
  int32_t max_depth;    // max stack depth of the function
  size_t max_depth_pos; // position in code array where max_depth is emitted
                        // (for patching)
} func_frame;

typedef struct {
  int32_t depth;
  reach_state state;
  int32_t max_depth;
  size_t max_depth_pos;
  struct {
    func_frame *data;
    size_t len;
    size_t cap;
  } func_stack;
} stack_validation;

#define DEPTH_INC(sv, n)                                                       \
  do {                                                                         \
    if ((sv).state != DEAD) {                                                  \
      VM_DEBUG("  DEPTH: %d -> %d (+%d)\n", (sv).depth, (sv).depth + (n),      \
               (n));                                                           \
      (sv).depth += (n);                                                       \
    }                                                                          \
  } while (0)
#define DEPTH_DEC(sv, n)                                                       \
  do {                                                                         \
    if ((sv).state != DEAD) {                                                  \
      VM_DEBUG("  DEPTH: %d -> %d (-%d)\n", (sv).depth, (sv).depth - (n),      \
               (n));                                                           \
      (sv).depth -= (n);                                                       \
      assert((sv).depth >= 0 && "stack underflow");                            \
    }                                                                          \
  } while (0)
#define DEPTH_PUSH(sv) DEPTH_INC(sv, 1)
#define DEPTH_POP(sv) DEPTH_DEC(sv, 1)

#endif // STACK_VALIDATION_H
