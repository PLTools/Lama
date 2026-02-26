#include "vm.h"
#include "../runtime/gc.h"
#include "../runtime/runtime_common.h"
#include "converter.h"
#include "loader.h"
#include "memory.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern size_t __gc_stack_top, __gc_stack_bottom;
extern void set_args(aint argc, char *argv[]);

struct virtual_machine {
  bytecode **bc_arr; // Array of unique loaded bytecode units
  size_t bc_len;
  insn *code;          // Contiguous code array
  insn **entry_points; // Entry point for each unique unit
  size_t entry_points_len;
  size_t total_globals;
  void *ffi_data; // ffi_resolved array
  size_t ffi_count;
};

virtual_machine *vm_create(const char *main_unit_path, const char **paths,
                           size_t total_paths_len) {
  __gc_init();
  search_paths search_paths = {.paths = paths, .len = total_paths_len};

  virtual_machine *vm = ALLOC(virtual_machine);

  load_result lr = load(main_unit_path, &search_paths);
  if (!lr.units) {
    free(vm);
    return NULL;
  }
  vm->bc_arr = lr.units;
  vm->bc_len = lr.units_len;

  program *prog = decode(lr.units, lr.units_len);
  if (!prog) {
    for (size_t i = 0; i < vm->bc_len; i++) {
      bytecode_free(lr.units[i]);
    }
    free(lr.units);
    free(vm);
    return NULL;
  }

  vm->total_globals = prog->total_globals;
  vm->code = prog->code;
  vm->entry_points = prog->entry_points;
  vm->ffi_data = prog->ffi_data;
  vm->ffi_count = prog->ffi_len;

  free(prog);

  return vm;
}

void vm_destroy(virtual_machine *vm) {
  if (!vm) {
    return;
  }
  for (size_t i = 0; i < vm->bc_len; i++) {
    bytecode_free(vm->bc_arr[i]);
  }
  free(vm->bc_arr);
  free(vm->ffi_data);
  free(vm->code);
  free(vm->entry_points);
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
  for (size_t i = 0; i < vm->total_globals; i++) {
    globals[i] = 0;
  }

  aint *sp = &stack_data[active_stack_size - 1];
  aint *bp = sp;

  for (size_t i = 0; i < vm->bc_len; i++) {
    insn *ip = vm->entry_points[i];

    ip->func(ip, sp, bp, globals);
  }

  return *bp;
}
