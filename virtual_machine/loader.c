/*
 * Unit loader implementation for Lama VM.
 * Recursively loads bytecode files following import declarations.
 */

#define _POSIX_C_SOURCE 200809L

#include "loader.h"
#include "bytecode.h"
#include "da.h"
#include "memory.h"
#include <libgen.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef struct {
  bytecode **data;
  size_t len;
  size_t cap;
} bytecode_array;

typedef struct {
  size_t *data; // Indices into the loaded bytecode_array
  size_t len;
  size_t cap;
} exec_order;

/*
 * Build the path to a unit's .bc file by searching through paths.
 */
static char *build_unit_path(const char *unit_name, const search_paths *paths) {
  char *path = ALLOC_ARRAY(char, MAX_PATH_LEN);

  for (size_t i = 0; i < paths->len; i++) {
    snprintf(path, MAX_PATH_LEN, "%s/%s.bc", paths->paths[i], unit_name);
    if (access(path, F_OK) == 0) {
      return path;
    }
  }

  free(path);
  return NULL;
}

/*
 * Find a loaded unit by name. Returns its index, or (size_t)-1 if not found.
 */
static size_t find_loaded(bytecode_array *units, const char *name) {
  for (size_t i = 0; i < units->len; i++) {
    if (strcmp(units->data[i]->name, name) == 0) {
      return i;
    }
  }
  return (size_t)-1;
}

/*
 * Extract name from filename (without path and extension .bc)
 */
static char *extract_unit_name(const char *filename) {
  char *path_copy = ESTRDUP(filename);
  char *base = basename(path_copy);

  char *dot = strrchr(base, '.');
  if (dot && strcmp(dot, ".bc") == 0) {
    *dot = '\0';
  }

  char *result = ESTRDUP(base);
  free(path_copy);
  return result;
}

/*
 * Load a single unit and its dependencies recursively.
 */
static bool load_unit_recursive(bytecode_array *units, exec_order *order,
                                const char *s, const search_paths *paths) {

  char *filepath = build_unit_path(s, paths);
  char *unit_name = ESTRDUP(s);

  size_t existing = find_loaded(units, unit_name);
  if (existing != (size_t)-1) {
    free(filepath);
    free(unit_name);
    return true;
  }

  bytecode *bc = bytecode_load(filepath);
  if (!bc) {
    fprintf(stderr, "Failed to load dependency '%s' from '%s'\n", unit_name,
            filepath);
    free(unit_name);
    return false;
  }
  free(filepath);
  bc->name = unit_name;

  size_t my_idx = units->len;
  da_append(*units, bc);

  // Recursively load dependencies

  const char *import_name;
  bytecode_iterator iter;
  bytecode_imports_init(&iter, bc);
  while (bytecode_imports_next(&iter, &import_name)) {
    // Skip Std since we have it as runtime.a
    if (strcmp(import_name, "Std") == 0) {
      continue;
    }

    if (!load_unit_recursive(units, order, import_name, paths)) {
      free(filepath);
      return false;
    }
  }

  da_append(*order, my_idx);
  return true;
}

static bytecode *load_main_unit(const char *path) {
  char *filepath = ESTRDUP(path);
  char *unit_name = extract_unit_name(path);
  bytecode *bc = bytecode_load(filepath);
  if (!bc) {
    fprintf(stderr, "Failed to load main unit from '%s'\n", filepath);
    exit(EXIT_FAILURE);
  }

  bc->name = unit_name;
  free(filepath);
  return bc;
}

load_result load(const char *main_unit_path, const search_paths *paths) {
  load_result result = {0};
  bytecode_array m;
  da_init(m);
  exec_order order;
  da_init(order);

  bytecode *bc = load_main_unit(main_unit_path);

  const char *import_name;
  bytecode_iterator iter;
  bytecode_imports_init(&iter, bc);
  while (bytecode_imports_next(&iter, &import_name)) {

    // Skip Std since we have it as runtime.a
    if (strcmp(import_name, "Std") == 0) {
      continue;
    }

    if (!load_unit_recursive(&m, &order, import_name, paths)) {
      free(order.data);
      return result;
    }
  }

  // Check if main unit was already loaded as a dependency
  // NOTE: this is all done to comply with the semantics of the reference
  // implementation which allows main module to execute twice (if it's imported
  // by one of its dependencies).
  size_t main_idx = find_loaded(&m, bc->name);
  if (main_idx == (size_t)-1) {
    main_idx = m.len;
    da_append(m, bc);
  } else {
    bytecode_free(bc);
  }
  da_append(order, main_idx);

  result.units = m.data;
  result.units_len = m.len;
  result.exec_order = order.data;
  result.exec_order_len = order.len;
  return result;
}
