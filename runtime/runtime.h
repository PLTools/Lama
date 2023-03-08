# ifndef __LAMA_RUNTIME__
# define __LAMA_RUNTIME__

# include <stdio.h>
# include <stdio.h>
# include <string.h>
# include <stdarg.h>
# include <stdlib.h>
# include <sys/mman.h>
# include <assert.h>
# include <errno.h>
# include <regex.h>
# include <time.h>
# include <limits.h>
# include <ctype.h>

# define WORD_SIZE (CHAR_BIT * sizeof(int))

# define STRING_TAG  0x00000001
# define ARRAY_TAG   0x00000003
# define SEXP_TAG    0x00000005
# define CLOSURE_TAG 0x00000007
# define UNBOXED_TAG 0x00000009 // Not actually a tag; used to return from LkindOf

# define LEN(x) ((x & 0xFFFFFFF8) >> 3)
# define TAG(x)  (x & 0x00000007)

# define TO_DATA(x) ((data*)((char*)(x)-sizeof(int)))
# define TO_SEXP(x) ((sexp*)((char*)(x)-2*sizeof(int)))

# define UNBOXED(x)  (((int) (x)) &  0x0001)
# define UNBOX(x)    (((int) (x)) >> 1)
# define BOX(x)      ((((int) (x)) << 1) | 0x0001)

void failure (char *s, ...);

typedef struct {
    int tag;
    char contents[0];
} data;

typedef struct {
    int tag;
    data contents;
} sexp;

static char* chars = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'";

extern char* de_hash (int);

typedef struct {
    char *contents;
    int ptr;
    int len;
} StringBuf;

static StringBuf stringBuf;

# define STRINGBUF_INIT 128

static void createStringBuf () {
    stringBuf.contents = (char*) malloc (STRINGBUF_INIT);
    memset(stringBuf.contents, 0, STRINGBUF_INIT);
    stringBuf.ptr      = 0;
    stringBuf.len      = STRINGBUF_INIT;
}

static void deleteStringBuf () {
    free (stringBuf.contents);
}

static void extendStringBuf () {
    int len = stringBuf.len << 1;

    stringBuf.contents = (char*) realloc (stringBuf.contents, len);
    stringBuf.len      = len;
}

static void vprintStringBuf (char *fmt, va_list args) {
    int     written = 0,
            rest    = 0;
    char   *buf     = (char*) BOX(NULL);
    va_list vsnargs;

    again:
    va_copy (vsnargs, args);

    buf     = &stringBuf.contents[stringBuf.ptr];
    rest    = stringBuf.len - stringBuf.ptr;

    written = vsnprintf (buf, rest, fmt, vsnargs);

    va_end(vsnargs);

    if (written >= rest) {
        extendStringBuf ();
        goto again;
    }

    stringBuf.ptr += written;
}

static void printStringBuf (char *fmt, ...) {
    va_list args;

    va_start (args, fmt);
    vprintStringBuf (fmt, args);
}


# endif
