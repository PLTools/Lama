/* Runtime library */

# include <stdio.h>
# include <stdio.h>
# include <malloc.h>
# include <string.h>
# include <stdarg.h>
# include <alloca.h>

# define STRING_TAG 0x00000000
# define ARRAYU_TAG 0x01000000
# define ARRAYB_TAG 0x02000000

# define LEN(x) (x & 0x00FFFFFF)
# define TAG(x) (x & 0xFF000000)

# define TO_DATA(x) ((data*)((char*)(x)-sizeof(int)))

typedef struct {
  int tag; 
  char contents[0];
} data; 

extern int Blength (void *p) {
  data *a = TO_DATA(p);
  return LEN(a->tag);
}

extern void* Belem (void *p, int i) {
  data *a = TO_DATA(p);

  if (TAG(a->tag) == STRING_TAG) return (void*)(int)(a->contents[i]);
   
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

  r->tag = ARRAYB_TAG | n; //(boxed ? ARRAYB_TAG : ARRAYU_TAG) | size;
  
  va_start(args, n);
  
  for (i=0; i<n; i++) {
    int ai = va_arg(args, int);
    ((int*)r->contents)[i] = ai; 
  }
  
  va_end(args);

  return r->contents;
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

/*
extern void* Lstrdup (void *p) {
  data *s = TO_DATA(p);
  data *r = (data*) malloc (s->tag + sizeof(int) + 1);
  r->tag = s->tag;
  strncpy (r->contents, s->contents, s->tag + 1);
  return r->contents;
}

extern int Lstrget (void *p, int i) {
  data *s = TO_DATA(p);
  return s->contents[i];
}

extern void* Lstrset (void *p, int i, int c) {
  data *s = TO_DATA(p);
  s->contents[i] = c;
  return s;
}

extern void* Lstrcat (void *p1, void *p2) {
  data *s1 = TO_DATA(p1), *s2 = TO_DATA(p2);
  data *r = (data*) malloc (s1->tag + s2->tag + sizeof (int) + 1);
  r->tag = s1->tag + s2->tag;
  strncpy (r->contents, s1->contents, s1->tag);
  strncpy (&(r->contents)[s1->tag], s2->contents, s2->tag+1);
  return r->contents;
} 

extern void* Lstrmake (int n, int c) {
  data *r = (data*) malloc (n + sizeof (int) + 1);
  int i;
  r->tag = n;
  for (i=0; i<n; i++) r->contents[i] = c;
  r->contents[n] = 0;
  return r->contents;
}

extern void* Lstrsub (void *p, int i, int l) {
  data *s = TO_DATA(p);
  data *r = (data*) malloc (l + sizeof (int) + 1);
  r->tag = l;
  strncpy (r->contents, &(s->contents[i]), l);
  r->contents[l] = 0;
  return r->contents; 
}

extern int Lstrcmp (void *p1, void *p2) {
  int i;
  data *s1 = TO_DATA(p1), *s2 = TO_DATA(p2);
  int b = s1->tag < s2->tag ? s1->tag : s2->tag;
  for (i=0; i < b; i++) {
    if (s1->contents[i] < s2->contents[i]) return -1;
    if (s2->contents[i] < s1->contents[i]) return  1;
  }
  if (s1->tag < s2->tag) return -1;
  if (s1->tag > s2->tag) return  1;
  return 0;    
}

extern int Larrlen (void *p) {
  data *a = TO_DATA(p);
  return a->tag & 0x00FFFFFF;
}

extern int L0arrElem (int i, void *p) {
  data *a = TO_DATA(p);
  return ((int*) a->contents)[i];
}

extern void* L0sta (void *s, int n, ...) {
  data *a = TO_DATA(s);
  va_list args;
  int i, k, v;
  data *p = a;

  va_start(args, n);

  for (i=0; i<n-1; i++) {
    k = va_arg(args, int);
    p = (data*) ((int*) p->contents)[k];
  }

  k = va_arg(args, int);
  v = va_arg(args, int);

  ((int*) p->contents)[k] = v;

  va_end(args);

  return p;
}

extern void* L0makeArray (int boxed, int size, ...) {
  va_list args;
  int i;
  data *r = (data*) malloc (sizeof(int)*(size+1));

  r->tag = (boxed ? ARRAYB_TAG : ARRAYU_TAG) | size;
  
  va_start(args, size);
  
  for (i=0; i<size; i++) {
    int ai = va_arg(args, int);
    ((int*)r->contents)[i] = ai; 
  }
  
  va_end(args);

  return r->contents;
}

extern void* L0makeSexp (int tag, int size, ...) {
  va_list args;
  int i;
  data *r = (data*) malloc (sizeof(int)*(size+1));

  r->tag = ((tag+3) << 24) | size;
  
  va_start(args, size);
  
  for (i=0; i<size; i++) {
    int ai = va_arg(args, int);
    ((int*)r->contents)[i] = ai; 
  }
  
  va_end(args);

  return r->contents;
}

extern int Ltag (void *p) {
  data *s = TO_DATA(p);
  int t = ((s->tag & 0xFF000000) >> 24) - 3;
  return t;
}

extern int Ltagcmp (int t1, int t2) {
  return t1 == t2;
}

extern void* Larrmake (int size, int val) {
  data *a = (data*) malloc (sizeof(int)*(size+1));
  int i;

  a->tag = ARRAYU_TAG | size;

  for (i=0; i<size; i++)
    ((int*)a->contents)[i] = val; 

  return a->contents;
}

extern void* LArrmake (int size, void *val) {
  data *a = (data*) malloc (sizeof(int)*(size+1));
  int i;

  a->tag = ARRAYB_TAG | size;

  for (i=0; i<size; i++)
    ((data**)a->contents)[i] = val; 

  return a->contents;
}

extern int Lread () {
  int result;

  printf ("> "); 
  fflush (stdout);
  scanf  ("%d", &result);

  return result;
}

extern int Lwrite (int n) {
  printf ("%d\n", n);
  fflush (stdout);

  return 0;
}

extern int Lprintf (char *format, ...) {
  va_list args;
  int n = Lstrlen ((void*)format);

  va_start (args, format);

  vprintf (format, args);

  va_end (args);

  return 0;
}

extern void* Lfread (char *fname) {
  data *result;
  int size;
  FILE * file;
  int n = Lstrlen ((void*)fname);

  file = fopen (fname, "rb"); 

  fseek (file, 0, SEEK_END);
  size = ftell (file); 
  rewind (file); 

  result = (data*) malloc (size+sizeof(int)+1);
  result->tag = size;

  fread (result->contents, sizeof(char), size, file);
  fclose (file);

  result->contents[size] = 0;

  return result->contents;
}

// New one
*/

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

