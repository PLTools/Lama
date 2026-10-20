#ifndef SYMBOLS_H
#define SYMBOLS_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/*
 * Resolved symbol — represents a public function or global variable
 * that has been registered by the linker after decoding a unit.
 */
typedef struct {
  const char *name; // Symbol name (points into bytecode's string table)
  bool is_function; // true = function, false = global variable
  // For functions: index into the final code array
  // For globals: rebased global index (stack position)
  int32_t idx;
} resolved_symbol;

/*
 * Maps symbol names to resolved symbols (functions or globals).
 * Used by the linker to resolve stubs after all units are decoded.
 */
typedef struct symbol_table symbol_table;

symbol_table *symbol_table_create(void);
void symbol_table_destroy(symbol_table *table);
resolved_symbol *symbol_table_find_function(symbol_table *table,
                                            const char *name);
resolved_symbol *symbol_table_find_global(symbol_table *table,
                                          const char *name);
bool symbol_table_add_function(symbol_table *table, const char *name,
                               int32_t code_index);
bool symbol_table_add_global(symbol_table *table, const char *name,
                             int32_t global_idx);

#endif // SYMBOLS_H
