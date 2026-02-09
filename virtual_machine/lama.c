#define _POSIX_C_SOURCE 200809L

#include "../runtime/gc.h"
#include "../runtime/runtime_common.h"
#include "vm.h"
#include <getopt.h>
#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_INCLUDE_PATHS 64

extern void set_args(aint argc, char *argv[]);

static void print_usage(const char *prog_name) {
  printf("Usage: %s [options] <bytecode.bc> [args]\n", prog_name);
  printf("\nWhen no options are specified, the VM will run the bytecode file "
         "and look for modules in the same directory.\n");
  printf("Options:\n");
  printf("  -h, --help              Show this help message\n");
  printf("  -I, --include PATH      Add PATH to module search paths (can be "
         "used multiple times)\n");
}

int main(int argc, char *argv[]) {
  char *include_paths[MAX_INCLUDE_PATHS];
  int include_path_count = 1; // Reserve index 0 for bytecode file's directory
  // TODO: better error handling in general
  int exit_code = 0;
  char *bytecode_dir = NULL;
  search_paths paths = {0};

  static struct option long_options[] = {{"help", no_argument, 0, 'h'},
                                         {"include", required_argument, 0, 'I'},
                                         {0, 0, 0, 0}};

  int opt;
  int option_index = 0;

  while ((opt = getopt_long(argc, argv, "hI:", long_options, &option_index)) !=
         -1) {
    switch (opt) {
    case 'h':
      print_usage(argv[0]);
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
    case '?':
      if (optopt) {
        fprintf(stderr, "Invalid command line specifier ('-%c')\n", optopt);
        return 1;
      }
    default:
      fprintf(stderr, "Invalid command line specifier\n");
      return 1;
    }
  }

  if (optind >= argc) {
    fprintf(stderr, "No bytecode file specified\n\n");
    print_usage(argv[0]);
    return 1;
  }

  char *bytecode_file = argv[optind];

  // Inlcude main module's directory by default
  bytecode_dir = strdup(dirname(bytecode_dir));
  include_paths[0] = bytecode_dir;

  paths.paths = (const char **)include_paths;
  paths.len = include_path_count;

  __gc_init();

  // Skip options, pass only program args
  set_args(argc - optind, argv + optind);

  virtual_machine *vm = vm_create(bytecode_file, &paths);
  if (!vm) {
    exit_code = 1;
    goto cleanup;
  }

  vm_run(vm);

cleanup:
  free(bytecode_dir);
  vm_destroy(vm);
  return exit_code;
}
