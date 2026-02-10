#include "decoder.h"
#include "../runtime/runtime_common.h"
#include "bytecode.h"
#include "da.h"
#include "ffi.h"
#include "opcodes.h"
#include <alloca.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

/*
 * Stack manipulation macros (stack grows downwards)
 */
#define STACK_PUSH(sp, val) (*sp-- = (val))
#define STACK_POP(sp) (*++sp)
#define STACK_PEEK(sp) (*(sp + 1))

/*
 * Symbolic stack depth tracking macros used during decoding
 * depth = -1 means unreachable code
 */
#define DEPTH_INC(d, n)                                                        \
  do {                                                                         \
    if ((d) != -1)                                                             \
      (d) += (n);                                                              \
  } while (0)
#define DEPTH_DEC(d, n)                                                        \
  do {                                                                         \
    if ((d) != -1)                                                             \
      (d) -= (n);                                                              \
  } while (0)
#define DEPTH_PUSH(d) DEPTH_INC(d, 1)
#define DEPTH_POP(d) DEPTH_DEC(d, 1)
#define DEPTH_DEAD(d) ((d) = -1)

/*
 * Code emission macros - append to code array in context
 */
#define EMIT_FUNC(ctx, f)                                                      \
  do {                                                                         \
    (ctx)->code[(ctx)->code_len++].func = (f);                                 \
  } while (0)
#define EMIT_NUM(ctx, n)                                                       \
  do {                                                                         \
    (ctx)->code[(ctx)->code_len++].num = (n);                                  \
  } while (0)
#define EMIT_STR(ctx, s)                                                       \
  do {                                                                         \
    (ctx)->code[(ctx)->code_len++].str = (s);                                  \
  } while (0)
#define EMIT_TARGET(ctx, t)                                                    \
  do {                                                                         \
    (ctx)->code[(ctx)->code_len++].target = (t);                               \
  } while (0)

typedef struct fixup_node {
  size_t insn_idx; // Index in code array that needs the jump target
  struct fixup_node *next;
} fixup_node;

// Metadata for each bytecode offset
typedef struct {
  int32_t resolved_idx; // Index in generated code array (-1 if not visited)
  int32_t stack_depth;  // Expected stack depth (-1 if not visited yet)
  fixup_node *fixups;   // Linked list of forward jumps pointing here
} meta_info;

/*
 * External runtime functions (runtime.c)
 */
extern aint Lread(void);
extern aint Lwrite(aint n);
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

extern aint Llength(void *p);
extern void *Lstring(aint *args);
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
 * Opcode handlers
 */
void op_const(DECL_STATE) {
  ip++;
  aint val = ip->num;
  VM_DEBUG("CONST: %ld\n", (long)val);
  STACK_PUSH(sp, BOX(val));
  DISPATCH();
}

#define DEFINE_BINOP(name, fn, opname)                                         \
  static void name(DECL_STATE) {                                               \
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

void symbol_table_init(symbol_table *table) { da_init(*table); }

void symbol_table_free(symbol_table *table) { da_free(*table); }

static resolved_symbol *symbol_table_find(symbol_table *table,
                                          const char *name) {
  for (size_t i = 0; i < table->len; i++) {
    if (strcmp(table->data[i].name, name) == 0) {
      return &table->data[i];
    }
  }
  return NULL;
}

// TODO: Make two separate functions for functions and globals?
// and structures?
static int symbol_table_add(symbol_table *table, const char *name,
                            insn *code_ptr, int32_t global_idx,
                            bool is_function) {

  // TODO: handle main in another way?
  if (strcmp(name, "main") != 0) {
    resolved_symbol *existing = symbol_table_find(table, name);
    // Update with the new definition
    if (existing) {
      existing->code_ptr = code_ptr;
      existing->global_idx = global_idx;
      existing->is_function = is_function;
      return 0;
    }
  }

  resolved_symbol entry = {
      .name = name,
      .code_ptr = code_ptr,
      .global_idx = global_idx,
      .is_function = is_function,
  };

  symbol_table tmp = *table;
  da_append(tmp, entry);
  *table = tmp;

  return 0;
}

/*
 * Register sysargs separately because it's not stored explicitly during
 * execution
 */
void register_sysargs(symbol_table *table) {
  symbol_table_add(table, "global_sysargs", NULL, 0, false);
}

void ext_func_stub_table_init(ext_func_stub_table *table) { da_init(*table); }

void ext_func_stub_table_free(ext_func_stub_table *table) { da_free(*table); }

static insn *ext_func_stub_table_find(ext_func_stub_table *table,
                                      const char *name) {
  for (size_t i = 0; i < table->len; i++) {
    if (strcmp(table->data[i].name, name) == 0) {
      return table->data[i].stub;
    }
  }
  return NULL;
}

static insn *ext_func_stub_table_add(ext_func_stub_table *table,
                                     const char *name, fn stub_fn,
                                     arena *code_arena) {
  insn *stub = ARENA_ALLOC(code_arena, insn, 2);

  char *persistent_name = ARENA_STRDUP(code_arena, name);

  stub[0].func = stub_fn;
  stub[1].str = persistent_name;

  ext_func_stub_entry entry = {.name = persistent_name, .stub = stub};
  ext_func_stub_table tmp = *table;
  da_append(tmp, entry);
  *table = tmp;

  VM_DEBUG("EXT_FUNC_STUB_TABLE: added '%s' -> stub=%p\n", name, (void *)stub);
  return stub;
}

int register_public_symbols(symbol_table *st, insn *code,
                            public_symbols *public_symbols,
                            int32_t *offset_to_insn, int32_t global_base) {

  for (size_t i = 0; i < public_symbols->len; i++) {
    public_symbol *pub = &public_symbols->data[i];

    insn *code_ptr = NULL;
    int32_t global_idx = 0;
    // TODO: ugly
    bool is_function = (pub->flag == PUB_FLAG_FUNCTION);

    if (is_function) {
      int32_t insn_idx = offset_to_insn[pub->code_offset];
      code_ptr = &code[insn_idx];
    } else {
      // Global variable - rebase index with module's global base
      global_idx = pub->code_offset + global_base;
    }

    symbol_table_add(st, pub->name, code_ptr, global_idx, is_function);
  }
  return 0;
}

void op_div(DECL_STATE) {
  aint y = STACK_POP(sp);
  aint x = STACK_POP(sp);
  VM_DEBUG("DIV: x=%ld, y=%ld\n", (long)UNBOX(x), (long)UNBOX(y));
  if (UNBOX(y) == 0) {
    fprintf(stderr, "Division by zero\n");
    exit(1);
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
    exit(1);
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

void op_module_end(DECL_STATE);

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
  // If a module_end bridge follows, jump to it.
  // Otherwise, return to finish execution.
  insn *next = ip + 1;
  if (next && next->func == op_module_end) {
    VM_DEBUG("END: jumping to module_end bridge at %p\n", (void *)next);
    ip = next;
    DISPATCH_JUMP();
  }
  VM_DEBUG("END: returning (no module bridge)\n");
  return;
}

/*
 * Closures
 */

/*
 * External function closure stub - called when an external closure is invoked
 * via op_callc This stub is generated for each unresolved external closure
 * reference. The function name is embedded in the next instruction.
 */
static void op_callc_ext_func_stub(DECL_STATE) {
  ip++;
  const char *func_name = ip->str;

  int32_t n_args = (int32_t)bp[1];

  VM_DEBUG("EXT_FUNC_STUB: func='%s' n_args=%d bp=%p\n", func_name, n_args,
           (void *)bp);

  aint args[256];
  for (int32_t i = 0; i < n_args; i++) {
    args[i] = bp[n_args + 1 - i];
  }

  aint result = ffi_call_c(func_name, args, n_args);
  VM_DEBUG("EXT_FUNC_STUB: func='%s' result=%ld\n", func_name, (long)result);

  // Store result in return value slot
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

void op_call_ext_func(DECL_STATE) {
  ip++;
  const char *func_name = ip->str;
  ip++;
  int32_t n_args = ip->num;

  VM_DEBUG("CALL_EXT_FUNC: func='%s' n_args=%d\n", func_name, n_args);

  aint args[256];
  aint *args_base = sp + 1;
  for (int32_t i = 0; i < n_args; i++) {
    args[i] = args_base[n_args - 1 - i];
  }
  sp += n_args;

  aint result = ffi_call_c(func_name, args, n_args);

  VM_DEBUG("CALL_EXT_FUNC: result=%ld\n", (long)UNBOX(result));
  STACK_PUSH(sp, result);
  DISPATCH();
}

void op_module_end(DECL_STATE) {
  ip++;
  insn *next_module = ip->target;

  VM_DEBUG("MODULE_END: next_module=%p\n", (void *)next_module);

  if (next_module) {
    ip = next_module;
    DISPATCH_JUMP();
  }
  // If no next module, just fall through (return)
  VM_DEBUG("MODULE_END: no next module, returning\n");
  return;
}

decode_ctx *decode_ctx_create(const bytecode *bc, int32_t global_offset,
                              arena *arena) {
  decode_ctx *ctx = ARENA_NEW(arena, decode_ctx);

  ctx->bc = bc;

  // TODO: ugly?
  // Code array will be allocated from arena in decode()
  ctx->code_cap = 0;
  ctx->code = NULL;
  ctx->code_len = 0;
  ctx->global_offset = global_offset;
  ctx->module_end_idx = (size_t)-1;

  // Allocate offset map (one entry per bytecode byte)
  ctx->offset_map.cap = bc->code_size;
  ctx->offset_map.offset_to_insn = ARENA_ALLOC(arena, int32_t, bc->code_size);

  // Initialize all to -1 (unmapped)
  for (size_t i = 0; i < bc->code_size; i++) {
    ctx->offset_map.offset_to_insn[i] = -1;
  }

  // Initialize reader
  // TODO: return struct not pass?
  reader_init(&ctx->reader, bc->code, bc->code_size);

  return ctx;
}

/*
 * Decoding
 */
// TODO: /??
static fixup_node *add_fixup(meta_info *meta, size_t target_off,
                             size_t insn_idx, memory *mem) {
  fixup_node *node = ARENA_NEW(mem->tmp, fixup_node);
  if (!node)
    return NULL;

  node->insn_idx = insn_idx;
  node->next = meta[target_off].fixups;
  meta[target_off].fixups = node;
  return node;
}

static bool validate_target_off(const bytecode *bc, size_t target_off,
                                size_t current_bc_off, const char *op_name) {
  if (target_off >= bc->code_size) {
    fprintf(
        stderr,
        "Error: %s target_off=%zu out of range (bc_off=%zu, code_size=%zu)\n",
        op_name, target_off, current_bc_off, bc->code_size);
    return false;
  }
  return true;
}

static bool emit_ld_glo(decode_ctx *ctx, symbol_table *st, int32_t idx,
                        size_t global_base) {
  const bytecode *bc = ctx->bc;

  if (IS_EXT_REF(idx)) {
    // External global: resolve by name (idx is negative string offset)
    int str_offset = EXT_REF_INDEX(idx);
    const char *glob_name = bytecode_get_string(bc, str_offset);
    resolved_symbol *sym = st ? symbol_table_find(st, glob_name) : NULL;
    VM_DEBUG("DECODE: OP_LD external global '%s' resolved to idx=%d\n",
             glob_name, sym->global_idx);
    EMIT_FUNC(ctx, op_ld_glo);
    EMIT_NUM(ctx, sym->global_idx);
  } else {
    // Local global: add module's global_base
    EMIT_FUNC(ctx, op_ld_glo);
    EMIT_NUM(ctx, global_base + idx);
  }
  return true;
}

static bool emit_st_glo(decode_ctx *ctx, symbol_table *st, int32_t idx,
                        size_t global_base) {
  const bytecode *bc = ctx->bc;

  if (IS_EXT_REF(idx)) {
    // External global: resolve by name (idx is negative string offset)
    int str_offset = EXT_REF_INDEX(idx);
    const char *glob_name = bytecode_get_string(bc, str_offset);
    resolved_symbol *sym = st ? symbol_table_find(st, glob_name) : NULL;
    VM_DEBUG("DECODE: OP_ST external global '%s' resolved to idx=%d\n",
             glob_name, sym->global_idx);
    EMIT_FUNC(ctx, op_st_glo);
    EMIT_NUM(ctx, sym->global_idx);
  } else {
    // Local global: add module's global_base
    EMIT_FUNC(ctx, op_st_glo);
    EMIT_NUM(ctx, global_base + idx);
  }
  return true;
}

/*
 * Handle jump target resolution
 */
static bool handle_jump(decode_ctx *ctx, meta_info *meta, size_t current_bc_off,
                        int32_t depth, memory *mem) {
  // TODO: unsigned ??
  int32_t target_off = reader_i32(&ctx->reader);

  if (!validate_target_off(ctx->bc, target_off, current_bc_off, "JUMP")) {
    return false;
  }

  size_t my_idx = ctx->code_len;
  EMIT_TARGET(ctx, NULL); // placeholder

  meta_info *tm = &meta[target_off];
  if (target_off < current_bc_off && tm->resolved_idx != -1) {
    // Backward jump
    ctx->code[my_idx].target = &ctx->code[tm->resolved_idx];
    if (depth != -1 && tm->stack_depth != -1 && tm->stack_depth != depth) {
      fprintf(stderr, "Error: Loop stack mismatch\n");
      return false;
    }
  } else {
    // Forward jump
    if (!add_fixup(meta, target_off, my_idx, mem)) {
      return false;
    }
    if (depth != -1) {
      if (tm->stack_depth == -1)
        tm->stack_depth = depth;
      else if (tm->stack_depth != depth) {
        fprintf(stderr, "Error: Jump stack mismatch\n");
        return false;
      }
    }
  }
  return true;
}

insn *decode(decode_ctx *ctx, symbol_table *st, ext_func_stub_table *fst,
             memory *mem) {
  const bytecode *bc = ctx->bc;
  size_t global_base = ctx->global_offset;

  size_t code_cap = bc->code_size * 16; // TODO: estimate better
  insn *code = ARENA_ALLOC(mem->code, insn, code_cap);
  ctx->code = code;
  ctx->code_cap = code_cap;

  meta_info *meta = ARENA_ALLOC(mem->tmp, meta_info, bc->code_size);

  // Initialize meta table
  for (size_t i = 0; i < bc->code_size; i++) {
    meta[i].resolved_idx = -1;
    meta[i].stack_depth = -1;
    meta[i].fixups = NULL;
  }

  int32_t depth = 0;
  // Track if we've seen the first END
  bool first_end_seen = false;

  while (!reader_eof(&ctx->reader)) {
    size_t current_bc_off = reader_pos(&ctx->reader);
    uint8_t opcode = reader_u8(&ctx->reader);

#ifdef DEBUG_PRINT
    if (current_bc_off < 10) { // Only log first 10 instructions
      VM_DEBUG("DECODE: bc_off=%zu opcode=0x%02X\n", current_bc_off, opcode);
    }
#endif

    VM_DEBUG("DECODE: visiting bc_off=%zu opcode=%d code_idx=%zu\n",
             current_bc_off, opcode, ctx->code_len);

    meta_info *m = &meta[current_bc_off];
    m->resolved_idx = (int32_t)ctx->code_len;

    // Update offset map (bytecode offset -> instruction index)
    ctx->offset_map.offset_to_insn[current_bc_off] = (int32_t)ctx->code_len;

    // Validate stack depth
    if (depth != -1) {
      if (m->stack_depth != -1 && m->stack_depth != depth) {
        fprintf(stderr,
                "Error: Stack mismatch at offset %zu (expected %d, got %d)\n",
                current_bc_off, m->stack_depth, depth);
        return NULL;
      }
      m->stack_depth = depth;
    } else {
      depth = m->stack_depth;
    }

    // Resolve forward jumps (backpatching)
    for (fixup_node *f = m->fixups; f; f = f->next) {
      VM_DEBUG("DECODE: Resolving fixup at bc_off=%zu: insn_idx=%zu -> "
               "code_idx=%zu\n",
               current_bc_off, f->insn_idx, ctx->code_len);
      ctx->code[f->insn_idx].target = &ctx->code[ctx->code_len];
    }
    // m->fixups = NULL;

    switch (opcode) {
    case OP_CONST:
      DEPTH_PUSH(depth);
      EMIT_FUNC(ctx, op_const);
      EMIT_NUM(ctx, reader_i32(&ctx->reader));
      break;

    case OP_BINOP_ADD:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_add);
      break;

    case OP_BINOP_SUB:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_sub);
      break;

    case OP_BINOP_MUL:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_mul);
      break;

    case OP_BINOP_DIV:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_div);
      break;

    case OP_BINOP_MOD:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_mod);
      break;

    case OP_BINOP_LT:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_lt);
      break;

    case OP_BINOP_LE:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_le);
      break;

    case OP_BINOP_GT:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_gt);
      break;

    case OP_BINOP_GE:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_ge);
      break;

    case OP_BINOP_EQ:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_eq);
      break;

    case OP_BINOP_NE:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_ne);
      break;

    case OP_BINOP_AND:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_and);
      break;

    case OP_BINOP_OR:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_or);
      break;

    case OP_JMP:
      EMIT_FUNC(ctx, op_jmp);
      if (!handle_jump(ctx, meta, current_bc_off, depth, mem)) {
        return NULL;
      }
      DEPTH_DEAD(depth);
      break;

    case OP_CJMP_Z:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_cjmp_z);
      if (!handle_jump(ctx, meta, current_bc_off, depth, mem)) {
        return NULL;
      }
      break;

    case OP_CJMP_NZ:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_cjmp_nz);
      if (!handle_jump(ctx, meta, current_bc_off, depth, mem)) {
        return NULL;
      }
      break;

    case OP_DROP:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_drop);
      break;

    case OP_DUP:
      DEPTH_PUSH(depth);
      EMIT_FUNC(ctx, op_dup);
      break;

    case OP_SWAP:
      EMIT_FUNC(ctx, op_swap);
      break;

    case OP_ELEM:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_elem);
      break;

    case OP_STA:
      DEPTH_DEC(depth, 2);
      EMIT_FUNC(ctx, op_sta);
      break;

    case OP_LD: {
      DEPTH_PUSH(depth);
      int32_t idx = reader_i32(&ctx->reader);
      emit_ld_glo(ctx, st, idx, global_base);
      break;
    }

    case OP_ST: {
      int32_t idx = reader_i32(&ctx->reader);
      emit_st_glo(ctx, st, idx, global_base);
      break;
    }

    case OP_LD_LOC: {
      DEPTH_PUSH(depth);
      int32_t idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_ld_loc);
      EMIT_NUM(ctx, idx);
      break;
    }

    case OP_ST_LOC: {
      int32_t idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_st_loc);
      EMIT_NUM(ctx, idx);
      break;
    }

    case OP_LD_ARG: {
      DEPTH_PUSH(depth);
      int32_t idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_ld_arg);
      EMIT_NUM(ctx, idx);
      break;
    }

    case OP_ST_ARG: {
      int32_t idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_st_arg);
      EMIT_NUM(ctx, idx);
      break;
    }

    case OP_LD_CLO: {
      DEPTH_PUSH(depth);
      int32_t idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_ld_clo);
      EMIT_NUM(ctx, idx);
      break;
    }

    case OP_ST_CLO: {
      int32_t idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_st_clo);
      EMIT_NUM(ctx, idx);
      break;
    }

    case OP_STRING: {
      DEPTH_PUSH(depth);
      int32_t str_idx = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_string);
      EMIT_STR(ctx, bytecode_get_string(bc, str_idx));
      break;
    }

    case OP_BARRAY: {
      int32_t n = reader_i32(&ctx->reader);
      DEPTH_DEC(depth, n - 1);
      EMIT_FUNC(ctx, op_barray);
      EMIT_NUM(ctx, n);
      break;
    }

    case OP_SEXP: {
      int32_t tag_idx = reader_i32(&ctx->reader);
      int32_t n_fields = reader_i32(&ctx->reader);
      DEPTH_DEC(depth, n_fields - 1);
      EMIT_FUNC(ctx, op_sexp);
      EMIT_STR(ctx, bytecode_get_string(bc, tag_idx));
      EMIT_NUM(ctx, n_fields);
      break;
    }

    case OP_TAG: {
      int32_t tag_idx = reader_i32(&ctx->reader);
      int32_t n_fields = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_tag);
      EMIT_STR(ctx, bytecode_get_string(bc, tag_idx));
      EMIT_NUM(ctx, n_fields);
      break;
    }

    case OP_ARRAY: {
      int32_t n = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_array);
      EMIT_NUM(ctx, n);
      break;
    }

    case OP_FAIL: {
      int32_t line = reader_i32(&ctx->reader);
      int32_t col = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_fail);
      EMIT_NUM(ctx, line);
      EMIT_NUM(ctx, col);
      DEPTH_DEAD(depth);
      break;
    }

    case OP_PATT_STR_CMP:
      DEPTH_POP(depth);
      EMIT_FUNC(ctx, op_patt_str_cmp);
      break;

    case OP_PATT_STRING:
      EMIT_FUNC(ctx, op_patt_string);
      break;

    case OP_PATT_ARRAY:
      EMIT_FUNC(ctx, op_patt_array);
      break;

    case OP_PATT_SEXP:
      EMIT_FUNC(ctx, op_patt_sexp);
      break;

    case OP_PATT_BOXED:
      EMIT_FUNC(ctx, op_patt_boxed);
      break;

    case OP_PATT_UNBOXED:
      EMIT_FUNC(ctx, op_patt_unboxed);
      break;

    case OP_PATT_CLOSURE:
      EMIT_FUNC(ctx, op_patt_closure);
      break;

    case OP_BEGIN: {
      int32_t n_args = reader_i32(&ctx->reader);
      int32_t n_locals = reader_i32(&ctx->reader);
      depth = 0;
      EMIT_FUNC(ctx, op_begin);
      EMIT_NUM(ctx, n_args);
      EMIT_NUM(ctx, n_locals);
      EMIT_NUM(ctx, 0);
      break;
    }

    case OP_BEGIN_CLOSURE: {
      int32_t n_args = reader_i32(&ctx->reader);
      int32_t n_locals = reader_i32(&ctx->reader);
      depth = 0;
      VM_DEBUG("DECODE: OP_BEGIN_CLOSURE n_args=%d n_locals=%d\n", n_args,
               n_locals);
      EMIT_FUNC(ctx, op_begin);
      EMIT_NUM(ctx, n_args);
      EMIT_NUM(ctx, n_locals);
      EMIT_NUM(ctx, 0);
      break;
    }

    case OP_CLOSURE: {
      int32_t target_raw = reader_i32(&ctx->reader);
      int32_t n_captured = reader_i32(&ctx->reader);

      VM_DEBUG("DECODE: OP_CLOSURE target_raw=0x%x n_captured=%d bc_off=%zu\n",
               target_raw, n_captured, current_bc_off);

      bool is_external = IS_EXT_REF(target_raw);
      const char *ext_func_name = NULL;
      resolved_symbol *ext_sym = NULL;

      if (is_external) {
        int str_offset = EXT_REF_INDEX(target_raw);
        ext_func_name = bytecode_get_string(bc, str_offset);
        VM_DEBUG("DECODE: OP_CLOSURE external name='%s' str_offset=%d\n",
                 ext_func_name, str_offset);
        ext_sym = st ? symbol_table_find(st, ext_func_name) : NULL;
      } else if (!validate_target_off(bc, (uint32_t)target_raw, current_bc_off,
                                      "CLOSURE")) {
        return NULL;
      }

      // Emit load instructions for each captured variable
      for (int32_t i = 0; i < n_captured; i++) {
        uint8_t type_byte = reader_u8(&ctx->reader);
        int32_t idx = reader_i32(&ctx->reader);

        int designation_type = type_byte & 0xF;
        switch (designation_type) {
        case 0: // Global
          DEPTH_PUSH(depth);
          emit_ld_glo(ctx, st, idx, global_base);
          break;
        case 1: // Local
          DEPTH_PUSH(depth);
          EMIT_FUNC(ctx, op_ld_loc);
          EMIT_NUM(ctx, idx);
          break;
        case 2: // Arg
          DEPTH_PUSH(depth);
          EMIT_FUNC(ctx, op_ld_arg);
          EMIT_NUM(ctx, idx);
          break;
        case 3: // Closure var
          DEPTH_PUSH(depth);
          EMIT_FUNC(ctx, op_ld_clo);
          EMIT_NUM(ctx, idx);
          break;
        default:
          fprintf(stderr, "Unknown designation type: %d\n", designation_type);
          return NULL;
        }
      }

      DEPTH_DEC(depth, n_captured - 1);

      if (is_external) {
        if (ext_sym && ext_sym->is_function && ext_sym->code_ptr) {
          // Resolved external - emit regular closure with code pointer
          EMIT_FUNC(ctx, op_closure);
          EMIT_TARGET(ctx, ext_sym->code_ptr);
          EMIT_NUM(ctx, n_captured);
        } else {
          // Check if we already have a stub for this function
          insn *stub = ext_func_stub_table_find(fst, ext_func_name);
          if (!stub) {
            stub = ext_func_stub_table_add(fst, ext_func_name,
                                           op_callc_ext_func_stub, mem->code);
          }

          EMIT_FUNC(ctx, op_closure);
          EMIT_TARGET(ctx, stub);
          EMIT_NUM(ctx, n_captured);
        }
      } else {
        uint32_t target_off = (uint32_t)target_raw;
        size_t target_slot = ctx->code_len + 1;
        EMIT_FUNC(ctx, op_closure);
        EMIT_TARGET(ctx, NULL);
        EMIT_NUM(ctx, n_captured);

        VM_DEBUG("DECODE: OP_CLOSURE internal target_off=%u target_slot=%zu\n",
                 target_off, target_slot);

        meta_info *tm = &meta[target_off];
        if (target_off < current_bc_off && tm->resolved_idx != -1) {
          ctx->code[target_slot].target = &ctx->code[tm->resolved_idx];
        } else {
          add_fixup(meta, target_off, target_slot, mem);
        }
      }
      break;
    }

    case OP_CALL: {
      int32_t target_off = reader_i32(&ctx->reader);
      int32_t n_args = reader_i32(&ctx->reader);
      DEPTH_DEC(depth, n_args - 1);

      VM_DEBUG("DECODE: OP_CALL target_off=0x%x n_args=%d "
               "current_bc_off=%zu code_idx=%zu\n",
               target_off, n_args, current_bc_off, ctx->code_len);

      if (IS_EXT_REF(target_off)) {
        int str_offset = EXT_REF_INDEX(target_off);
        const char *func_name = bytecode_get_string(bc, str_offset);

        // Try to resolve from symbol table (external module call)
        resolved_symbol *sym = st ? symbol_table_find(st, func_name) : NULL;

        if (sym && sym->is_function && sym->code_ptr) {
          VM_DEBUG("DECODE:   external module call to '%s' resolved to %p\n",
                   func_name, (void *)sym->code_ptr);

          EMIT_FUNC(ctx, op_call);
          EMIT_TARGET(ctx, sym->code_ptr);
          EMIT_NUM(ctx, n_args);
        } else {
          VM_DEBUG("DECODE:   external function call to '%s'\n", func_name);

          EMIT_FUNC(ctx, op_call_ext_func);
          EMIT_STR(ctx, func_name);
          EMIT_NUM(ctx, n_args);
        }
      } else {
        // Call between modules
        if (!validate_target_off(bc, (uint32_t)target_off, current_bc_off,
                                 "CALL")) {
          return NULL;
        }
        size_t target_slot = ctx->code_len + 1;
        EMIT_FUNC(ctx, op_call);
        EMIT_TARGET(ctx, NULL);
        EMIT_NUM(ctx, n_args);

        meta_info *tm = &meta[(uint32_t)target_off];
        VM_DEBUG("DECODE:   tm->resolved_idx=%d\n", tm->resolved_idx);
        if ((uint32_t)target_off < current_bc_off && tm->resolved_idx != -1) {
          ctx->code[target_slot].target = &ctx->code[tm->resolved_idx];
        } else {
          add_fixup(meta, (uint32_t)target_off, target_slot, mem);
        }
      }
      break;
    }

    case OP_CALLC: {
      int32_t n_args = reader_i32(&ctx->reader);
      DEPTH_DEC(depth, n_args);
      EMIT_FUNC(ctx, op_callc);
      EMIT_NUM(ctx, n_args);
      break;
    }

    case OP_END:
      EMIT_FUNC(ctx, op_end);
      DEPTH_DEAD(depth);

      // After the first END (main function's end), emit module bridge
      if (!first_end_seen) {
        first_end_seen = true;
        VM_DEBUG("DECODE: First END detected, emitting op_module_end bridge\n");
        ctx->module_end_idx = ctx->code_len;
        EMIT_FUNC(ctx, op_module_end);
        // Will be patched by linker
        EMIT_TARGET(ctx, NULL);
      }
      break;

    case OP_LINE: {
#ifdef DEBUG_PRINT
      int32_t line = reader_i32(&ctx->reader);
      EMIT_FUNC(ctx, op_line);
      EMIT_NUM(ctx, line);
#else
      reader_skip(&ctx->reader, 4);
#endif
      break;
    }

    case 0xFF:
    case 0x00:
      break;

    default:
      fprintf(stderr, "Not yet supported opcode 0x%02X at ip=0x%08zx\n", opcode,
              reader_pos(&ctx->reader) - 1);
      return NULL;
    }
  }
  return ctx->code;
}
