#ifndef LOADER_H
#define LOADER_H

#include "bytecode.h"
#include <stdbool.h>
#include <stddef.h>

#define MAX_PATH_LEN 1024

typedef struct {
  const char **paths;
  size_t len;
} search_paths;

typedef struct {
  bytecode **units;      // Array of unique loaded bytecode units
  size_t units_len;      // Number of unique units
  size_t *exec_order;    // Indices into units[], in execution order
  size_t exec_order_len; // Length of exec_order (may be units_len + 1)
} load_result;

load_result load(const char *main_unit_path, const search_paths *paths);

#endif // LOADER_H
