#define _POSIX_C_SOURCE 200809L
#include "bytecode.h"
#include "memory.h"
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

  const char *string_table = map + st_offset;
  const uint8_t *data = (const uint8_t *)map;

  bytecode *bc = ALLOC(bytecode);

  bc->map_base = map;
  bc->map_size = file_size;

  bc->string_table = string_table;
  bc->string_table_size = (size_t)string_table_size;
  bc->code = data + code_offset;
  bc->code_size = code_size;
  bc->globals_count = (size_t)globals_count;

  bc->pubs = data + pubs_offset;
  bc->pubs_len = (size_t)num_pubs;

  bc->imports = data + imports_offset;
  bc->imports_len = (size_t)num_imports;

  // will be set later
  bc->name = NULL;

  return bc;
}

void bytecode_pubs_init(bytecode_iterator *iter, const bytecode *bc) {
  reader_init(&iter->reader, bc->pubs, bc->pubs_len * PUB_ENTRY_SIZE);
  iter->string_table = bc->string_table;
  iter->len = bc->pubs_len;
  iter->curr = 0;
}

bool bytecode_pubs_next(bytecode_iterator *iter, public_symbol *out) {
  if (iter->curr >= iter->len) {
    return false;
  }
  int32_t name_offset = reader_i32(&iter->reader);
  out->name = iter->string_table + name_offset;
  out->code_offset = reader_i32(&iter->reader);
  out->flag = reader_u8(&iter->reader);

  iter->curr++;
  return true;
}

void bytecode_imports_init(bytecode_iterator *it, const bytecode *bc) {
  reader_init(&it->reader, bc->imports, bc->imports_len * IMPORT_ENTRY_SIZE);
  it->string_table = bc->string_table;
  it->len = bc->imports_len;
  it->curr = 0;
}

bool bytecode_imports_next(bytecode_iterator *it, const char **out_name) {
  if (it->curr >= it->len) {
    return false;
  }
  int32_t name_offset = reader_i32(&it->reader);
  *out_name = it->string_table + name_offset;

  it->curr++;
  return true;
}

void bytecode_free(bytecode *bc) {
  if (!bc) {
    return;
  }
  munmap(bc->map_base, bc->map_size);
  free((void *)bc->name);
  free(bc);
}
