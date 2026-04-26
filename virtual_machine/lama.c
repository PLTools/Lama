#define _POSIX_C_SOURCE 200809L

#include "loader.h"
#include "memory.h"
#include "vm.h"
#include <getopt.h>
#include <libgen.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * Extract directory and unit name from a path. Returns false if the suffix does
 * not match.
 */
static bool parse_bytecode_path(const char *path, char **unit_name_out,
                                char **dir_out) {
  size_t len = strlen(path);
  size_t suffix_len = sizeof(BYTECODE_SUFFIX) - 1;
  if (len <= suffix_len ||
      strcmp(path + len - suffix_len, BYTECODE_SUFFIX) != 0) {
    return false;
  }

  char *path_copy = ESTRDUP(path);
  char *base = basename(path_copy);
  base[strlen(base) - suffix_len] = '\0';

  char *dir_copy = ESTRDUP(path);
  *unit_name_out = ESTRDUP(base);
  *dir_out = ESTRDUP(dirname(dir_copy));
  free(dir_copy);
  free(path_copy);
  return true;
}

#define MAX_INCLUDE_PATHS 64

static void print_usage(FILE *dest, const char *prog_name) {
  fprintf(dest, "Usage: %s [options] <unit name | bytecode.bc> [args]\n",
          prog_name);
  fprintf(dest,
          "\nWhen no options are specified, the VM will run the bytecode file "
          "and look for units in the same directory.\n");
  fprintf(dest,
          "You can also specify unit name instead of a bytecode file, but "
          "you need to manually include relevant search paths.\n");
  fprintf(dest, "Options:\n");
  fprintf(dest, "  -h, --help              Show this help message\n");
  fprintf(dest,
          "  -I, --include PATH      Add PATH to unit search paths (can be "
          "used multiple times)\n");
}

int main(int argc, char *argv[]) {
  char *include_paths[MAX_INCLUDE_PATHS];
  int include_path_count = 1;
  // TODO: better error handling in general
  int exit_code = 0;
  char *bytecode_dir = NULL;
  char *main_unit_name = NULL;
  bool is_path = false;

  static struct option long_options[] = {{"help", no_argument, 0, 'h'},
                                         {"include", required_argument, 0, 'I'},
                                         {0, 0, 0, 0}};

  int opt;
  int option_index = 0;

  while ((opt = getopt_long(argc, argv, "hI:", long_options, &option_index)) !=
         -1) {
    switch (opt) {
    case 'h':
      print_usage(stdout, argv[0]);
      return 0;
    case 'I':
      if (include_path_count < MAX_INCLUDE_PATHS) {
        include_paths[include_path_count++] = optarg;
      } else {
        fprintf(stderr, "Maximum number of include paths (%d) exceeded\n",
                MAX_INCLUDE_PATHS);
        return 1;
      }
      break;
    default:
      print_usage(stderr, argv[0]);
      return 1;
    }
  }

  if (optind >= argc) {
    fprintf(stderr, "No bytecode file specified\n\n");
    print_usage(stderr, argv[0]);
    return 1;
  }

  char *entry_arg = argv[optind];
  is_path = parse_bytecode_path(entry_arg, &main_unit_name, &bytecode_dir);
  if (is_path) {
    include_paths[0] = bytecode_dir;
  } else {
    main_unit_name = entry_arg;
  }

  virtual_machine *vm =
      vm_create(main_unit_name,
                (const char **)(is_path ? include_paths : include_paths + 1),
                is_path ? include_path_count : include_path_count - 1);
  if (!vm) {
    exit_code = 1;
    goto cleanup;
  }

  // Skip options, pass only program args
  vm_set_args(vm, argc - optind, argv + optind);

  vm_run(vm);

cleanup:
  vm_destroy(vm);
  if (is_path) {
    free(main_unit_name);
  }
  free(bytecode_dir);
  return exit_code;
}
