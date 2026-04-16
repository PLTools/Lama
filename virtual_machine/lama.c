#define _POSIX_C_SOURCE 200809L

#include "memory.h"
#include "vm.h"
#include <getopt.h>
#include <libgen.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_INCLUDE_PATHS 64

/*
 * Check if a string looks like a file (ends with '.bc')
 */
static bool is_filepath(const char *str) {
  size_t len = strlen(str);
  return len > 3 && strcmp(str + len - 3, ".bc") == 0;
}

/*
 * Extract name from filename (without path and extension .bc)
 */
static char *extract_unit_name(const char *filename) {
  char *path_copy = ESTRDUP(filename);
  char *base = basename(path_copy);

  char *dot = strrchr(base, '.');
  if (dot && strcmp(dot, ".bc") == 0) {
    *dot = '\0';
  }

  char *result = ESTRDUP(base);
  free(path_copy);
  return result;
}

static void print_usage(FILE *dest, const char *prog_name) {
  fprintf(dest, "Usage: %s [options] <bytecode.bc> [args]\n", prog_name);
  fprintf(dest,
          "\nWhen no options are specified, the VM will run the bytecode file "
          "and look for units in the same directory.\n");
  fprintf(dest, "Options:\n");
  fprintf(dest, "  -h, --help              Show this help message\n");
  fprintf(dest,
          "  -I, --include PATH      Add PATH to unit search paths (can be "
          "used multiple times)\n");
}

int main(int argc, char *argv[]) {
  char *include_paths[MAX_INCLUDE_PATHS];
  int include_path_count = 0;
  // TODO: better error handling in general
  int exit_code = 0;
  char *bytecode_dir = NULL;
  char *main_unit_name_alloc = NULL;
  const char *main_unit_dir = NULL;

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

  char *name = argv[optind];
  if (is_filepath(name)) {
    if (include_path_count >= MAX_INCLUDE_PATHS) {
      fprintf(stderr, "Maximum number of include paths (%d) exceeded\n",
              MAX_INCLUDE_PATHS);
      return 1;
    }

    char *tmp = ESTRDUP(name);
    bytecode_dir = ESTRDUP(dirname(tmp));
    free(tmp);

    main_unit_name_alloc = extract_unit_name(name);
    name = main_unit_name_alloc;
    main_unit_dir = bytecode_dir;
    include_paths[include_path_count++] = bytecode_dir;
  }

  virtual_machine *vm = vm_create(
      name, main_unit_dir, (const char **)include_paths, include_path_count);
  if (!vm) {
    exit_code = 1;
    goto cleanup;
  }

  // Skip options, pass only program args
  vm_set_args(vm, argc - optind, argv + optind);

  vm_run(vm);

cleanup:
  vm_destroy(vm);
  free(main_unit_name_alloc);
  free(bytecode_dir);
  return exit_code;
}
