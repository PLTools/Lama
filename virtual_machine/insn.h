/*
 * Internal instruction representation and VM state definitions.
 */

#ifndef INSN_H
#define INSN_H

#include "../runtime/runtime_common.h"
#include <stdint.h>

union insn;

// State: ip = instruction pointer, sp = stack pointer, bp = base pointer
// bp and globals are marked unused since not all handlers need them
#define DECL_STATE                                                             \
  __attribute((unused)) union insn *ip, __attribute__((unused)) aint *sp,      \
      __attribute__((unused)) aint *bp, __attribute__((unused)) aint *globals
#define STATE ip, sp, bp, globals

// Function pointer type for opcode handlers (returns void for tail calls)
typedef void (*fn)(DECL_STATE);

// Union representing a single threaded code instruction/operand
typedef union insn {
  fn func;            // Pointer to function
  int32_t num;        // Integer operand (signed)
  const char *str;    // String operand (direct pointer)
  union insn *target; // Direct jump target (pointer to insn)
  aint *global_ptr;   // Pointer to a C global variable
  void *ptr;          // Generic pointer
} insn;

#endif // INSN_H
