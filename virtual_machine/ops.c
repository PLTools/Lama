#include "ops.h"
#include "../runtime/runtime_common.h"
#include "ffi.h"
#include "insn.h"
#include <stdio.h>
#include <stdlib.h>

/*
 * External runtime functions (runtime.c)
 */
extern aint Ls__Infix_43(void *p, void *q);   // +
extern aint Ls__Infix_45(void *p, void *q);   // -
extern aint Ls__Infix_42(void *p, void *q);   // *
extern aint Ls__Infix_47(void *p, void *q);   // /
extern aint Ls__Infix_37(void *p, void *q);   // %
extern aint Ls__Infix_60(void *p, void *q);   // <
extern aint Ls__Infix_6061(void *p, void *q); // <=
extern aint Ls__Infix_62(void *p, void *q);   // >
extern aint Ls__Infix_6261(void *p, void *q); // >=
extern aint Ls__Infix_6161(void *p, void *q); // ==
extern aint Ls__Infix_3361(void *p, void *q); // !=
extern aint Ls__Infix_3838(void *p, void *q); // &&
extern aint Ls__Infix_3333(void *p, void *q); // ||

extern aint LtagHash(char *s);
extern void *Barray(aint *args, aint bn);
extern void *Bsexp(aint *args, aint bn);
extern void *Bclosure(aint *args, aint bn);
extern void *Bstring(aint *args);
extern void *Belem(void *p, aint i);
extern void *Bsta(void *x, aint i, void *v);

extern aint Btag(void *d, aint t, aint n);
extern aint Barray_patt(void *d, aint n);
extern aint Bstring_patt(void *x, void *y);
extern aint Bclosure_tag_patt(void *x);
extern aint Bboxed_patt(void *x);
extern aint Bunboxed_patt(void *x);
extern aint Barray_tag_patt(void *x);
extern aint Bstring_tag_patt(void *x);
extern aint Bsexp_tag_patt(void *x);

/*
 * Debug macros
 */
#ifdef DEBUG_PRINT
#define VM_DEBUG(fmt, ...) fprintf(stderr, fmt, ##__VA_ARGS__)
#define VM_TRACE_STACK(stack)                                                  \
  do {                                                                         \
    long sp_idx = (stack)->sp - (stack)->data;                                 \
    fprintf(stderr, "  stack [sp=%p, idx=%ld]: ", (stack)->sp, sp_idx);        \
    for (int i = 1; i <= STACK_PEEK_SIZE; i++) {                               \
      if (sp_idx + i < STACK_SIZE) {                                           \
        fprintf(stderr, "%ld ", (long)(stack)->data[sp_idx + i]);              \
      }                                                                        \
    }                                                                          \
    fprintf(stderr, "\n");                                                     \
  } while (0)
#define VM_TRACE_CALL(fmt, ...) fprintf(stderr, "[CALL] " fmt, ##__VA_ARGS__)
#define VM_ASSERT(cond, msg)                                                   \
  do {                                                                         \
    if (!(cond)) {                                                             \
      fprintf(stderr, "Assert failed: %s at %s:%d\n", msg, __FILE__,           \
              __LINE__);                                                       \
      exit(1);                                                                 \
    }                                                                          \
  } while (0)
#else
#define VM_DEBUG(fmt, ...)
#define VM_TRACE_STACK(stack)
#define VM_TRACE_CALL(fmt, ...)
#define VM_ASSERT(cond, msg)
#endif

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
#define STACK_PUSH(sp, val) (*sp-- = (val))
#define STACK_POP(sp) (*++sp)
#define STACK_PEEK(sp) (*(sp + 1))

#define DEFINE_BINOP(name, fn, opname)                                         \
  void name(DECL_STATE) {                                                      \
    aint y = STACK_POP(sp);                                                    \
    aint x = STACK_POP(sp);                                                    \
    VM_DEBUG(opname ": x=%ld, y=%ld\n", (long)UNBOX(x), (long)UNBOX(y));       \
    aint res = fn((void *)x, (void *)y);                                       \
    VM_DEBUG(opname " result=%ld\n", (long)UNBOX(res));                        \
    STACK_PUSH(sp, res);                                                       \
    DISPATCH();                                                                \
  }

DEFINE_BINOP(op_add, Ls__Infix_43, "ADD")
DEFINE_BINOP(op_sub, Ls__Infix_45, "SUB")
DEFINE_BINOP(op_mul, Ls__Infix_42, "MUL")
DEFINE_BINOP(op_lt, Ls__Infix_60, "LT")
DEFINE_BINOP(op_le, Ls__Infix_6061, "LE")
DEFINE_BINOP(op_gt, Ls__Infix_62, "GT")
DEFINE_BINOP(op_ge, Ls__Infix_6261, "GE")
DEFINE_BINOP(op_eq, Ls__Infix_6161, "EQ")
DEFINE_BINOP(op_ne, Ls__Infix_3361, "NE")
DEFINE_BINOP(op_and, Ls__Infix_3838, "AND")
DEFINE_BINOP(op_or, Ls__Infix_3333, "OR")

#undef DEFINE_BINOP

void op_const(DECL_STATE) {
  ip++;
  aint val = ip->num;
  VM_DEBUG("CONST: %ld\n", (long)val);
  STACK_PUSH(sp, BOX(val));
  DISPATCH();
}

void op_div(DECL_STATE) {
  aint y = STACK_POP(sp);
  aint x = STACK_POP(sp);
  VM_DEBUG("DIV: x=%ld, y=%ld\n", (long)UNBOX(x), (long)UNBOX(y));
  if (UNBOX(y) == 0) {
    fprintf(stderr, "Division by zero\n");
    exit(EXIT_FAILURE);
  }
  aint res = Ls__Infix_47((void *)x, (void *)y);
  VM_DEBUG("DIV result=%ld\n", (long)UNBOX(res));
  STACK_PUSH(sp, res);
  DISPATCH();
}

void op_mod(DECL_STATE) {
  aint y = STACK_POP(sp);
  aint x = STACK_POP(sp);
  VM_DEBUG("MOD: x=%ld, y=%ld\n", (long)UNBOX(x), (long)UNBOX(y));
  if (UNBOX(y) == 0) {
    fprintf(stderr, "Division by zero\n");
    exit(EXIT_FAILURE);
  }
  aint res = Ls__Infix_37((void *)x, (void *)y);
  VM_DEBUG("MOD result=%ld\n", (long)UNBOX(res));
  STACK_PUSH(sp, res);
  DISPATCH();
}

void op_drop(DECL_STATE) {
  VM_DEBUG("DROP\n");
  sp++;
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
  (void)bp;
  (void)globals;
  ip++;
  const char *str = ip->str;
  VM_DEBUG("STRING: \"%s\"\n", str);
  void *result = Bstring((void *)&str);
  STACK_PUSH(sp, (aint)result);
  DISPATCH();
}

void op_barray(DECL_STATE) {
  (void)bp;
  (void)globals;
  ip++;
  int32_t n = ip->num;
  VM_DEBUG("BARRAY: n=%d\n", n);
  aint *args_base = sp + 1;
  aint tmp_args[256];
  // TODO: optimize for passing direct pointer
  // instead of population array
  for (int32_t i = 0; i < n; i++) {
    tmp_args[i] = args_base[n - 1 - i];
  }
  sp += n;
  void *arr = Barray(tmp_args, BOX(n));
  STACK_PUSH(sp, (aint)arr);
  DISPATCH();
}

void op_sexp(DECL_STATE) {
  ip++;
  const char *tag_str = ip->str;
  ip++;
  int32_t n_fields = ip->num;

  aint tag_hash = LtagHash((char *)tag_str);
  VM_DEBUG("SEXP: tag=\"%s\" (hash=0x%lx), n_fields=%d\n", tag_str, tag_hash,
           n_fields);
  aint args[256];
  aint *args_base = sp + 1;
  // TODO: optimize for passing direct pointer
  // instead of population array
  for (int32_t i = 0; i < n_fields; i++) {
    args[i] = args_base[n_fields - 1 - i];
  }
  args[n_fields] = tag_hash;
  sp += n_fields;

  void *s = Bsexp(args, BOX(n_fields + 1));
  STACK_PUSH(sp, (aint)s);
  DISPATCH();
}

void op_tag(DECL_STATE) {
  ip++;
  const char *tag_str = ip->str;
  ip++;
  int32_t n_fields = ip->num;

  aint tag_hash = LtagHash((char *)tag_str);
  aint val = STACK_POP(sp);
  VM_DEBUG("TAG: tag='%s' hash=0x%lx n_fields=%d val=0x%lx\n", tag_str,
           (long)tag_hash, n_fields, (long)val);
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
  aint result = Barray_patt((void *)val, BOX(n));
  STACK_PUSH(sp, result);
  DISPATCH();
}

void op_fail(DECL_STATE) {
  ip++;
  int32_t line = ip->num;
  ip++;
  int32_t col = ip->num;
  VM_DEBUG("FAIL: line=%d, col=%d\n", line, col);
  fprintf(stderr, "Match failure at line %d, column %d\n", line, col);
  exit(1);
}

/*
 * Pattern matching operations
 */
void op_patt_str_cmp(DECL_STATE) {
  aint y = STACK_POP(sp);
  aint x = STACK_POP(sp);
  VM_DEBUG("PATT_STR_CMP: x=%p, y=%p\n", (void *)x, (void *)y);
  aint result = Bstring_patt((void *)x, (void *)y);
  VM_DEBUG("PATT_STR_CMP result=%ld\n", (long)UNBOX(result));
  STACK_PUSH(sp, result);
  DISPATCH();
}

void op_patt_string(DECL_STATE) {
  aint val = STACK_POP(sp);
  VM_DEBUG("PATT_STRING: val=%p\n", (void *)val);
  aint result = Bstring_tag_patt((void *)val);
  VM_DEBUG("PATT_STRING result=%ld\n", (long)UNBOX(result));
  STACK_PUSH(sp, result);
  DISPATCH();
}

void op_patt_array(DECL_STATE) {
  aint val = STACK_POP(sp);
  VM_DEBUG("PATT_ARRAY: val=%p\n", (void *)val);
  aint result = Barray_tag_patt((void *)val);
  VM_DEBUG("PATT_ARRAY result=%ld\n", (long)UNBOX(result));
  STACK_PUSH(sp, result);
  DISPATCH();
}

void op_patt_sexp(DECL_STATE) {
  aint val = STACK_POP(sp);
  VM_DEBUG("PATT_SEXP: val=%p\n", (void *)val);
  aint result = Bsexp_tag_patt((void *)val);
  VM_DEBUG("PATT_SEXP result=%ld\n", (long)UNBOX(result));
  STACK_PUSH(sp, result);
  DISPATCH();
}

void op_patt_boxed(DECL_STATE) {
  aint val = STACK_POP(sp);
  VM_DEBUG("PATT_BOXED: val=%p\n", (void *)val);
  aint result = Bboxed_patt((void *)val);
  VM_DEBUG("PATT_BOXED result=%ld\n", (long)UNBOX(result));
  STACK_PUSH(sp, result);
  DISPATCH();
}

void op_patt_unboxed(DECL_STATE) {
  aint val = STACK_POP(sp);
  VM_DEBUG("PATT_UNBOXED: val=%ld\n", (long)val);
  aint result = Bunboxed_patt((void *)val);
  VM_DEBUG("PATT_UNBOXED result=%ld\n", (long)UNBOX(result));
  STACK_PUSH(sp, result);
  DISPATCH();
}

void op_patt_closure(DECL_STATE) {
  aint val = STACK_POP(sp);
  VM_DEBUG("PATT_CLOSURE: val=%p\n", (void *)val);
  aint result = Bclosure_tag_patt((void *)val);
  VM_DEBUG("PATT_CLOSURE result=%ld\n", (long)UNBOX(result));
  STACK_PUSH(sp, result);
  DISPATCH();
}

/*
 * Load / store operations
 */
void op_ld_glo(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  VM_DEBUG("LD_GLO[%d] = %ld\n", idx, (long)globals[idx]);
  STACK_PUSH(sp, globals[idx]);
  DISPATCH();
}

void op_st_glo(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  aint val = STACK_PEEK(sp);
  VM_DEBUG("ST_GLO[%d] = %ld\n", idx, (long)val);
  globals[idx] = val;
  DISPATCH();
}

/*
 * Load / store extenral globals
 */
void op_ld_glo_ext(DECL_STATE) {
  ip++;
  aint *ptr = ip->global_ptr;
  VM_DEBUG("LD_GLO_FFI ptr=%p val=%ld\n", (void *)ptr, (long)*ptr);
  STACK_PUSH(sp, *ptr);
  DISPATCH();
}

void op_st_glo_ext(DECL_STATE) {
  ip++;
  aint *ptr = ip->global_ptr;
  aint val = STACK_PEEK(sp);
  VM_DEBUG("ST_GLO_FFI ptr=%p val=%ld\n", (void *)ptr, (long)val);
  *ptr = val;
  DISPATCH();
}

void op_ld_loc(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  VM_DEBUG("LD_LOC[%d] bp=%p bp[-idx]=%ld\n", idx, (void *)bp, (long)bp[-idx]);
  STACK_PUSH(sp, bp[-idx]);
  DISPATCH();
}

void op_st_loc(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  aint val = STACK_PEEK(sp);
  VM_DEBUG("ST_LOC[%d] = %ld bp=%p\n", idx, (long)val, (void *)bp);
  bp[-idx] = val;
  DISPATCH();
}

void op_ld_arg(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  int32_t n_args = (int32_t)bp[1];
  aint val = bp[n_args + 1 - idx];
  VM_DEBUG("LD_ARG[%d] n_args=%d bp=%p val=%ld\n", idx, n_args, (void *)bp,
           (long)val);
  STACK_PUSH(sp, val);
  DISPATCH();
}

void op_st_arg(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  int32_t n_args = (int32_t)bp[1];
  aint val = STACK_PEEK(sp);
  VM_DEBUG("ST_ARG[%d] = %ld bp=%p\n", idx, (long)val, (void *)bp);
  bp[n_args + 1 - idx] = val;
  DISPATCH();
}

void op_ld_clo(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  int32_t n_args = (int32_t)bp[1];
  aint *closure = (aint *)bp[n_args + 2];
  VM_DEBUG("LD_CLO[%d] closure=%p val=%ld\n", idx, (void *)closure,
           (long)closure[idx + 1]);
  STACK_PUSH(sp, closure[idx + 1]);
  DISPATCH();
}

void op_st_clo(DECL_STATE) {
  ip++;
  int32_t idx = ip->num;
  int32_t n_args = (int32_t)bp[1];
  aint val = STACK_PEEK(sp);
  aint *closure = (aint *)bp[n_args + 2];
  VM_DEBUG("ST_CLO[%d] = %ld closure=%p\n", idx, (long)val, (void *)closure);
  closure[idx + 1] = val;
  DISPATCH();
}

/*
 * Function call operations
 */
void op_begin(DECL_STATE) {

  ip++;
  int32_t n_args = ip->num;
  (void)n_args;
  ip++;
  int32_t n_locals = ip->num;
  ip++;

  VM_TRACE_CALL("BEGIN n_args=%d n_locals=%d bp=%p sp=%p\n", n_args, n_locals,
                (void *)bp, (void *)sp);

  for (int32_t i = 0; i < n_locals; i++) {
    STACK_PUSH(sp, 0);
  }

  DISPATCH();
}

void op_call(DECL_STATE) {
  ip++;
  insn *target = ip->target;
  ip++;
  int32_t n_args = ip->num;

  VM_TRACE_CALL("CALL target=%p n_args=%d sp=%p bp=%p\n", (void *)target,
                n_args, (void *)sp, (void *)bp);

  STACK_PUSH(sp, (aint)n_args);
  STACK_PUSH(sp, (aint)bp);

  aint *new_bp = sp + 1;
  target->func(target, sp, new_bp, globals);

  aint ret_val = *new_bp;

  sp = new_bp + n_args + 1;

  STACK_PUSH(sp, ret_val);
  DISPATCH();
}

void op_callc(DECL_STATE) {
  ip++;
  int32_t n_args = ip->num;

  aint closure_val = *(sp + 1 + n_args);
  aint *closure = (aint *)closure_val;

  aint entry = closure[0];
  insn *target = (insn *)entry;

  VM_TRACE_CALL("CALLC closure=%p target=%p n_args=%d sp=%p bp=%p\n",
                (void *)closure, (void *)target, n_args, (void *)sp,
                (void *)bp);

  STACK_PUSH(sp, (aint)n_args);
  STACK_PUSH(sp, (aint)bp);

  aint *new_bp = sp + 1;
  target->func(target, sp, new_bp, globals);

  aint ret_val = *new_bp;
  VM_DEBUG("CALLC: return value=%ld new_bp=%p\n", (long)ret_val,
           (void *)new_bp);

  sp = new_bp + n_args + 2;

  STACK_PUSH(sp, ret_val);
  DISPATCH();
}

void op_end(DECL_STATE) {
  VM_TRACE_CALL("END sp=%p\n", (void *)sp);
  aint ret_val = STACK_PEEK(sp);
  *bp = ret_val;
  return;
}

/*
 * FFI call — dispatches via pre-resolved ffi_resolved struct
 */
void op_ffi_call(DECL_STATE) {
  ip++;
  const ffi_resolved *res = (const ffi_resolved *)ip->ptr;

  int32_t n_args = (int32_t)bp[1];

  VM_DEBUG("FFI_CALL: kind=%d n_args=%d bp=%p\n", res->kind, n_args,
           (void *)bp);

  aint args[256];
  for (int32_t i = 0; i < n_args; i++) {
    args[i] = bp[n_args + 1 - i];
  }

  aint result = ffi_call_c(res, args, n_args);
  VM_DEBUG("FFI_CALL: result=%ld\n", (long)result);

  *bp = result;

  return;
}

void op_closure(DECL_STATE) {
  ip++;
  insn *target = ip->target;
  ip++;
  int32_t n_captured = ip->num;

  VM_DEBUG("CLOSURE: target=%p n_captured=%d\n", (void *)target, n_captured);

  aint tmp_args[256];
  tmp_args[0] = (aint)target;
  aint *args_base = sp + 1;
  for (int32_t i = 0; i < n_captured; i++) {
    tmp_args[i + 1] = args_base[n_captured - 1 - i];
    VM_DEBUG("CLOSURE: captured[%d]=%ld\n", i, (long)tmp_args[i + 1]);
  }
  sp += n_captured;

  void *closure = Bclosure(tmp_args, BOX(n_captured));
  VM_DEBUG("CLOSURE: created=%p\n", (void *)closure);
  STACK_PUSH(sp, (aint)closure);
  DISPATCH();
}

#ifdef DEBUG_PRINT
void op_line(DECL_STATE) {
  ip++;
  int32_t line = ip->num;
  fprintf(stderr, "LINE %d\n", line);
  (void)line;
  DISPATCH();
}
#else
void op_line(DECL_STATE) {
  ip++;
  DISPATCH();
}
#endif
