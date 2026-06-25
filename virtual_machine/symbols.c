#include "symbols.h"
#include "da.h"
#include "memory.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

static resolved_symbol *symbol_table_find(symbol_table *table, const char *name,
                                          bool is_function) {
  for (size_t i = 0; i < table->len; i++) {
    if (strcmp(table->data[i].name, name) == 0 &&
        table->data[i].is_function == is_function) {
      return &table->data[i];
    }
  }
  return NULL;
}

static bool symbol_table_add(symbol_table *table, const char *name, int32_t idx,
                             bool is_function) {
  resolved_symbol *existing = symbol_table_find(table, name, is_function);
  if (existing) {
    fprintf(stderr, "Error: Duplicate symbol '%s' found in symbol table\n",
            name);
    return false;
  }

  resolved_symbol entry = {
      .name = name,
      .is_function = is_function,
      .idx = idx,
  };

  da_append(*table, entry);

  return true;
}

resolved_symbol *symbol_table_find_function(symbol_table *table,
                                            const char *name) {
  return symbol_table_find(table, name, true);
}

resolved_symbol *symbol_table_find_global(symbol_table *table,
                                          const char *name) {
  return symbol_table_find(table, name, false);
}

bool symbol_table_add_function(symbol_table *table, const char *name,
                               int32_t code_idx) {
  return symbol_table_add(table, name, code_idx, true);
}

bool symbol_table_add_global(symbol_table *table, const char *name,
                             int32_t global_idx) {
  return symbol_table_add(table, name, global_idx, false);
}
