#include "symbols.h"
#include "da.h"
#include "memory.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *MAIN_FUNC = "main";

struct symbol_table {
  resolved_symbol *data;
  size_t len;
  size_t cap;
};

symbol_table *symbol_table_create(void) {
  symbol_table *table = ALLOC(symbol_table);
  da_init(*table);
  return table;
}

void symbol_table_destroy(symbol_table *table) {
  if (!table) {
    return;
  }
  da_free(*table);
  free(table);
}

resolved_symbol *symbol_table_find(symbol_table *table, const char *name) {
  for (size_t i = 0; i < table->len; i++) {
    if (strcmp(table->data[i].name, name) == 0) {
      return &table->data[i];
    }
  }
  return NULL;
}

static int symbol_table_add(symbol_table *table, const char *name,
                            bool is_function, int32_t idx) {

  // Allow duplicate main() (each uinit has one)
  if (strcmp(name, MAIN_FUNC) != 0) {
    resolved_symbol *existing = symbol_table_find(table, name);
    if (existing) {
      fprintf(stderr, "Error: Duplicate symbol '%s' found in symbol table\n",
              name);
      exit(EXIT_FAILURE);
    }
  }

  resolved_symbol entry = {
      .name = name,
      .is_function = is_function,
      .idx = idx,
  };

  da_append(*table, entry);

  return 0;
}

int symbol_table_add_function(symbol_table *table, const char *name,
                              int32_t code_idx) {
  return symbol_table_add(table, name, true, code_idx);
}

int symbol_table_add_global(symbol_table *table, const char *name,
                            int32_t global_idx) {
  return symbol_table_add(table, name, false, global_idx);
}
