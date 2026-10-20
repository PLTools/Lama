#ifndef LOADER_H
#define LOADER_H

#include "bytecode.h"
#include <stdbool.h>
#include <stddef.h>

#define BYTECODE_SUFFIX ".bc"
#define MAX_PATH_LEN 1024

typedef struct {
  const char **paths;
  size_t len;
} search_paths;

typedef struct {
  bytecode **units; // Array of unique loaded bytecode units
  size_t units_len; // Number of unique units
} load_result;

load_result load(const char *main_unit_name, const search_paths *paths);

#endif // LOADER_H
