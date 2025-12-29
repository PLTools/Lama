#include "bytecode.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int read_i32(const uint8_t data[], int offset) {
  return data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16) |
         (data[offset + 3] << 24);
}

#define HEADER_SIZE 12
#define PUB_ENTRY_SIZE 8

static int find_entry_point(const uint8_t *data, int pubs_offset, int num_pubs,
                            const uint8_t *string_table, const char *name) {
  for (int i = 0; i < num_pubs; i++) {
    int entry_offset = pubs_offset + i * PUB_ENTRY_SIZE;
    int name_offset = read_i32(data, entry_offset);
    char *f_name = (char *)(string_table + name_offset);
    int address = read_i32(data, entry_offset + 4);
    if (strcmp(f_name, name) == 0) {
      return address;
    }
  }
  return -1;
}

bytecode *load_bytecode(const char *filename) {
  FILE *f = fopen(filename, "rb");
  if (!f) {
    perror("fopen");
    return NULL;
  }

  fseek(f, 0, SEEK_END);
  long size = ftell(f);
  rewind(f);

  uint8_t *data = malloc(size);

  if (!data) {
    fclose(f);
    return NULL;
  }

  if (fread(data, 1, size, f) != size) {
    perror("fread");
    fclose(f);
    free(data);
    return NULL;
  }
  fclose(f);

  int st_size = read_i32(data, 0);
  int globals_count = read_i32(data, 4);
  int num_pubs = read_i32(data, 8);
  int num_imports = read_i32(data, 12);
  int num_ext_fixups = read_i32(data, 16);

  int pubs_offset = HEADER_SIZE;
  int st_offset = pubs_offset + num_pubs * PUB_ENTRY_SIZE;
  int code_offset = st_offset + st_size;
  int code_size = size - code_offset;

  uint8_t *string_table = data + st_offset;
  int main_entry_point =
      find_entry_point(data, pubs_offset, num_pubs, string_table, "main");

  bytecode *bc = malloc(sizeof(bytecode));
  bc->code = malloc(code_size);
  memcpy((void *)bc->code, data + code_offset, code_size);
  bc->code_size = code_size;
  bc->entry_point = main_entry_point;
  bc->globals_count = globals_count;
  bc->public_symbols_count = num_pubs;
  bc->public_symbols = malloc(num_pubs * sizeof(int));
  for (int i = 0; i < num_pubs; i++) {
    int entry_offset = pubs_offset + i * PUB_ENTRY_SIZE;
    bc->public_symbols[i] = read_i32(data, entry_offset + 4);
  }

  bc->string_table = malloc(st_size);
  memcpy((void *)bc->string_table, string_table, st_size);

  free(data);
  return bc;
}

void free_bytecode(bytecode *bc) {
  if (bc) {
    free((void *)bc->code);
    free((void *)bc->string_table);
    free(bc->public_symbols);
    free(bc);
  }
}
