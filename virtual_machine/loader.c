/*
 * Unit loader implementation for Lama VM.
 * Recursively loads bytecode files following import declarations.
 */

#define _POSIX_C_SOURCE 200809L

#include "loader.h"
#include "bytecode.h"
#include "da.h"
#include "memory.h"
#include <fcntl.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  bytecode **data;
  size_t len;
  size_t cap;
} bytecode_array;

typedef struct {
  const char **data;
  size_t len;
  size_t cap;
} name_array;

static bool is_loading(const name_array *stack, const char *name) {
  for (size_t i = stack->len; i-- > 0; ) {
    if (strcmp(stack->data[i], name) == 0)
      return true;
  }
  return false;
}

static void free_loaded_units(bytecode_array *units) {
  for (size_t i = 0; i < units->len; i++) {
    bytecode_free(units->data[i]);
  }
  da_free(*units);
}

static bytecode *load_unit_from_dir(const char *unit_name, const char *dir) {
  char path[MAX_PATH_LEN];
  const char *base_dir = dir ? dir : ".";

  snprintf(path, MAX_PATH_LEN, "%s/%s.bc", base_dir, unit_name);
  int fd = open(path, O_RDONLY);
  if (fd >= 0) {
    return bytecode_load_fd(fd);
  }

  return NULL;
}

/*
 * Resolve a unit name against the search paths and load the first
 * bytecode file.
 */
static bytecode *load_unit_from_paths(const char *unit_name,
                                      const search_paths *paths) {
  for (size_t i = 0; i < paths->len; i++) {
    bytecode *bc = load_unit_from_dir(unit_name, paths->paths[i]);
    if (bc) {
      return bc;
    }
  }

  return NULL;
}

static bool find_loaded(bytecode_array *units, const char *name) {
  for (size_t i = 0; i < units->len; i++) {
    if (strcmp(units->data[i]->name, name) == 0) {
      return true;
    }
  }
  return false;
}

/*
 * Load a single unit and its dependencies recursively.
 */
static bool load_unit_recursive(bytecode_array *units, name_array *loading,
                                const char *unit_name, bytecode *bc,
                                const search_paths *paths) {
  bc->name = ESTRDUP(unit_name);

  da_append(*loading, unit_name);

  // Recursively load dependencies first (topological order)
  const char *import_name;
  bytecode_iterator iter;
  bytecode_imports_init(&iter, bc);
  while (bytecode_imports_next(&iter, &import_name)) {

    // Skip Std since we have it as runtime.a
    if (strcmp(import_name, "Std") == 0) {
      continue;
    }

    if (is_loading(loading, import_name)) {
      fprintf(stderr, "Circular dependency: '%s' -> '%s'\n", unit_name,
              import_name);
      goto fail;
    }

    if (find_loaded(units, import_name)) {
      continue;
    }

    bytecode *dep_bc = load_unit_from_paths(import_name, paths);
    if (!dep_bc) {
      fprintf(stderr, "Failed to load dependency '%s'\n", import_name);
      goto fail;
    }

    if (!load_unit_recursive(units, loading, import_name, dep_bc, paths)) {
      goto fail;
    }
  }

  loading->len--;
  da_append(*units, bc);
  return true;

fail:
  loading->len--;
  bytecode_free(bc);
  return false;
}

load_result load(const char *main_unit_name, const char *main_unit_dir,
                 const search_paths *paths) {
  bytecode_array m;
  da_init(m);

  name_array loading;
  da_init(loading);

  bytecode *bc = load_unit_from_dir(main_unit_name, main_unit_dir);
  if (!bc) {
    fprintf(stderr, "Failed to load unit '%s'\n", main_unit_name);
    goto cleanup;
  }

  if (!load_unit_recursive(&m, &loading, main_unit_name, bc, paths)) {
    goto cleanup;
  }
  da_free(loading);

  return (load_result){
      .units = m.data,
      .units_len = m.len,
  };

cleanup:
  da_free(loading);
  free_loaded_units(&m);
  return (load_result){0};
}
