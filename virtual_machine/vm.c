#include "vm.h"
#include "../runtime/gc.h"
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
                           const char *search_path) {

  // TODO: estimates
  memory *mem = memory_create(1024 * 1024, 4096);
  virtual_machine *vm = ARENA_NEW(mem->main, virtual_machine);

  module_manager *mm = load_modules(main_module_path, search_path, mem);
  if (!mm) {
    return NULL;
  }

  vm->globals_count = mm->total_globals_count;

  insn *entry_point = decode_and_link(mm, mem);

  vm->entry_point = entry_point;

  return vm;
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

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stderr, "Usage: %s <bytecode.bc>\n", argv[0]);
    return 1;
  }

  __gc_init();

  set_args(argc, argv);

  virtual_machine *vm = vm_create(argv[1], NULL);
  if (!vm) {
    return 1;
  }

  vm_run(vm);

  return 0;
}
