#include "ops.h"
#include "../runtime/runtime_common.h"
#include "debug.h"
#include "ffi.h"
#include "insn.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern size_t __gc_stack_top;

/*
 * External runtime functions (runtime.c)
 */
extern aint Ls__Infix_43(aint p, aint q);   // +
extern aint Ls__Infix_45(aint p, aint q);   // -
extern aint Ls__Infix_42(aint p, aint q);   // *
extern aint Ls__Infix_47(aint p, aint q);   // /
extern aint Ls__Infix_37(aint p, aint q);   // %
extern aint Ls__Infix_60(aint p, aint q);   // <
extern aint Ls__Infix_6061(aint p, aint q); // <=
extern aint Ls__Infix_62(aint p, aint q);   // >
extern aint Ls__Infix_6261(aint p, aint q); // >=
extern aint Ls__Infix_6161(aint p, aint q); // ==
extern aint Ls__Infix_3361(aint p, aint q); // !=
extern aint Ls__Infix_3838(aint p, aint q); // &&
extern aint Ls__Infix_3333(aint p, aint q); // ||

extern void *Barray(aint *args, aint bn);
extern void *Bsexp(aint *args, aint bn);
extern void *Bclosure(aint *args, aint bn);
extern void *Bstring(aint *args);
extern void *Belem(void *p, aint i);
extern void *Bsta(void *x, aint i, void *v);

extern aint Btag(void *d, aint t, aint n);
extern aint Barray_patt(aint d, aint n);
extern aint Bstring_patt(aint x, aint y);
extern aint Bclosure_tag_patt(aint x);
extern aint Bboxed_patt(aint x);
extern aint Bunboxed_patt(aint x);
extern aint Barray_tag_patt(aint x);
extern aint Bstring_tag_patt(aint x);
extern aint Bsexp_tag_patt(aint x);
extern void Bmatch_failure(aint v, const char *fname, aint line, aint col);

#define DISPATCH()                                                             \
  do {                                                                         \
    ip++;                                                                      \
    __attribute__((musttail)) return ip->func(STATE);                          \
  } while (0)

#define DISPATCH_JUMP()                                                        \
  do {                                                                         \
    __attribute__((musttail)) return ip->func(STATE);                          \
  } while (0)

/*
 * Stack manipulation macros (stack grows downwards)
 */
#define STACK_PUSH(sp, val) (*--(sp) = (val))
#define STACK_POP(sp) (*sp++)
#define STACK_PEEK(sp) (*sp)
#define STACK_REVERSE(base, n)                                                 \
  do {                                                                         \
    for (int32_t _i = 0; _i < (n) / 2; _i++) {                                 \
      aint _tmp = (base)[_i];                                                  \
      (base)[_i] = (base)[(n) - 1 - _i];                                       \
      (base)[(n) - 1 - _i] = _tmp;                                             \
    }                                                                          \
  } while (0)

#define FRAME_SAVED_BP (-1)
#define FRAME_SAVED_IP (-2)
#define FRAME_SAVED_SP (-3)
#define FRAME_LOCALS (-4)

#define PUSH_FRAME(n_args_val, saved_bp, saved_ip, caller_sp_val)              \
  do {                                                                         \
    STACK_PUSH(sp, n_args_val);                                                \
    aint *new_bp = sp;                                                         \
    STACK_PUSH(sp, (aint)(saved_bp));                                          \
    STACK_PUSH(sp, (aint)(saved_ip));                                          \
    STACK_PUSH(sp, (aint)(caller_sp_val));                                     \
    bp = new_bp;                                                               \
  } while (0)

#define DEFINE_BINARY_OP(name, fn, opname)                                     \
  void name(DECL_STATE) {                                                      \
    aint y = STACK_POP(sp);                                                    \
    aint x = STACK_POP(sp);                                                    \
    VM_DEBUG(opname ": x=0x%lx, y=0x%lx\n", (unsigned long)x,                  \
             (unsigned long)y);                                                \
    aint res = fn(x, y);                                                       \
    VM_DEBUG(opname " result=%ld\n", (long)UNBOX(res));                        \
    STACK_PUSH(sp, res);                                                       \
    DISPATCH();                                                                \
  }

#define DEFINE_UNARY_OP(name, fn, opname)                                      \
  void name(DECL_STATE) {                                                      \
    aint val = STACK_POP(sp);                                                  \
    VM_DEBUG(opname ": val=0x%lx\n", (unsigned long)val);                      \
    aint result = fn(val);                                                     \
    VM_DEBUG(opname " result=%ld\n", (long)UNBOX(result));                     \
    STACK_PUSH(sp, result);                                                    \
    DISPATCH();                                                                \
  }

DEFINE_BINARY_OP(op_add, Ls__Infix_43, "ADD")
DEFINE_BINARY_OP(op_sub, Ls__Infix_45, "SUB")
DEFINE_BINARY_OP(op_mul, Ls__Infix_42, "MUL")
DEFINE_BINARY_OP(op_div, Ls__Infix_47, "DIV")
DEFINE_BINARY_OP(op_mod, Ls__Infix_37, "MOD")
DEFINE_BINARY_OP(op_lt, Ls__Infix_60, "LT")
DEFINE_BINARY_OP(op_le, Ls__Infix_6061, "LE")
DEFINE_BINARY_OP(op_gt, Ls__Infix_62, "GT")
DEFINE_BINARY_OP(op_ge, Ls__Infix_6261, "GE")
DEFINE_BINARY_OP(op_eq, Ls__Infix_6161, "EQ")
DEFINE_BINARY_OP(op_ne, Ls__Infix_3361, "NE")
DEFINE_BINARY_OP(op_and, Ls__Infix_3838, "AND")
DEFINE_BINARY_OP(op_or, Ls__Infix_3333, "OR")

/*
 * Pattern matching operations
 */
DEFINE_BINARY_OP(op_patt_str_cmp, Bstring_patt, "PATT_STR_CMP")
DEFINE_UNARY_OP(op_patt_string, Bstring_tag_patt, "PATT_STRING")
DEFINE_UNARY_OP(op_patt_array, Barray_tag_patt, "PATT_ARRAY")
DEFINE_UNARY_OP(op_patt_sexp, Bsexp_tag_patt, "PATT_SEXP")
DEFINE_UNARY_OP(op_patt_boxed, Bboxed_patt, "PATT_BOXED")
DEFINE_UNARY_OP(op_patt_unboxed, Bunboxed_patt, "PATT_UNBOXED")
DEFINE_UNARY_OP(op_patt_closure, Bclosure_tag_patt, "PATT_CLOSURE")

#undef DEFINE_BINARY_OP
#undef DEFINE_UNARY_OP

void op_const(DECL_STATE) {
  ip++;
  aint val = ip->num;
  VM_DEBUG("CONST: %ld\n", (long)val);
  STACK_PUSH(sp, BOX(val));
  DISPATCH();
}

void op_drop(DECL_STATE) {
  VM_DEBUG("DROP\n");
  (void)STACK_POP(sp);
  DISPATCH();
}

void op_dup(DECL_STATE) {
  aint val = STACK_PEEK(sp);
  VM_DEBUG("DUP: %ld\n", (long)UNBOX(val));
  STACK_PUSH(sp, val);
  DISPATCH();
}

void op_swap(DECL_STATE) {
  aint a = STACK_POP(sp);
  aint b = STACK_POP(sp);
  VM_DEBUG("SWAP: a=%ld, b=%ld\n", (long)UNBOX(a), (long)UNBOX(b));
  STACK_PUSH(sp, a);
  STACK_PUSH(sp, b);
  DISPATCH();
}

void op_elem(DECL_STATE) {
  aint idx = STACK_POP(sp);
  aint arr = STACK_POP(sp);
  VM_DEBUG("ELEM: arr=%p, idx=%ld\n", (void *)arr, (long)UNBOX(idx));
  void *elem = Belem((void *)arr, idx);
  STACK_PUSH(sp, (aint)elem);
  DISPATCH();
}

void op_sta(DECL_STATE) {
  aint val = STACK_POP(sp);
  aint idx = STACK_POP(sp);
  aint arr = STACK_POP(sp);
  VM_DEBUG("STA: arr=%p, idx=%ld, val=%ld\n", (void *)arr, (long)UNBOX(idx),
           (long)UNBOX(val));
  Bsta((void *)arr, idx, (void *)val);
  STACK_PUSH(sp, val);
  DISPATCH();
}

/*
 * Jumps
 */
void op_jmp(DECL_STATE) {
  ip++;
  VM_DEBUG("JMP: target=%p\n", (void *)ip->target);
  ip = ip->target;
  DISPATCH_JUMP();
}

void op_cjmp_z(DECL_STATE) {
  ip++;
  insn *target = ip->target;
  ip++;
  aint val = STACK_POP(sp);
  VM_DEBUG("CJMP_Z: val=%ld, target=%p, will_jump=%d\n", (long)UNBOX(val),
           (void *)target, UNBOX(val) == 0);
  if (UNBOX(val) == 0) {
    ip = target;
  }
  DISPATCH_JUMP();
}

void op_cjmp_nz(DECL_STATE) {
  ip++;
  insn *target = ip->target;
  ip++;
  aint val = STACK_POP(sp);
  VM_DEBUG("CJMP_NZ: val=%ld, target=%p, will_jump=%d\n", (long)UNBOX(val),
           (void *)target, UNBOX(val) != 0);
  if (UNBOX(val) != 0) {
    ip = target;
  }
  DISPATCH_JUMP();
}

/*
 * String, data etc.
 */
void op_string(DECL_STATE) {
  ip++;
  const char *str = ip->str;
  void *result = Bstring((void *)&str);
  VM_DEBUG("STRING literal: \"%s\" -> %p\n", str, result);
  STACK_PUSH(sp, (aint)result);
  DISPATCH();
}

void op_barray(DECL_STATE) {
  ip++;
  int32_t n = ip->num;
  VM_DEBUG("BARRAY: n=%d\n", n);
  aint *args = sp;
  STACK_REVERSE(args, n);
  sp += n;
  void *arr = Barray(args, BOX(n));
  STACK_PUSH(sp, (aint)arr);
  DISPATCH();
}

void op_sexp(DECL_STATE) {
  ip++;
  aint tag_hash = ip->anum;
  ip++;
  int32_t n_fields = ip->num;

  VM_DEBUG("SEXP: tag_hash=0x%lx, n_fields=%d\n", tag_hash, n_fields);
  // Use the free slot below the current top for tag_hash.
  aint *args = sp - 1;
  args[0] = tag_hash;
  STACK_REVERSE(args, n_fields + 1);
  sp += n_fields;

  void *s = Bsexp(args, BOX(n_fields + 1));
  STACK_PUSH(sp, (aint)s);
  DISPATCH();
}

void op_tag(DECL_STATE) {
  ip++;
  aint tag_hash = ip->anum;
  ip++;
  int32_t n_fields = ip->num;

  aint val = STACK_POP(sp);
  VM_DEBUG("TAG: tag_hash=0x%lx n_fields=%d val=0x%lx\n",
           (unsigned long)tag_hash, n_fields, (long)val);
  aint result = Btag((void *)val, tag_hash, BOX(n_fields));
  VM_DEBUG("TAG: result=%ld\n", (long)UNBOX(result));
  STACK_PUSH(sp, result);
  DISPATCH();
}

void op_array(DECL_STATE) {
  ip++;
  int32_t n = ip->num;
  aint val = STACK_POP(sp);
  VM_DEBUG("ARRAY: n=%d, val=%p\n", n, (void *)val);
  aint result = Barray_patt(val, BOX(n));
  STACK_PUSH(sp, result);
  DISPATCH();
}

void op_fail(DECL_STATE) {
  (void)bp;
  ip++;
  int32_t line = ip->num;
  ip++;
  int32_t col = ip->num;
  ip++;
  bool drop_value = ip->num;
  ip++;
  const char *module_name = ip->str;

  aint val = drop_value ? STACK_POP(sp) : STACK_PEEK(sp);
  Bmatch_failure(val, module_name, BOX(line), BOX(col));
}

/*
 * Load / store global variables (by pointer)
 */
void op_ld_glo(DECL_STATE) {
  ip++;
  aint *ptr = ip->global_ptr;
  VM_DEBUG("LD_GLO ptr=%p val=%ld\n", (void *)ptr, (long)*ptr);
  STACK_PUSH(sp, *ptr);
  DISPATCH();
}

void op_st_glo(DECL_STATE) {
  ip++;
  aint *ptr = ip->global_ptr;
  aint val = STACK_PEEK(sp);
  VM_DEBUG("ST_GLO ptr=%p val=%ld\n", (void *)ptr, (long)val);
  *ptr = val;
  DISPATCH();
}

void op_ld_loc(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  VM_DEBUG("LD_LOC[%d] bp=%p val=%ld\n", idx, (void *)bp,
           (long)bp[FRAME_LOCALS - idx]);
  STACK_PUSH(sp, bp[FRAME_LOCALS - idx]);
  DISPATCH();
}

void op_st_loc(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  aint val = STACK_PEEK(sp);
  VM_DEBUG("ST_LOC[%d] = %ld bp=%p\n", idx, (long)val, (void *)bp);
  bp[FRAME_LOCALS - idx] = val;
  DISPATCH();
}

void op_ld_arg(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  int32_t n_args = (int32_t)bp[0];
  aint val = bp[n_args - idx];
  VM_DEBUG("LD_ARG[%d] n_args=%d bp=%p val=%ld\n", idx, n_args, (void *)bp,
           (long)val);
  STACK_PUSH(sp, val);
  DISPATCH();
}

void op_st_arg(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  int32_t n_args = (int32_t)bp[0];
  aint val = STACK_PEEK(sp);
  VM_DEBUG("ST_ARG[%d] = %ld bp=%p\n", idx, (long)val, (void *)bp);
  bp[n_args - idx] = val;
  DISPATCH();
}

void op_ld_clo(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  int32_t n_args = (int32_t)bp[0];
  aint *closure = (aint *)bp[n_args + 1];
  VM_DEBUG("LD_CLO[%d] closure=%p val=%ld\n", idx, (void *)closure,
           (long)closure[idx + 1]);
  STACK_PUSH(sp, closure[idx + 1]);
  DISPATCH();
}

void op_st_clo(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  int32_t n_args = (int32_t)bp[0];
  aint val = STACK_PEEK(sp);
  aint *closure = (aint *)bp[n_args + 1];
  VM_DEBUG("ST_CLO[%d] = %ld closure=%p\n", idx, (long)val, (void *)closure);
  closure[idx + 1] = val;
  DISPATCH();
}

/*
 * Function call operations
 */
#define DEFINE_BEGIN(name)                                                     \
  void name(DECL_STATE) {                                                      \
    ip++;                                                                      \
    int32_t n_args = ip->num;                                                  \
    (void)n_args;                                                              \
    ip++;                                                                      \
    int32_t n_locals = ip->num;                                                \
    ip++;                                                                      \
    int32_t max_depth = ip->num;                                               \
                                                                               \
    VM_DEBUG("BEGIN n_args=%d n_locals=%d max_depth=%d bp=%p sp=%p\n", n_args, \
             n_locals, max_depth, (void *)bp, (void *)sp);                     \
                                                                               \
    for (int32_t i = 0; i < n_locals; i++) {                                   \
      STACK_PUSH(sp, BOX(0));                                                  \
    }                                                                          \
                                                                               \
    aint *offset = sp - max_depth;                                             \
    memset(offset, 0, max_depth * sizeof(aint));                               \
    __gc_stack_top = (size_t)(offset - 1);                                     \
                                                                               \
    DISPATCH();                                                                \
  }

/*
 * The distinction is made at the opcode level to allow for easier validation
 * during decoding (and maybe for future things).
 */
DEFINE_BEGIN(op_begin)
DEFINE_BEGIN(op_begin_closure)
#undef DEFINE_BEGIN

void op_call(DECL_STATE) {
  ip++;
  insn *target = ip->target;
  ip++;
  int32_t n_args = ip->num;
  ip++; // sort of a return address

  VM_DEBUG("CALL target=%p n_args=%d sp=%p bp=%p\n", (void *)target, n_args,
           (void *)sp, (void *)bp);

  aint *caller_sp = sp + n_args;
  PUSH_FRAME(n_args, bp, ip, caller_sp);
  ip = target;
  DISPATCH_JUMP();
}

void op_callc(DECL_STATE) {
  ip++;
  int32_t n_args = ip->num;
  ip++; // sort of a return address

  aint closure_val = *(sp + n_args);
  aint *closure = (aint *)closure_val;
  aint entry = closure[0];
  insn *target = (insn *)entry;

  VM_DEBUG("CALLC closure=%p target=%p n_args=%d sp=%p bp=%p\n",
           (void *)closure, (void *)target, n_args, (void *)sp, (void *)bp);

  aint *caller_sp = sp + n_args + 1;
  PUSH_FRAME(n_args, bp, ip, caller_sp);
  ip = target;
  DISPATCH_JUMP();
}

void op_end(DECL_STATE) {
  (void)sp;
  aint ret_val = STACK_POP(sp);

  VM_DEBUG("END ret_val=%ld bp=%p sp=%p\n", (long)ret_val, (void *)bp,
           (void *)sp);

  // Restore caller's state from frame
  sp = (aint *)bp[FRAME_SAVED_SP];
  ip = (insn *)bp[FRAME_SAVED_IP];
  bp = (aint *)bp[FRAME_SAVED_BP];

  STACK_PUSH(sp, ret_val);
  DISPATCH_JUMP();
}

/*
 * FFI call — dispatches via pre-resolved ffi_resolved struct
 */
void op_ffi_call(DECL_STATE) {
  (void)sp;
  ip++;
  const ffi_resolved *res = (const ffi_resolved *)ip->ptr;

  int32_t n_args = (int32_t)bp[0];

  VM_DEBUG("FFI_CALL: kind=%d n_args=%d bp=%p\n", res->kind, n_args,
           (void *)bp);

  // args at bp[1..n_args]
  STACK_REVERSE(bp + 1, n_args);
  aint result = ffi_call_c(res, bp + 1, n_args);
  VM_DEBUG("FFI_CALL: result=%ld\n", (long)result);

  // Same as op_end
  sp = (aint *)bp[FRAME_SAVED_SP];
  ip = (insn *)bp[FRAME_SAVED_IP];
  bp = (aint *)bp[FRAME_SAVED_BP];

  STACK_PUSH(sp, result);
  DISPATCH_JUMP();
}

void op_closure(DECL_STATE) {
  ip++;
  insn *target = ip->target;
  ip++;
  int32_t n_captured = ip->num;

  VM_DEBUG("CLOSURE: target=%p n_captured=%d\n", (void *)target, n_captured);

  aint *args = sp - 1;
  args[0] = (aint)target;
  STACK_REVERSE(args + 1, n_captured);
  sp += n_captured;

  void *closure = Bclosure(args, BOX(n_captured));
  VM_DEBUG("CLOSURE: created=%p\n", (void *)closure);
  STACK_PUSH(sp, (aint)closure);
  DISPATCH();
}

void op_eof(DECL_STATE) {
  (void)ip;
  (void)bp;
  (void)sp;
  return;
}

void op_line(DECL_STATE) {
  ip++;
  int32_t line = ip->num;
  fprintf(stderr, "LINE %d\n", line);
  (void)line;
  DISPATCH();
}
