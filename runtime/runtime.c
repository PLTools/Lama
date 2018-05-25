/* Runtime library */

# include <stdio.h>
# include <stdio.h>
# include <malloc.h>
# include <string.h>
# include <stdarg.h>
# include <alloca.h>

# define STRING_TAG 0x00000000
# define ARRAY_TAG  0x01000000
# define SEXP_TAG   0x02000000

# define LEN(x) (x & 0x00FFFFFF)
# define TAG(x) (x & 0xFF000000)

# define TO_DATA(x) ((data*)((char*)(x)-sizeof(int)))
# define TO_SEXP(x) ((sexp*)((char*)(x)-2*sizeof(int)))

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
  return LEN(a->tag);
}

extern void* Belem (void *p, int i) {
  data *a = TO_DATA(p);

  if (TAG(a->tag) == STRING_TAG) return (void*)(int)(a->contents[i]);

  //printf ("elem %d = %p\n", i, (void*) ((int*) a->contents)[i]);
  
  return (void*) ((int*) a->contents)[i];
}

extern void* Bstring (void *p) {
  int n = strlen (p);
  data *r = (data*) malloc (n + 1 + sizeof (int));

  r->tag = n;
  strncpy (r->contents, p, n + 1);
  
  return r->contents;
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
  return TAG(r->tag) == SEXP_TAG && TO_SEXP(d)->tag == t;
}
		 
extern void Bsta (int n, int v, void *s, ...) {
  va_list args;
  int i, k;
  data *a;
  
  va_start(args, s);

  for (i=0; i<n-1; i++) {
    k = va_arg(args, int);
    s = ((int**) s) [k];
  }

  k = va_arg(args, int);
  a = TO_DATA(s);
  
  if (TAG(a->tag) == STRING_TAG)((char*) s)[k] = (char) v;
  else ((int*) s)[k] = v;
}

void Lprintf (char *s, ...) {
  va_list args;

  va_start (args, s);
  vprintf (s, args); // vprintf (char *, va_list) <-> printf (char *, ...) 
  va_end (args);
}

void* Lstrcat (void *a, void *b) {
  data *da = TO_DATA(a);
  data *db = TO_DATA(b);
  
  data *d  = (data *) malloc (sizeof(int) + LEN(da->tag) + LEN(db->tag) + 1);

  d->tag = LEN(da->tag) + LEN(db->tag);

  strcpy (d->contents, da->contents);
  strcat (d->contents, db->contents);

  return d->contents;
}

void Lfprintf (FILE *f, char *s, ...) {
  va_list args;

  va_start (args, s);
  vfprintf (f, s, args);
  va_end (args);
}

FILE* Lfopen (char *f, char *m) {
  return fopen (f, m);
}

void Lfclose (FILE *f) {
  fclose (f);
}
   
/* Lread is an implementation of the "read" construct */
extern int Lread () {
  int result;

  printf ("> "); 
  fflush (stdout);
  scanf  ("%d", &result);

  return result;
}

/* Lwrite is an implementation of the "write" construct */
extern int Lwrite (int n) {
  printf ("%d\n", n);
  fflush (stdout);

  return 0;
}

