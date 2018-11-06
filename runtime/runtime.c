/* Runtime library */

# include <stdio.h>
# include <stdio.h>
# include <malloc.h>
# include <string.h>
# include <stdarg.h>
# include <alloca.h>
# include <stdlib.h>

# define STRING_TAG 0x00000000
# define ARRAY_TAG  0x01000000
# define SEXP_TAG   0x02000000

# define LEN(x) (x & 0x00FFFFFF)
# define TAG(x) (x & 0xFF000000)

# define TO_DATA(x) ((data*)((char*)(x)-sizeof(int)))
# define TO_SEXP(x) ((sexp*)((char*)(x)-2*sizeof(int)))

# define UNBOXED(x) (((int) (x)) & 0x0001)
# define UNBOX(x)   (((int) (x)) >> 1)
# define BOX(x)     ((((int) (x)) << 1) | 0x0001)

typedef struct {
  int tag; 
  char contents[0];
} data; 

typedef struct {
  int tag; 
  data contents; 
} sexp; 

extern int Blength (void *p) {
  data *a = TO_DATA(p);
  return BOX(LEN(a->tag));
}

char* de_hash (int n) {
  static char *chars = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNJPQRSTUVWXYZ";
  static char buf[6];
  char *p = &buf[5];

  /*printf ("tag: %d\n", n);*/
  
  *p-- = 0;

  while (n != 0) {
    /*printf ("char: %c\n", chars [n & 0x003F]);*/
    *p-- = chars [n & 0x003F];
    n = n >> 6;
  }
  
  return ++p;
}

typedef struct {
  char *contents;
  int ptr;
  int len;
} StringBuf;

static StringBuf stringBuf;

# define STRINGBUF_INIT 128

static void createStringBuf () {
  stringBuf.contents = (char*) malloc (STRINGBUF_INIT);
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

static void printStringBuf (char *fmt, ...) {
  va_list args;
  int     written, rest;
  char   *buf;

 again:
  va_start (args, fmt);
  buf     = &stringBuf.contents[stringBuf.ptr];
  rest    = stringBuf.len - stringBuf.ptr;
  written = vsnprintf (buf, rest, fmt, args);
  
  if (written >= rest) {
    extendStringBuf ();
    goto again;
  }

  stringBuf.ptr += written;
}

static void printValue (void *p) {
  if (UNBOXED(p)) printStringBuf ("%d", UNBOX(p));
  else {
    data *a = TO_DATA(p);

    switch (TAG(a->tag)) {      
    case STRING_TAG:
      printStringBuf ("\"%s\"", a->contents);
      break;
      
    case ARRAY_TAG:
      printStringBuf ("[");
      for (int i = 0; i < LEN(a->tag); i++) {
        printValue ((void*)((int*) a->contents)[i]);
	if (i != LEN(a->tag) - 1) printStringBuf (", ");
      }
      printStringBuf ("]");
      break;
      
    case SEXP_TAG:
      printStringBuf ("`%s", de_hash (TO_SEXP(p)->tag));
      if (LEN(a->tag)) {
	printStringBuf (" (");
	for (int i = 0; i < LEN(a->tag); i++) {
	  printValue ((void*)((int*) a->contents)[i]);
	  if (i != LEN(a->tag) - 1) printStringBuf (", ");
	}
	printStringBuf (")");
      }
      break;
      
    default:
      printStringBuf ("*** invalid tag: %x ***", TAG(a->tag));
    }
  }
}

extern void* Belem (void *p, int i) {
  data *a = TO_DATA(p);
  i = UNBOX(i);
  
  /* printf ("elem %d = %p\n", i, (void*) ((int*) a->contents)[i]); */

  if (TAG(a->tag) == STRING_TAG) {
    return (void*) BOX(a->contents[i]);
  }
  
  return (void*) ((int*) a->contents)[i];
}

extern void* Bstring (void *p) {
  int n = strlen (p);
  data *r = (data*) malloc (n + 1 + sizeof (int));

  r->tag = n;
  strncpy (r->contents, p, n + 1);
  
  return r->contents;
}

extern void* Bstringval (void *p) {
  void *s;
  
  createStringBuf ();
  printValue (p);

  s = Bstring (stringBuf.contents);
  
  deleteStringBuf ();

  return s;
}

extern void* Barray (int n, ...) {
  va_list args;
  int i;
  data *r = (data*) malloc (sizeof(int) * (n+1));

  r->tag = ARRAY_TAG | n;
  
  va_start(args, n);
  
  for (i=0; i<n; i++) {
    int ai = va_arg(args, int);
    ((int*)r->contents)[i] = ai; 
  }
  
  va_end(args);

  return r->contents;
}

extern void* Bsexp (int n, ...) {
  va_list args;
  int i;
  sexp *r = (sexp*) malloc (sizeof(int) * (n+2));
  data *d = &(r->contents);

  d->tag = SEXP_TAG | (n-1);
  
  va_start(args, n);
  
  for (i=0; i<n-1; i++) {
    int ai = va_arg(args, int);
    //printf ("arg %d = %x\n", i, ai);
    ((int*)d->contents)[i] = ai; 
  }

  r->tag = va_arg(args, int);
  va_end(args);

  //printf ("tag %d\n", r->tag);
  //printf ("returning %p\n", d->contents);
  
  return d->contents;
}

extern int Btag (void *d, int t) {
  data *r = TO_DATA(d);
  return BOX(TAG(r->tag) == SEXP_TAG && TO_SEXP(d)->tag == t);
}
		 
extern void Bsta (int n, int v, void *s, ...) {
  va_list args;
  int i, k;
  data *a;
  
  va_start(args, s);

  for (i=0; i<n-1; i++) {
    k = UNBOX(va_arg(args, int));
    s = ((int**) s) [k];
  }

  k = UNBOX(va_arg(args, int));
  a = TO_DATA(s);
  
  if (TAG(a->tag) == STRING_TAG)((char*) s)[k] = (char) UNBOX(v);
  else ((int*) s)[k] = v;
}

extern int Lraw (int x) {
  return UNBOX(x);
}

extern void Lprintf (char *s, ...) {
  va_list args;

  va_start (args, s);
  vprintf  (s, args); // vprintf (char *, va_list) <-> printf (char *, ...) 
  va_end   (args);
}

extern void* Lstrcat (void *a, void *b) {
  data *da = TO_DATA(a);
  data *db = TO_DATA(b);
  
  data *d  = (data *) malloc (sizeof(int) + LEN(da->tag) + LEN(db->tag) + 1);

  d->tag = LEN(da->tag) + LEN(db->tag);

  strcpy (d->contents, da->contents);
  strcat (d->contents, db->contents);

  return d->contents;
}

extern void Lfprintf (FILE *f, char *s, ...) {
  va_list args;

  va_start (args, s);
  vfprintf (f, s, args);
  va_end   (args);
}

extern FILE* Lfopen (char *f, char *m) {
  return fopen (f, m);
}

extern void Lfclose (FILE *f) {
  fclose (f);
}
   
/* Lread is an implementation of the "read" construct */
extern int Lread () {
  int result;

  printf ("> "); 
  fflush (stdout);
  scanf  ("%d", &result);

  return BOX(result);
}

/* Lwrite is an implementation of the "write" construct */
extern int Lwrite (int n) {
  printf ("%d\n", UNBOX(n));
  fflush (stdout);

  return 0;
}

