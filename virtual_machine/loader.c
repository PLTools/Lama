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
#include <libgen.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  bytecode **data;
  size_t len;
  size_t cap;
} bytecode_array;

static void free_loaded_units(bytecode_array *units) {
  for (size_t i = 0; i < units->len; i++) {
    bytecode_free(units->data[i]);
  }
  da_free(*units);
}

/*
 * Resolve a unit name against the search paths and load the first
 * bytecode file.
 */
static bytecode *load_unit_from_paths(const char *unit_name,
                                      const search_paths *paths) {
  static char path[MAX_PATH_LEN];
  for (size_t i = 0; i < paths->len; i++) {
    snprintf(path, MAX_PATH_LEN, "%s/%s.bc", paths->paths[i], unit_name);
    int fd = open(path, O_RDONLY);
    if (fd >= 0) {
      return bytecode_load_fd(fd);
    }
  }

  return NULL;
}

/*
 * Check if a string looks like a file path (contains '/' or ends with '.bc')
 */
static bool is_filepath(const char *str) {
  if (strchr(str, '/') != NULL)
    return true;
  size_t len = strlen(str);
  return len > 3 && strcmp(str + len - 3, ".bc") == 0;
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
static bool load_unit_recursive(bytecode_array *units, const char *unit_name,
                                bytecode *bc, const search_paths *paths) {
  bc->name = ESTRDUP(unit_name);

  // Recursively load dependencies first (topological order)
  const char *import_name;
  bytecode_iterator iter;
  bytecode_imports_init(&iter, bc);
  while (bytecode_imports_next(&iter, &import_name)) {

    // Skip Std since we have it as runtime.a
    if (strcmp(import_name, "Std") == 0) {
      continue;
    }

    if (find_loaded(units, import_name)) {
      continue;
    }

    bytecode *dep_bc = load_unit_from_paths(import_name, paths);
    if (!dep_bc) {
      fprintf(stderr, "Failed to load dependency '%s'\n", import_name);
      bytecode_free(bc);
      return false;
    }

    if (!load_unit_recursive(units, import_name, dep_bc, paths)) {
      bytecode_free(bc);
      return false;
    }
  }

  da_append(*units, bc);
  return true;
}

load_result load(const char *main_unit_path, const search_paths *paths) {
  bytecode_array m;
  da_init(m);

  bool is_path = is_filepath(main_unit_path);
  bytecode *bc = is_path ? bytecode_load(main_unit_path)
                         : load_unit_from_paths(main_unit_path, paths);
  if (!bc) {
    fprintf(stderr, "Failed to load unit '%s'\n", main_unit_path);
    return (load_result){0};
  }

  char *unit_name =
      is_path ? extract_unit_name(main_unit_path) : ESTRDUP(main_unit_path);

  if (!load_unit_recursive(&m, unit_name, bc, paths)) {
    free(unit_name);
    free_loaded_units(&m);
    return (load_result){0};
  }
  free(unit_name);

  load_result result = {
      .units = m.data,
      .units_len = m.len,
  };
  return result;
}
