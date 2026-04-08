#ifndef OPS_H
#define OPS_H

#include "insn.h"

void op_add(DECL_STATE);
void op_sub(DECL_STATE);
void op_mul(DECL_STATE);
void op_div(DECL_STATE);
void op_mod(DECL_STATE);

void op_lt(DECL_STATE);
void op_le(DECL_STATE);
void op_gt(DECL_STATE);
void op_ge(DECL_STATE);
void op_eq(DECL_STATE);
void op_ne(DECL_STATE);

void op_and(DECL_STATE);
void op_or(DECL_STATE);

void op_const(DECL_STATE);
void op_drop(DECL_STATE);
void op_dup(DECL_STATE);
void op_swap(DECL_STATE);

void op_elem(DECL_STATE);
void op_sta(DECL_STATE);
void op_string(DECL_STATE);
void op_barray(DECL_STATE);
void op_sexp(DECL_STATE);
void op_tag(DECL_STATE);
void op_array(DECL_STATE);

void op_jmp(DECL_STATE);
void op_cjmp_z(DECL_STATE);
void op_cjmp_nz(DECL_STATE);
void op_fail(DECL_STATE);

void op_patt_str_cmp(DECL_STATE);
void op_patt_string(DECL_STATE);
void op_patt_array(DECL_STATE);
void op_patt_sexp(DECL_STATE);
void op_patt_boxed(DECL_STATE);
void op_patt_unboxed(DECL_STATE);
void op_patt_closure(DECL_STATE);

void op_ld_glo(DECL_STATE);
void op_st_glo(DECL_STATE);
void op_ld_loc(DECL_STATE);
void op_st_loc(DECL_STATE);
void op_ld_arg(DECL_STATE);
void op_st_arg(DECL_STATE);
void op_ld_clo(DECL_STATE);
void op_st_clo(DECL_STATE);

void op_begin(DECL_STATE);
void op_begin_closure(DECL_STATE);
void op_call(DECL_STATE);
void op_callc(DECL_STATE);
void op_end(DECL_STATE);
void op_closure(DECL_STATE);
void op_ffi_call(DECL_STATE);

void op_init(DECL_STATE);
void op_eof(DECL_STATE);
#ifdef DEBUG_PRINT
void op_line(DECL_STATE);
#endif

#endif // OPS_H
