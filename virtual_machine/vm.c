#include "vm.h"
#include "../runtime/gc.h"
#include "../runtime/runtime_common.h"
#include "decoder.h"
#include "linker.h"
#include "loader.h"
#include "memory.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern size_t __gc_stack_top, __gc_stack_bottom;
extern void set_args(aint argc, char *argv[]);

struct virtual_machine {
  bytecode **bc_arr; // Array of loaded bytecode units
  size_t bc_len;
  insn *entry_point;    // Entry point instruction
  size_t total_globals; // Number of globals
};

virtual_machine *vm_create(const char *main_unit_path, const char **paths,
                           size_t total_paths_len) {
  __gc_init();
  search_paths search_paths = {.paths = paths, .len = total_paths_len};

  virtual_machine *vm = ALLOC(virtual_machine);

  bytecode **bc_arr = load(main_unit_path, &search_paths, &vm->bc_len);
  if (!bc_arr) {
    free(vm);
    return NULL;
  }
  vm->bc_arr = bc_arr;
  decoded **decoded_arr = decode(bc_arr, vm->bc_len);
  if (!decoded_arr) {
    for (size_t i = 0; i < vm->bc_len; i++) {
      bytecode_free(bc_arr[i]);
    }
    free(bc_arr);
    free(vm);
    return NULL;
  }

  program *prog = link(bc_arr, decoded_arr, vm->bc_len);

  vm->total_globals = prog->total_globals;
  vm->entry_point = prog->code;

  free(prog);

  return vm;
}

void vm_destroy(virtual_machine *vm) {
  for (size_t i = 0; i < vm->bc_len; i++) {
    bytecode_free(vm->bc_arr[i]);
  }
  free(vm->bc_arr);
  free(vm->entry_point);
  free(vm);
}

void vm_set_args(virtual_machine *vm, int argc, char *argv[]) {
  set_args(argc, argv);
}

aint vm_run(virtual_machine *vm) {

  // TODO: this is all very ugly
  size_t active_stack_size = 32768;
  __attribute__((aligned(16))) aint stack_data[65536];

  memset(stack_data, 0, active_stack_size * sizeof(aint));

  __gc_stack_bottom = (size_t)(stack_data + active_stack_size);
  __gc_stack_top = (size_t)(stack_data - 16);

  // Globals at the top of stack
  aint *globals = stack_data;

  extern void *global_sysargs;
  globals[0] = (aint)global_sysargs;

  aint *sp = &stack_data[active_stack_size - 1];
  aint *bp = sp;

  insn *ip = vm->entry_point;

  ip->func(ip, sp, bp, globals);

  return *bp;
}
