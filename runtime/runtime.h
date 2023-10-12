#ifndef __LAMA_RUNTIME__
#define __LAMA_RUNTIME__

#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <regex.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>

#define WORD_SIZE (CHAR_BIT * sizeof(int))

void failure (char *s, ...);

#endif
