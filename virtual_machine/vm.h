#ifndef VM_H
#define VM_H

#include "decoder.h"
#include "module_manager.h"
#include <stddef.h>

typedef struct {
  size_t globals_count; // Number of globals
  insn *entry_point;    // Entry point instruction

} virtual_machine;

virtual_machine *vm_create(const char *main_module_path,
                           const search_paths *paths);

aint vm_run(virtual_machine *vm);

#endif // VM_H
