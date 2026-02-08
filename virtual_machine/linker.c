#include "linker.h"
#include "arena.h"
#include "decoder.h"
#include "module_manager.h"
#include <libgen.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// opcode handler used to identify module end
extern void op_module_end(DECL_STATE);

insn *decode_and_link(module_manager *mm, memory *mem) {
  arena_savepoint_t sp = arena_save(mem->tmp);
  // TODO: shoudl be redone without dynamic array
  symbol_table *st = ARENA_NEW(mem->tmp, symbol_table);
  symbol_table_init(st);

  register_sysargs(st);

  ext_func_stub_table *fst = ARENA_NEW(mem->tmp, ext_func_stub_table);
  ext_func_stub_table_init(fst);

  insn *hd_insn = NULL;
  insn *tl_insn = NULL;
  for (size_t i = 0; i < mm->modules.len; i++) {
    loaded_module *mod = mm->modules.data[i];

    decode_ctx_t *ctx = decode_ctx_create(mod->bc, mod->global_base, mem->tmp);

    insn *mod_code = decode(ctx, st, fst, mem);

    // Register public symbols from this module
    register_public_symbols(st, mod_code, mod->bc,
                            ctx->offset_map.offset_to_insn, mod->global_base);

    if (hd_insn == NULL) {
      hd_insn = &mod_code[0];
    }

    // Link previous module's end to this module's start
    if (tl_insn != NULL) {
      // prev_module_end is pointing to op_module_end instruction
      // The next slot contains the target pointer (NULL placeholder)
      tl_insn[1].target = &mod_code[0];
    }

    // Remember this module's op_module_end instruction for next iteration
    // It was emitted after the first END, position stored in
    // ctx->module_end_idx
    size_t module_end_idx = ctx->module_end_idx;

    // Last module's op_module_end target remains NULL (program ends)
    if (module_end_idx == (size_t)-1) {
      tl_insn = NULL;
    } else {
      tl_insn = &mod_code[module_end_idx];
    }
  }

  arena_restore(mem->tmp, sp);

  return hd_insn;
}
