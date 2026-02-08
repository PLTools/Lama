/*
 * Module loader and linker for Lama VM.
 *
 */

#ifndef MODULE_MANAGER_H
#define MODULE_MANAGER_H

#include "arena.h"
#include "bytecode.h"
#include <stdbool.h>
#include <stddef.h>

#define MAX_PATH_LEN 1024
#define INITIAL_SYMBOL_TABLE_CAP 64
#define INITIAL_MODULE_CAP 8

typedef struct {
  bytecode *bc;        // Loaded bytecode
  int32_t global_base; // Starting index for this module's globals
} loaded_module;

typedef struct {
  // Loaded modules (topological order)
  struct {
    loaded_module **data;
    size_t len;
    size_t cap;
  } modules;

  // Combined globals count
  // Used for stack allocation
  size_t total_globals_count;
  size_t total_code_size;

} module_manager;

module_manager *load_modules(const char *main_module_path,
                             const char *search_path, memory *mem);

#endif
