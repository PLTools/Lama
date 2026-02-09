#include "vm.h"
#include "../runtime/runtime_common.h"
#include "arena.h"
#include "decoder.h"
#include "linker.h"
#include "module_manager.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void set_args(aint argc, char *argv[]);
extern size_t __gc_stack_top, __gc_stack_bottom;

virtual_machine *vm_create(const char *main_module_path,
                           const search_paths *paths) {

  // TODO: estimates
  memory *mem = memory_create(1024 * 1024, 4096);
  virtual_machine *vm = ARENA_NEW(mem->main, virtual_machine);

  module_manager *mm = load_modules(main_module_path, paths, mem);
  if (!mm) {
    memory_destroy(mem);
    return NULL;
  }

  vm->globals_count = mm->total_globals_count;

  insn *entry_point = decode_and_link(mm, mem);
  vm->entry_point = entry_point;

  vm->mem = mem;

  return vm;
}

void vm_destroy(virtual_machine *vm) { memory_destroy(vm->mem); }

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
