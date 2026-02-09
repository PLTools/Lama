/*
 * Module manager implementation for Lama VM.
 */

#define _POSIX_C_SOURCE 200809L

#include "module_manager.h"
#include "arena.h"
#include "bytecode.h"
#include "da.h"
#include <libgen.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/*
 * Build the path to a module's .bc file by searching through paths.
 */
static char *build_module_path(const char *module_name,
                               const search_paths *paths, arena *arena) {
  char *path = ARENA_ALLOC(arena, char, MAX_PATH_LEN);

  for (size_t i = 0; i < paths->len; i++) {
    snprintf(path, MAX_PATH_LEN, "%s/%s.bc", paths->paths[i], module_name);
    if (access(path, F_OK) == 0) {
      return path;
    }
  }

  return path;
}

/* Extract module name from filename (without path and extension .bc) */
static char *extract_module_name(const char *filename, arena *arena) {
  char *path_copy = ARENA_STRDUP(arena, filename);
  char *base = basename(path_copy);

  char *dot = strrchr(base, '.');
  if (dot && strcmp(dot, ".bc") == 0) {
    *dot = '\0';
  }

  return ARENA_STRDUP(arena, base);
}

/*
 * Check if a string looks like a file path (contains '/' or ends with '.bc')
 */
static bool is_filepath(const char *str) {
  size_t len = strlen(str);
  return strchr(str, '/') != NULL ||
         (len > 3 && strcmp(str + len - 3, ".bc") == 0);
}

static loaded_module *find_module(module_manager *mm, const char *name) {
  for (size_t i = 0; i < mm->modules.len; i++) {
    if (strcmp(mm->modules.data[i]->bc->module_name, name) == 0) {
      return mm->modules.data[i];
    }
  }
  return NULL;
}

/*
 * Load modules recursively.
 */
static loaded_module *load_module(module_manager *mm, const char *s,
                                  const search_paths *paths, memory *mem) {
  char *filepath;
  char *module_name;

  // The initial call uses a filepath, recursive calls use module names
  if (is_filepath(s)) {
    filepath = ARENA_STRDUP(mem->tmp, s);
    module_name = extract_module_name(s, mem->tmp);
  } else {
    filepath = build_module_path(s, paths, mem->tmp);
    module_name = ARENA_STRDUP(mem->tmp, s);
  }

  // Check if module is already loaded (avoid duplicates and circular
  // dependencies)
  // TODO: check circular imports?
  loaded_module *result = find_module(mm, module_name);
  if (result) {
    return result;
  }

  bytecode *bc = load_bytecode(filepath, mem);
  if (!bc) {
    fprintf(stderr, "Failed to load module '%s' from '%s'\n", module_name,
            filepath);
    return NULL;
  }

  // NOTE: a bit ugly:
  bc->module_name = module_name;

  // Recursively load dependencies
  for (size_t i = 0; i < bc->imports.len; i++) {
    const char *import_name = bc->imports.data[i];

    // Skip since we already have it (as runtime.a)
    if (strcmp(import_name, "Std") == 0) {
      continue;
    }

    loaded_module *dep = load_module(mm, import_name, paths, mem);
    if (!dep) {
      fprintf(stderr, "Failed to load dependency '%s' for module '%s'\n",
              import_name, module_name);
      return NULL;
    }
  }

  result = ARENA_NEW(mem->main, loaded_module);
  result->bc = bc;
  result->global_base = (int32_t)mm->total_globals_count;
  mm->total_globals_count += bc->globals_count;
  mm->total_code_size += bc->code_size;
  // TODO: also use arena
  da_append(mm->modules, result);
  return result;
}

module_manager *load_modules(const char *main_module_path,
                             const search_paths *paths, memory *mem) {

  module_manager *mm = ARENA_NEW(mem->main, module_manager);

  da_init(mm->modules);
  // Reserve global index 0 for sysargs
  mm->total_globals_count = 1;

  arena_savepoint sp = arena_save(mem->tmp);
  loaded_module *main_mod = load_module(mm, main_module_path, paths, mem);
  arena_restore(mem->tmp, sp);

  if (!main_mod) {
    return NULL;
  }

  return mm;
}
