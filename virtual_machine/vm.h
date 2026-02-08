#ifndef VM_H
#define VM_H

#include "decoder.h"
#include <stddef.h>

typedef struct {
  size_t globals_count; // Number of globals
  insn *entry_point;    // Entry point instruction

} virtual_machine;

virtual_machine *vm_create(const char *main_module_path,
                           const char *search_path);

aint vm_run(virtual_machine *vm);

#endif // VM_H
