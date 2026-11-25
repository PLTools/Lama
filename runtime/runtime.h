#ifndef __LAMA_RUNTIME__
#define __LAMA_RUNTIME__

#include "runtime_common.h"
#include <assert.h>
#include <stdbool.h>
#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <regex.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define WORD_SIZE (CHAR_BIT * sizeof(uintptr_t))

_Noreturn void failure (char *s, ...) __attribute__((format(printf, 1, 2)));

// defined in runtime.c: decodes an S-expression tag hash into its name
char *de_hash (intptr_t);

// the tag hash of a C string (LtagHash, for Lama programs, also checks that s is a Lama string)
intptr_t lama_tag_hash (const char *s);

#endif
