/*
 * Bytecode loader for Lama VM.
 * Handles reading .bc files, including the string table, public symbols,
 * and the bytecode instructions themselves.
 */

#include "bytecode.h"
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

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
  int fd = open(filename, O_RDONLY);
  if (fd < 0) {
    perror("open");
    return NULL;
  }

  struct stat st;
  if (fstat(fd, &st) < 0) {
    perror("fstat");
    close(fd);
    return NULL;
  }

  size_t size = st.st_size;
  void *map = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
  close(fd);

  if (map == MAP_FAILED) {
    perror("mmap");
    return NULL;
  }

  uint8_t *data = (uint8_t *)map;

  int st_size = read_i32(data, 0);
  int globals_count = read_i32(data, 4);
  int num_pubs = read_i32(data, 8);

  int pubs_offset = HEADER_SIZE;
  int st_offset = pubs_offset + num_pubs * PUB_ENTRY_SIZE;
  int code_offset = st_offset + st_size;
  int code_size = size - code_offset;

  uint8_t *string_table = data + st_offset;
  int main_entry_point =
      find_entry_point(data, pubs_offset, num_pubs, string_table, "main");

  bytecode *bc = malloc(sizeof(bytecode));
  if (!bc) {
    munmap(map, size);
    return NULL;
  }

  bc->code = data + code_offset;
  bc->code_size = code_size;
  bc->entry_point = main_entry_point;
  bc->globals_count = globals_count;
  bc->public_symbols_count = num_pubs;
  bc->public_symbols = malloc(num_pubs * sizeof(int));
  for (int i = 0; i < num_pubs; i++) {
    int entry_offset = pubs_offset + i * PUB_ENTRY_SIZE;
    bc->public_symbols[i] = read_i32(data, entry_offset + 4);
  }

  bc->string_table = (const char *)string_table;

  bc->map_base = map;
  bc->map_size = size;

  return bc;
}

void free_bytecode(bytecode *bc) {
  if (bc) {
    if (bc->map_base) {
      munmap(bc->map_base, bc->map_size);
    }
    free(bc->public_symbols);
    free(bc);
  }
}
