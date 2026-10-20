/*
 * External function calling for Lama VM.
 * Uses libffi to dynamically call C functions.
 */

#include "ffi.h"
#include "../runtime/runtime_common.h"
#include "da.h"
#include "memory.h"
#include <dlfcn.h>
#include <ffi.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct ffi_call_table {
  ffi_resolved *data;
  size_t len;
  size_t cap;

  // Used for dedup
  struct {
    const char **data;
    size_t len;
    size_t cap;
  } names;
};

ffi_call_table *ffi_call_table_create(void) {
  ffi_call_table *table = ALLOC(ffi_call_table);
  da_init(*table);
  da_init(table->names);
  return table;
}

void ffi_call_table_destroy(ffi_call_table *table) {
  if (!table) {
    return;
  }
  for (size_t i = 0; i < table->names.len; i++) {
    free((char *)table->names.data[i]);
  }
  da_free(table->names);
  free(table->data);
  free(table);
}

#define FUNC_PREFIX "L"

typedef struct {
  const char *name;        // raw name as it appears in bytecode
  const char *target_name; // explicit dlsym name, or NULL for default
  bool is_args_array;
  int fixed_args;
} func_metadata;

static const func_metadata func_table[] = {
    // Args array functions
    {"substring", NULL, true, 0},
    {"stringcat", NULL, true, 0},
    {"string", NULL, true, 0},
    {"i__Infix_4343", NULL, true, 0}, // strcat
    {"s__Infix_58", NULL, true, 0},   // : (cons)
    {"clone", NULL, true, 0},

    // Variadic functions with mapping
    {"printf", "Bprintf", false, 1},
    {"fprintf", "Bfprintf", false, 2},
    {"sprintf", "Bsprintf", false, 1},

    // Sentinel
    {NULL, NULL, false, 0}};

static void *lookup_function(const char *name) {
  void *fn = dlsym(RTLD_DEFAULT, name);
  char *error = dlerror();
  if (error) {
    fprintf(stderr, "Error looking up function '%s': %s\n", name, error);
    return NULL;
  }
  return fn;
}

static const func_metadata *lookup_metadata(const char *name) {
  for (int i = 0; func_table[i].name != NULL; i++) {
    if (strcmp(name, func_table[i].name) == 0) {
      return &func_table[i];
    }
  }
  return NULL;
}

size_t ffi_call_table_intern(ffi_call_table *table, const char *name) {
  for (size_t i = 0; i < table->names.len; i++) {
    if (strcmp(table->names.data[i], name) == 0) {
      return i;
    }
  }

  const func_metadata *meta = lookup_metadata(name);

  ffi_kind kind = FFI_REGULAR;
  int fixed_args = 0;
  if (meta) {
    if (meta->is_args_array) {
      kind = FFI_ARGS_ARRAY;
    } else {
      kind = FFI_VARIADIC;
      fixed_args = meta->fixed_args;
    }
  }

  void *fn;
  if (meta && meta->target_name) {
    fn = lookup_function(meta->target_name);
  } else {
    size_t nlen = strlen(name);
    char prefixed[sizeof(FUNC_PREFIX) + nlen];
    memcpy(prefixed, FUNC_PREFIX, sizeof(FUNC_PREFIX) - 1);
    memcpy(prefixed + sizeof(FUNC_PREFIX) - 1, name, nlen + 1);
    fn = lookup_function(prefixed);
  }

  if (!fn) {
    fprintf(stderr, "Undefined external function: %s\n", name);
    exit(EXIT_FAILURE);
  }

  ffi_resolved entry = {
      .fn_ptr = fn,
      .kind = kind,
      .fixed_args = fixed_args,
  };

  da_append(*table, entry);
  da_append(table->names, ESTRDUP(name));
  return table->len - 1;
}

size_t ffi_call_table_len(ffi_call_table *table) { return table->len; }

ffi_resolved *ffi_call_table_release(ffi_call_table *table) {
  ffi_resolved *data = table->data;
  table->data = NULL;
  table->len = 0;
  table->cap = 0;
  return data;
}

void ffi_call_table_emit_init(ffi_call_iterator *iter, ffi_call_table *table) {
  iter->table = table;
  iter->curr = 0;
}

bool ffi_call_table_emit_next(ffi_call_iterator *iter, ffi_resolved **out) {
  if (iter->curr >= iter->table->len) {
    return false;
  }
  *out = &iter->table->data[iter->curr];
  iter->curr++;
  return true;
}

static aint call_args_array(void *fn_ptr, aint *args) {
  ffi_cif cif;
  ffi_type *arg_types[1] = {&ffi_type_pointer};
  void *arg_values[1] = {&args};
  void *result = NULL;

  ffi_status status =
      ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, &ffi_type_pointer, arg_types);
  if (status != FFI_OK) {
    fprintf(stderr, "FFI prep failed: status=%d\n", status);
    exit(EXIT_FAILURE);
  }

  ffi_call(&cif, FFI_FN(fn_ptr), &result, arg_values);
  return (aint)result;
}

static aint call_variadic(void *fn_ptr, int fixed_args, aint *args,
                          int n_args) {
  if (n_args < fixed_args) {
    fprintf(stderr, "FFI variadic call: expected at least %d args, got %d\n",
            fixed_args, n_args);
    exit(EXIT_FAILURE);
  }

  ffi_cif cif;
  ffi_type *arg_types[n_args];
  void *arg_values[n_args];
  aint int_values[n_args];
  void *result = NULL;

  for (int i = 0; i < n_args; i++) {
    if (UNBOXED(args[i])) {
      int_values[i] = UNBOX(args[i]);
      arg_types[i] = &ffi_type_pointer;
      arg_values[i] = &int_values[i];
    } else {
      arg_types[i] = &ffi_type_pointer;
      arg_values[i] = &args[i];
    }
  }

  ffi_status status = ffi_prep_cif_var(&cif, FFI_DEFAULT_ABI, fixed_args,
                                       n_args, &ffi_type_pointer, arg_types);
  if (status != FFI_OK) {
    fprintf(stderr, "FFI prep failed: status=%d\n", status);
    exit(EXIT_FAILURE);
  }

  ffi_call(&cif, FFI_FN(fn_ptr), &result, arg_values);
  return (aint)result;
}

static aint call_regular(void *fn_ptr, aint *args, int n_args) {
  ffi_cif cif;
  ffi_type *arg_types[n_args];
  void *arg_values[n_args];
  aint result;

  for (int i = 0; i < n_args; i++) {
    arg_types[i] = &ffi_type_pointer;
    arg_values[i] = &args[i];
  }

  ffi_status status =
      ffi_prep_cif(&cif, FFI_DEFAULT_ABI, n_args, &ffi_type_pointer, arg_types);
  if (status != FFI_OK) {
    fprintf(stderr, "FFI prep failed: status=%d\n", status);
    exit(EXIT_FAILURE);
  }

  ffi_call(&cif, FFI_FN(fn_ptr), &result, arg_values);
  return result;
}

aint ffi_call_c(const ffi_resolved *res, aint *args, int n_args) {
  switch (res->kind) {
  case FFI_ARGS_ARRAY:
    return call_args_array(res->fn_ptr, args);
  case FFI_VARIADIC:
    return call_variadic(res->fn_ptr, res->fixed_args, args, n_args);
  case FFI_REGULAR:
    return call_regular(res->fn_ptr, args, n_args);
  default:
    fprintf(stderr, "Unknown FFI kind: %d\n", res->kind);
    exit(EXIT_FAILURE);
  }
}
