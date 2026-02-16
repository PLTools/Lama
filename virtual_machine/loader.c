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
 * Check if a string looks like a file path (contains '/' or ends with '.bc')
 */
static bool is_filepath(const char *str) {
  size_t len = strlen(str);
  return strchr(str, '/') != NULL ||
         (len > 3 && strcmp(str + len - 3, ".bc") == 0);
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
static bool load_unit_recursive(bytecode_array *units, const char *s,
                                const search_paths *paths) {
  char *filepath = NULL;
  char *unit_name = NULL;

  // The initial call uses a filepath, recursive calls use unit names
  if (is_filepath(s)) {
    filepath = ESTRDUP(s);
    unit_name = extract_unit_name(s);
  } else {
    filepath = build_unit_path(s, paths);
    unit_name = ESTRDUP(s);
  }

  if (find_loaded(units, unit_name)) {
    free(filepath);
    free(unit_name);
    return true;
  }

  bytecode *bc = bytecode_load(filepath);
  if (!bc) {
    fprintf(stderr, "Failed to load dependency '%s' from '%s'\n", unit_name,
            filepath);
    free(filepath);
    free(unit_name);
    return false;
  }
  bc->name = unit_name;

  // Recursively load dependencies first (topological order)
  const char *import_name;
  bytecode_iterator iter;
  bytecode_imports_init(&iter, bc);
  while (bytecode_imports_next(&iter, &import_name)) {

    // Skip Std since we have it as runtime.a
    if (strcmp(import_name, "Std") == 0) {
      continue;
    }

    load_unit_recursive(units, import_name, paths);
  }

  da_append(*units, bc);
  free(filepath);
  return true;
}

load_result load(const char *main_unit_path, const search_paths *paths) {
  bytecode_array m;
  da_init(m);

  load_unit_recursive(&m, main_unit_path, paths);

  load_result result = {
      .units = m.data,
      .units_len = m.len,
  };
  return result;
}
