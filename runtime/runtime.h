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

# ifdef __cplusplus
extern "C"{
#endif

void failure (char *s, ...);

extern size_t __gc_stack_top, __gc_stack_bottom;

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

# define STRINGBUF_INIT 128

extern void __init (void);

extern int LtagHash (char *s);
extern int Lread    ();
extern int Lwrite   (int n);
extern int Llength  (void *p);

extern void* Lstring (void *p);

extern void failure (char *s, ...);

extern int Bclosure_tag_patt (void *x);
extern int Bboxed_patt       (void *x);
extern int Bunboxed_patt     (void *x);
extern int Barray_tag_patt   (void *x);
extern int Bstring_tag_patt  (void *x);
extern int Bsexp_tag_patt    (void *x);
extern int Barray_patt       (void *d, int n);
extern int Bstring_patt      (void *x, void *y);

extern int   Btag  (void *d, int t, int n);
extern void* Belem (void *p, int i);
extern void* Bsta  (void *v, int i, void *x);
extern void* Bclosure (int bn, void *entry, ...);

extern void Bmatch_failure (void *v, char *fname, int line, int col);

# ifdef __cplusplus
}
#endif

# endif 
