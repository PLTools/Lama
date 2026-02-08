#ifndef FFI_CALL_H
#define FFI_CALL_H

#include "../runtime/runtime_common.h"
#include <stdint.h>

/*
 * Call an external function by name using libffi.
 *
 */
aint ffi_call_c(const char *name, aint *args, int n_args);

#endif
