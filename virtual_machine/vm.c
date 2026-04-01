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
#include <sys/mman.h>

extern size_t __gc_stack_top, __gc_stack_bottom;
extern void set_args(aint argc, char *argv[]);

struct virtual_machine {
  bytecode **bc_arr; // Array of unique loaded bytecode units
  size_t bc_len;
  insn *code;          // Contiguous code array
  insn **entry_points; // Entry point for each unique unit
  size_t entry_points_len;
  size_t total_globals;
  aint *globals;  // Globals array (at the top of the stack)
  void *ffi_data; // ffi_resolved array
  size_t ffi_count;
  void *stack_base;
  size_t stack_size;
};

virtual_machine *vm_create(const char *main_unit_path, const char **paths,
                           size_t total_paths_len) {
  __gc_init();
  search_paths search_paths = {.paths = paths, .len = total_paths_len};

  virtual_machine *vm = ALLOC(virtual_machine);
  memset(vm, 0, sizeof(virtual_machine));
  vm->stack_base = MAP_FAILED;

  load_result lr = load(main_unit_path, &search_paths);
  if (!lr.units) {
    vm_destroy(vm);
    return NULL;
  }
  vm->bc_arr = lr.units;
  vm->bc_len = lr.units_len;

  vm->stack_size = 8 * 1024 * 1024;
  vm->stack_base = mmap(NULL, vm->stack_size, PROT_READ | PROT_WRITE,
                        MAP_PRIVATE | MAP_ANONYMOUS | MAP_GROWSDOWN, -1, 0);
  if (vm->stack_base == MAP_FAILED) {
    perror("mmap stack");
    vm_destroy(vm);
    return NULL;
  }

  // Compute total globals and place at the top of the stack
  vm->total_globals = count_globals(lr.units, lr.units_len);
  aint *stack_top = (aint *)((char *)vm->stack_base + vm->stack_size);
  vm->globals = stack_top - vm->total_globals;
  memset(vm->globals, 0, vm->total_globals * sizeof(aint));

  program *prog = decode(lr.units, lr.units_len, vm->globals);
  if (!prog) {
    vm_destroy(vm);
    return NULL;
  }

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
  if (vm->bc_arr) {
    for (size_t i = 0; i < vm->bc_len; i++) {
      bytecode_free(vm->bc_arr[i]);
    }
    free(vm->bc_arr);
  }
  free(vm->ffi_data);
  free(vm->code);
  free(vm->entry_points);
  if (vm->stack_base && vm->stack_base != MAP_FAILED) {
    munmap(vm->stack_base, vm->stack_size);
  }
  free(vm);
}

void vm_set_args(virtual_machine *vm, int argc, char *argv[]) {
  (void)vm;
  set_args(argc, argv);
}

aint vm_run(virtual_machine *vm) {
  aint *stack_top = (aint *)((char *)vm->stack_base + vm->stack_size);
  aint *sp = vm->globals - 1;

  __gc_stack_top = (size_t)sp;
  __gc_stack_bottom = (size_t)stack_top;

  aint *bp;
  aint ret_val = 0;
  for (size_t i = 0; i < vm->bc_len; i++) {
    insn *ip = vm->entry_points[i];
    ip->func(ip, sp, bp);
    ret_val = *sp;
  }

  return ret_val;
}
