#ifndef VM_H
#define VM_H

#include <stddef.h>

typedef struct virtual_machine virtual_machine;

virtual_machine *vm_create(const char *main_unit_name, const char **paths,
                           size_t total_paths_len);

void vm_destroy(virtual_machine *vm);

void vm_set_args(virtual_machine *vm, int argc, char *argv[]);

void vm_run(virtual_machine *vm);

#endif // VM_H
