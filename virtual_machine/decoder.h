#ifndef DECODER_NEW_H
#define DECODER_NEW_H

#include "../runtime/runtime_common.h"
#include "bytecode.h"
#include "bytecode_util.h"
#include "insn.h"
#include <stddef.h>
#include <stdint.h>

typedef enum {
  STUB_CALL,
  STUB_CLOSURE,
  STUB_GLOBAL_LD,
  STUB_GLOBAL_ST,
} stub_kind;

/*
 * A single fixup record emitted by the decoder for the linker to resolve.
 */
typedef struct {
  size_t patch_idx; // Index into code array
  const char *name; // Symbol name to look up
  stub_kind kind;
} stub;

/*
 * Result of decoding a single unit.
 */
typedef struct {
  insn *code; // Decoded threaded code array
  size_t code_len;
  stub *stubs; // Fixups for the linker to resolve
  size_t stubs_len;
  int32_t *bc_to_insn_map;
  size_t *relocs; // Indices of insn with internal target offsets
  size_t relocs_len;
} decoded;

decoded **decode(bytecode **bc_arr, size_t n);
void decoded_free(decoded *dec);

/*
 * Used for patching
 */
fn decoder_get_op_call(void);
fn decoder_get_op_call_ffi_stub(void);
fn decoder_get_op_callc_ffi_stub(void);
fn decoder_get_op_ld_glo(void);
fn decoder_get_op_st_glo(void);
fn decoder_get_op_ld_glo_ext(void);
fn decoder_get_op_st_glo_ext(void);

#endif // DECODER_NEW_H
