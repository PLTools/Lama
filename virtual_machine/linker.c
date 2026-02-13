#include "linker.h"
#include "bytecode.h"
#include "decoder.h"
#include "ffi.h"
#include "memory.h"
#include "symbols.h"
#include <dlfcn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void register_public_symbols(symbol_table *st, const bytecode *bc,
                                    size_t code_offset, size_t global_base,
                                    const int32_t *bc_to_insn_map) {
  const public_symbols *pub = &bc->public_symbols;

  for (size_t i = 0; i < pub->len; i++) {
    const public_symbol *p = &pub->data[i];

    if (p->flag == PUB_FLAG_FUNCTION) {
      // p->code_offset is the offset in the bytecode, so we use the mapping
      int32_t insn_idx = bc_to_insn_map[p->code_offset];
      if (insn_idx == -1) {
        fprintf(stderr,
                "Error: public symbol '%s' at bytecode offset %d not decoded\n",
                p->name, p->code_offset);
        exit(EXIT_FAILURE);
      }
      int32_t code_idx = insn_idx + code_offset;
      symbol_table_add_function(st, p->name, code_idx);
    } else {
      int32_t gidx = p->code_offset + global_base;
      symbol_table_add_global(st, p->name, gidx);
    }
  }
}

/*
 * Resolve all stubs from a decoded unit.
 */
static void resolve_stubs(decoded *dec, insn *all_code, size_t code_offset,
                          symbol_table *st, ffi_call_table *ffi_stubs) {
  // Unit's code starts at all_code + code_offset
  insn *code = all_code + code_offset;
  stub *stubs_arr = dec->stubs;
  size_t stubs_len = dec->stubs_len;

  for (size_t i = 0; i < stubs_len; i++) {
    stub *s = &stubs_arr[i];
    size_t pi = s->patch_idx;

    switch (s->kind) {

    case STUB_CALL: {
      resolved_symbol *sym = symbol_table_find(st, s->name);

      // Decoder emitted: [NULL] [NULL] [n_args]
      if (sym && sym->is_function) {
        code[pi - 1].func = decoder_get_op_call();
        code[pi].target = &all_code[sym->idx];
      } else {
        code[pi - 1].func = decoder_get_op_call_ffi_stub();
        code[pi].str = s->name;
      }
      break;
    }

    case STUB_CLOSURE: {
      resolved_symbol *sym = symbol_table_find(st, s->name);

      if (sym && sym->is_function) {
        code[pi].target = &all_code[sym->idx];
      } else {
        // Not found in symbol table — create FFI stub
        insn *ffi_stub = ffi_call_table_find(ffi_stubs, s->name);
        if (!ffi_stub) {
          ffi_stub = ffi_call_table_add(ffi_stubs, s->name,
                                        decoder_get_op_callc_ffi_stub());
        }
        code[pi].target = ffi_stub;
      }
      break;
    }

    case STUB_GLOBAL_LD:
    case STUB_GLOBAL_ST: {
      resolved_symbol *sym = symbol_table_find(st, s->name);
      if (sym && !sym->is_function) {
        // Global from another unit
        if (s->kind == STUB_GLOBAL_LD) {
          code[pi - 1].func = decoder_get_op_ld_glo();
        } else {
          code[pi - 1].func = decoder_get_op_st_glo();
        }
        code[pi].num = sym->idx;
      } else {
        // C global
        void *ptr = dlsym(RTLD_DEFAULT, s->name);
        if (ptr) {
          if (s->kind == STUB_GLOBAL_LD) {
            code[pi - 1].func = decoder_get_op_ld_glo_ext();
          } else {
            code[pi - 1].func = decoder_get_op_st_glo_ext();
          }
          code[pi].global_ptr = (aint *)ptr;
        } else {
          fprintf(stderr, "Error: unresolved global '%s'\n", s->name);
          exit(EXIT_FAILURE);
        }
      }
      break;
    }
    }
  }
}

program *link(bytecode **bc_arr, decoded **dec_arr, size_t n) {
  symbol_table *st = symbol_table_create();
  ffi_call_table *ffi_stubs = ffi_call_table_create();

  size_t total_code_len = 0;
  size_t total_globals = 0;

  for (size_t i = 0; i < n; i++) {
    decoded *dec = dec_arr[i];
    bytecode *bc = bc_arr[i];
    register_public_symbols(st, bc, total_code_len, total_globals,
                            dec->bc_to_insn_map);
    total_code_len += dec->code_len;
    total_globals += bc->globals_count;
  }

  insn *all_code = ALLOC_ARRAY(insn, total_code_len);
  insn **entry_points = ALLOC_ARRAY(insn *, n);

  size_t code_offset = 0;
  for (size_t i = 0; i < n; i++) {
    decoded *dec = dec_arr[i];

    memcpy(all_code + code_offset, dec->code, dec->code_len * sizeof(insn));

    entry_points[i] = &all_code[code_offset];

    // Resolve internal jumps
    for (size_t j = 0; j < dec->relocs_len; j++) {
      size_t slot = dec->relocs[j];
      int32_t target_idx = all_code[code_offset + slot].num;
      all_code[code_offset + slot].target = &all_code[code_offset + target_idx];
    }

    // Resolve all stubs
    resolve_stubs(dec, all_code, code_offset, st, ffi_stubs);

    code_offset += dec->code_len;
  }

  program *prog = ALLOC(program);
  prog->code = all_code;
  prog->code_len = total_code_len;
  prog->total_globals = total_globals;
  prog->entry_points = entry_points;
  prog->entry_points_len = n;

  symbol_table_destroy(st);
  ffi_call_table_destroy(ffi_stubs);
  // NOTE: we don't free bytecode here since it's used for strings etc.
  for (size_t i = 0; i < n; i++) {
    decoded_free(dec_arr[i]);
  }
  free(dec_arr);

  return prog;
}

void prog_free(program *prog) {
  if (prog) {
    free(prog->code);
    free(prog->entry_points);
    free(prog);
  }
}
