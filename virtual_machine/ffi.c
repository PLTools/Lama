/*
 * External function calling for Lama VM.
 * Uses libffi to dynamically call C functions.
 */

#include "ffi.h"
#include "../runtime/runtime_common.h"
#include <dlfcn.h>
#include <ffi.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// TODO: ugly?
typedef struct {
  const char *lama_name;
  const char *target_name;
  bool is_args_array;
  int fixed_args;
} func_metadata;

static const func_metadata func_table[] = {
    // Args array functions
    {"Lsubstring", "Lsubstring", true, 0},
    {"Lstringcat", "Lstringcat", true, 0},
    {"Lstring", "Lstring", true, 0},
    {"Li__Infix_4343", "Li__Infix_4343", true, 0}, // strcat
    {"Ls__Infix_58", "Ls__Infix_58", true, 0},     // : (cons)
    {"Lclone", "Lclone", true, 0},                 // clone

    // Variadic functions with mapping
    {"Lprintf", "Bprintf", false, 1},
    {"Lfprintf", "Bfprintf", false, 2},
    {"Lsprintf", "Bsprintf", false, 1},

    // Sentinel
    {NULL, NULL, false, 0, NULL}};

// TODO: cache?
static void *lookup_function(const char *name) {
  void *fn = dlsym(RTLD_DEFAULT, name);
  char *error = dlerror();
  if (error) {
    return NULL;
  }
  return fn;
}

static const func_metadata *lookup_metadata(const char *name) {
  for (int i = 0; func_table[i].lama_name != NULL; i++) {
    if (strcmp(name, func_table[i].lama_name) == 0) {
      return &func_table[i];
    }
  }
  return NULL;
}

/*
 * Functions that take (aint* args) - a pointer to argument array
 * TODO: a better way?
 */
static aint call_args_array_function(const char *name, aint *args) {
  void *fn = lookup_function(name);
  if (!fn) {
    fprintf(stderr, "Undefined external function: %s\n", name);
    exit(1);
  }

  ffi_cif cif;
  ffi_type *arg_types[1] = {&ffi_type_pointer};
  void *arg_values[1] = {&args};
  void *result = NULL;

  ffi_status status =
      ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, &ffi_type_pointer, arg_types);
  if (status != FFI_OK) {
    fprintf(stderr, "FFI prep failed for '%s': status=%d\n", name, status);
    exit(1);
  }

  ffi_call(&cif, FFI_FN(fn), &result, arg_values);
  return (aint)result;
}

/*
 * Mapping functions due to runtime.c x32 and x64 variants of printf etc.
 * TODO: very ugly
 */
static aint call_variadic_function(const char *target_name, int fixed_args,
                                   aint *args, int n_args) {
  void *fn = lookup_function(target_name);
  if (!fn) {
    fprintf(stderr, "Undefined external function: %s\n", target_name);
    exit(1);
  }

  if (n_args < fixed_args) {
    fprintf(stderr, "FFI call '%s': expected at least %d args, got %d\n",
            target_name, fixed_args, n_args);
    exit(1);
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

  // TODO: ABI ?
  ffi_status status = ffi_prep_cif_var(&cif, FFI_DEFAULT_ABI, fixed_args,
                                       n_args, &ffi_type_pointer, arg_types);

  if (status != FFI_OK) {
    fprintf(stderr, "FFI prep failed for '%s': status=%d\n", target_name,
            status);
    exit(1);
  }

  ffi_call(&cif, FFI_FN(fn), &result, arg_values);
  return (aint)result;
}

static aint call_regular_function(const char *name, aint *args, int n_args) {
  void *fn = lookup_function(name);
  if (!fn) {
    fprintf(stderr, "Undefined external function: %s\n", name);
    exit(1);
  }

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
    fprintf(stderr, "FFI prep failed for '%s': status=%d\n", name, status);
    exit(1);
  }

  ffi_call(&cif, FFI_FN(fn), &result, arg_values);

  return result;
}

aint ffi_call_c(const char *name, aint *args, int n_args) {
  const func_metadata *meta = lookup_metadata(name);

  if (meta) {
    if (meta->is_args_array) {
      return call_args_array_function(meta->target_name, args);
    } else {
      return call_variadic_function(meta->target_name, meta->fixed_args, args,
                                    n_args);
    }
  }

  return call_regular_function(name, args, n_args);
}
