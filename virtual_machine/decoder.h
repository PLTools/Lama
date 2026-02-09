#ifndef DECODER_NEW_H
#define DECODER_NEW_H

#include "../runtime/runtime_common.h"
#include "arena.h"
#include "bytecode.h"
#include <stddef.h>
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
} insn;

/*
 * Sentinel value for external references (both functions and globals).
 * Address = -(index + 1), so index 0 becomes -1, index 1 becomes -2, etc.
 */
#define TO_EXT_REF(idx) (-(idx) - 1)
#define IS_EXT_REF(addr) ((addr) < 0)
#define EXT_REF_INDEX(addr) (-(addr) - 1)

/*
 * Resolved symbol structure - represents a function or global variable that has
 * been resolved during decoding.
 */
typedef struct {
  const char *name;        // Symbol name (points into bytecode's string table)
  insn *code_ptr;          // For functions: pointer to first instruction
  int32_t global_idx;      // For globals: rebased global index
  bool is_function;        // true = function, false = global variable
  const char *module_name; // Module that defined this symbol
} resolved_symbol;

/*
 * Maps symbol names to resolved symbols (functions or globals).
 * Used for resolving imports and external references during decoding.
 */
typedef struct {
  resolved_symbol *data;
  size_t len;
  size_t cap;
} symbol_table;

typedef struct {
  const char *name; // Function name (points into bytecode string table or dup)
  insn *stub;       // Pointer to 2-insn stub: [op_callc_ext_stub][name_str]
} ext_func_stub_entry;

/*
 * Cache of generated stubs for unresolved external function references.
 */
typedef struct {
  ext_func_stub_entry *data;
  size_t len;
  size_t cap;
} ext_func_stub_table;

/*
 * Mapping from bytecode offsets to instruction indices in the decoded code
 */
typedef struct {
  int32_t *offset_to_insn; // offset_to_insn[bytecode_offset] = insn_index
  size_t cap;              // Size of the mapping array (= bytecode size)
} offset_map;

typedef struct {

  const bytecode *bc;

  insn *code; // Output threaded code
  size_t code_cap;
  size_t code_len;

  byte_reader reader;
  offset_map offset_map;

  size_t global_offset; // Offset for global variables

  size_t module_end_idx; // Pointer to this module's op_module_end instruction
                         // for linking (initialized to -1 if not found)

} decode_ctx;

void symbol_table_init(symbol_table *table);
void symbol_table_free(symbol_table *table);
void register_sysargs(symbol_table *table);
void ext_func_stub_table_init(ext_func_stub_table *table);
int register_public_symbols(symbol_table *st, insn *code,
                            public_symbols *public_symbols,
                            int32_t *offset_to_insn, int32_t global_base);

decode_ctx *decode_ctx_create(const bytecode *bc, int32_t global_offset,
                                arena *arena);

insn *decode(decode_ctx *ctx, symbol_table *st, ext_func_stub_table *fst,
             memory *mem);

#endif // DECODER_NEW_H
