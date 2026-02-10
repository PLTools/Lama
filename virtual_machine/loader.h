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

bytecode **load(const char *main_unit_path, const search_paths *paths,
                size_t *out_len);

#endif // LOADER_H
