#define _POSIX_C_SOURCE 200809L
#include "bytecode.h"
#include "memory.h"
#include "reader.h"
#include <fcntl.h>
#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#define HEADER_SIZE 16
#define PUB_ENTRY_SIZE 9
#define IMPORT_ENTRY_SIZE 4

bytecode *bytecode_load(const char *filename) {
  int fd = open(filename, O_RDONLY);
  if (fd < 0) {
    perror("bytecode_load: open");
    return NULL;
  }

  struct stat st;
  if (fstat(fd, &st) < 0) {
    perror("bytecode_load: fstat");
    close(fd);
    return NULL;
  }

  size_t file_size = (size_t)st.st_size;

  void *map = mmap(NULL, file_size, PROT_READ, MAP_PRIVATE, fd, 0);

  if (map == MAP_FAILED) {
    perror("bytecode_load: mmap");
    close(fd);
    return NULL;
  }

  close(fd);

  byte_reader reader;
  reader_init(&reader, (const uint8_t *)map, file_size);

  int32_t string_table_size = reader_i32(&reader);
  int32_t globals_count = reader_i32(&reader);
  int32_t num_imports = reader_i32(&reader);
  int32_t num_pubs = reader_i32(&reader);

  size_t st_offset = HEADER_SIZE;
  size_t imports_offset = st_offset + (size_t)string_table_size;
  size_t pubs_offset = imports_offset + (size_t)num_imports * IMPORT_ENTRY_SIZE;
  size_t code_offset = pubs_offset + (size_t)num_pubs * PUB_ENTRY_SIZE;
  size_t code_size = file_size - code_offset;

  // TODO: VALIdation

  const uint8_t *data = (const uint8_t *)map;
  const char *string_table = (const char *)(data + st_offset);

  bytecode *bc = ALLOC(bytecode);

  bc->map_base = map;
  bc->map_size = file_size;

  bc->string_table = string_table;
  bc->string_table_size = (size_t)string_table_size;
  bc->code = data + code_offset;
  bc->code_size = code_size;
  bc->globals_count = (size_t)globals_count;

  // Allocate and resolve public symbols
  bc->public_symbols.len = (size_t)num_pubs;
  if (num_pubs > 0) {
    bc->public_symbols.data = ALLOC_ARRAY(public_symbol, num_pubs);

    reader_seek(&reader, pubs_offset);
    for (int32_t i = 0; i < num_pubs; i++) {
      int32_t name_offset = reader_i32(&reader);
      int32_t code_off = reader_i32(&reader);
      uint8_t flag = reader_u8(&reader);

      bc->public_symbols.data[i].name = string_table + name_offset;
      bc->public_symbols.data[i].code_offset = code_off;
      bc->public_symbols.data[i].flag = flag;
    }
  }

  // Allocate and resolve imports
  bc->imports.len = (size_t)num_imports;
  if (num_imports > 0) {
    bc->imports.data = ALLOC_ARRAY(const char *, (size_t)num_imports);

    reader_seek(&reader, imports_offset);
    for (int32_t i = 0; i < num_imports; i++) {
      int32_t name_offset = reader_i32(&reader);

      bc->imports.data[i] = string_table + name_offset;
    }
  }

  // will be set later
  bc->name = NULL;

  return bc;
}

void bytecode_free(bytecode *bc) {
  if (!bc) {
    return;
  }
  munmap(bc->map_base, bc->map_size);
  free(bc->public_symbols.data);
  free(bc->imports.data);
  free((void *)bc->name);
  free(bc);
}
