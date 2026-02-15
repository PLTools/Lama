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
  bytecode **bc_arr; // Array of unique loaded bytecode units
  size_t bc_len;
  insn *code;          // Contiguous code array
  insn **entry_points; // Entry point for each unique unit
  size_t entry_points_len;
  size_t *exec_order; // Indices into entry_points[], execution order
  size_t exec_order_len;
  size_t total_globals;
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

  decoded **decoded_arr = decode(lr.units, lr.units_len);
  if (!decoded_arr) {
    for (size_t i = 0; i < vm->bc_len; i++) {
      bytecode_free(lr.units[i]);
    }
    free(lr.units);
    free(lr.exec_order);
    free(vm);
    return NULL;
  }

  program_link *prog = link(lr.units, decoded_arr, lr.units_len);

  vm->total_globals = prog->total_globals;
  vm->code = prog->code;
  vm->entry_points = prog->entry_points;
  vm->entry_points_len = prog->entry_points_len;
  vm->exec_order = lr.exec_order;
  vm->exec_order_len = lr.exec_order_len;

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
  free(vm->code);
  free(vm->entry_points);
  free(vm->exec_order);
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

  for (size_t i = 0; i < vm->exec_order_len; i++) {
    size_t unit_idx = vm->exec_order[i];
    insn *ip = vm->entry_points[unit_idx];

    ip->func(ip, sp, bp, globals);
  }

  return *bp;
}
