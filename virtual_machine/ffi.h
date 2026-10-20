#ifndef FFI_CALL_H
#define FFI_CALL_H

#include "../runtime/runtime_common.h"
#include "insn.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef enum { FFI_REGULAR, FFI_ARGS_ARRAY, FFI_VARIADIC } ffi_kind;

typedef struct {
  void *fn_ptr;
  ffi_kind kind;
  int fixed_args;
} ffi_resolved;

typedef struct ffi_call_table ffi_call_table;

ffi_call_table *ffi_call_table_create(void);
void ffi_call_table_destroy(ffi_call_table *table);

/*
 * Find existing or resolve and add.
 */
size_t ffi_call_table_intern(ffi_call_table *table, const char *name);
size_t ffi_call_table_len(ffi_call_table *table);

ffi_resolved *ffi_call_table_release(ffi_call_table *table);

typedef struct {
  ffi_call_table *table;
  size_t curr;
} ffi_call_iterator;

void ffi_call_table_emit_init(ffi_call_iterator *iter, ffi_call_table *table);
bool ffi_call_table_emit_next(ffi_call_iterator *iter, ffi_resolved **out);

aint ffi_call_c(const ffi_resolved *res, aint *args, int n_args);

#endif // FFI_CALL_H
