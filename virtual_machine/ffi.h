#ifndef FFI_CALL_H
#define FFI_CALL_H

#include "../runtime/runtime_common.h"
#include "insn.h"
#include <stdint.h>

/*
 * FFI call by name using libffi.
 *
 */
aint ffi_call_c(const char *name, aint *args, int n_args);

typedef struct {
  const char *name; // Function name
  insn *stub;       // Pointer to insn-stub
} ffi_call_stub;

/*
 * Cache of generated stubs for unresolved FFI references.
 */
typedef struct ffi_call_table ffi_call_table;

ffi_call_table *ffi_call_table_create(void);
void ffi_call_table_destroy(ffi_call_table *table);
size_t ffi_call_table_find(ffi_call_table *table, const char *name);
insn *ffi_call_table_add(ffi_call_table *table, const char *name, fn stub_fn);
size_t ffi_call_table_count(ffi_call_table *table);
ffi_call_stub *ffi_call_table_get(ffi_call_table *table, size_t idx);

insn *ffi_call_table_get_all(ffi_call_table *table);

#endif // FFI_CALL_H
