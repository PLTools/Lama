/* Runtime library */

# include <stdio.h>
# include <stdio.h>
# include <string.h>
# include <stdarg.h>
# include <stdlib.h>
# include <sys/mman.h>
# include <assert.h>

# define DEBUG_PRINT 1

# define STRING_TAG 0x00000001
# define ARRAY_TAG  0x00000003
# define SEXP_TAG   0x00000005

# define LEN(x) ((x & 0xFFFFFFF8) >> 3)
# define TAG(x) (x & 0x00000007)

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

static void* alloc (size_t);

extern int Blength (void *p) {
  data *a = TO_DATA(p);
  return BOX(LEN(a->tag));
}

char* de_hash (int n) {
  static char *chars = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNJPQRSTUVWXYZ";
  static char buf[6];
  char *p = &buf[5];

#ifdef DEBUG_PRINT
  printf ("de_hash: tag: %d\n", n);
#endif
  
  *p-- = 0;

  while (n != 0) {
#ifdef DEBUG_PRINT
    printf ("char: %c\n", chars [n & 0x003F]);
#endif
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
  
  if (TAG(a->tag) == STRING_TAG) {
    return (void*) BOX(a->contents[i]);
  }
  
  return (void*) ((int*) a->contents)[i];
}

extern void* Bstring (void *p) {
  int n = strlen (p);
  data *r = (data*) alloc (n + 1 + sizeof (int));

  r->tag = STRING_TAG | (n << 3);
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
  int i = 1;
  data *r = NULL;
  printf ("Barray: create n = %d\n", n);
  fflush(stdout);
  r = (data*) alloc (sizeof(int) * (n+1));

  r->tag = ARRAY_TAG | (n << 3);
  
  va_start(args, n);
  
  for (i=0; i<n; i++) {
    int ai = va_arg(args, int);
    ((int*)r->contents)[i] = ai; 
  }
  
  va_end(args);

  return r->contents;
}

extern void* Bsexp (int n, ...) {
  va_list args = (va_list) BOX(NULL);
  int     i    = BOX(0);
  int     ai   = BOX(0);
  sexp   *r    = (sexp*) BOX(NULL);
  data   *d    = (sexp*) BOX(NULL);

#ifdef DEBUG_PRINT
  printf("Bsexp: allocate %zu!\n",sizeof(int) * (n+1));
#endif
  r = (sexp*) alloc (sizeof(int) * (n+1));
  d = &(r->contents);
    
  d->tag = SEXP_TAG | ((n-1) << 3);
  
  va_start(args, n);
  
  for (i=0; i<n-1; i++) {
    ai = va_arg(args, int);
    ((int*)d->contents)[i] = ai; 
  }

  r->tag = va_arg(args, int);
  va_end(args);

  return d->contents;
}

extern int Btag (void *d, int t, int n) {
  data *r = TO_DATA(d);
  return BOX(TAG(r->tag) == SEXP_TAG && TO_SEXP(d)->tag == t && LEN(r->tag) == n);
}

extern int Barray_patt (void *d, int n) {
  if (UNBOXED(d)) return BOX(0);
  else {
    data *r = TO_DATA(d);
    return BOX(TAG(r->tag) == ARRAY_TAG && LEN(r->tag) == n);
  }
}

extern int Bstring_patt (void *x, void *y) {
  if (UNBOXED(x)) return BOX(0);
  else {
    data *rx = TO_DATA(x), *ry = TO_DATA(y);

    if (TAG(rx->tag) != STRING_TAG) return BOX(0);
    
    return BOX(strcmp (rx->contents, ry->contents) == 0 ? 1 : 0);
  }
}

extern int Bboxed_patt (void *x) {
  return BOX(UNBOXED(x) ? 0 : 1);
}

extern int Bunboxed_patt (void *x) {
  return BOX(UNBOXED(x) ? 1 : 0);
}

extern int Barray_tag_patt (void *x) {
  if (UNBOXED(x)) return BOX(0);
  
  return BOX(TAG(TO_DATA(x)->tag) == ARRAY_TAG);
}

extern int Bstring_tag_patt (void *x) {
  if (UNBOXED(x)) return BOX(0);
  
  return BOX(TAG(TO_DATA(x)->tag) == STRING_TAG);
}

extern int Bsexp_tag_patt (void *x) {
  if (UNBOXED(x)) return BOX(0);
  
  return BOX(TAG(TO_DATA(x)->tag) == SEXP_TAG);
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
  
  data *d  = (data *) alloc (sizeof(int) + LEN(da->tag) + LEN(db->tag) + 1);

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

extern int Lwrite2 (size_t* n) {
  printf ("%x\n", n);
  fflush (stdout);

  return 0;
}

/* GC starts here */

extern const size_t __gc_data_end, __gc_data_start;
extern size_t __gc_stack_bottom, __gc_stack_top;

extern void L__gc_init ();
extern void __pre_gc ();

extern void __gc_root_scan_stack ();


/* extern const void * __gc_data_end, * __gc_data_start; */

/* extern void __gc_root_scan_data () { */
/*   void * p = &__gc_data_start; */

/*   printf ("Start, end: %d, %d\n", &__gc_data_start, &__gc_data_end); */
  
/*   while (p != &__gc_data_end) { */
/*     if (!UNBOXED(* (size_t *) p)) printf ("Root: %d\n", p); */
/*     p = p + sizeof(size_t); */
/*   } */
/* } */

extern char __executable_start;
extern char __etext;

/* extern void Ltest () { */
/*   printf("\n"); */
/*   printf("STA 0x%lx\n", (unsigned long)&__executable_start); */
/*   printf("END 0x%lx\n", (unsigned long)&__etext); */
/*   __gc_root_scan_data (); */
/*   __gc_root_scan_stack (); */

/*   //  printf("STA 0x%lx\n", (unsigned long)&__executable_start); */
/*   //  printf("END 0x%lx\n", (unsigned long)&__etext); */
/*   //  printf("RET 0x%lx\n\n", __builtin_return_address(0)); */
/* } */

/* ======================================== */
/*           Mark-and-copy                  */
/* ======================================== */

static size_t SPACE_SIZE = 128;
# define POOL_SIZE (2*SPACE_SIZE)

typedef struct {
  size_t * begin;
  size_t * end;
  size_t * current;
  size_t   size;
} pool;

static pool     from_space;
static pool     to_space;
size_t * current;

static void swap (size_t ** a, size_t ** b) {
  size_t * t = *a;
  *a = *b;
  *b = t;
}

static void __gc_swap_spaces (void) {
  swap (&from_space.begin, &to_space.begin);
  swap (&from_space.end  , &to_space.end  );
  from_space.current = current;
  to_space.current   = to_space.begin;
}

# define IS_VALID_HEAP_POINTER(p)\
  (!UNBOXED(p) &&		 \
   from_space.begin <= p &&	 \
   from_space.end   >  p)

# define IN_PASSIVE_SPACE(p)	\
  (to_space.begin <= p	&&	\
   to_space.end   >  p)

# define IS_FORWARD_PTR(p)			\
  (!UNBOXED(p) && IN_PASSIVE_SPACE(p))

extern size_t * gc_copy (size_t *obj);

/* static void copy_elements (size_t *where, size_t *from, int len) { */
/*   int  i = 0; */
/*   void * p = NULL; */
/*   for (i = 0; i < len; i++) { */
/*     size_t elem = from[i]; */
/*     // if (UNBOXED(elem)) *++where = elem; */
/*     if (!IS_VALID_HEAP_POINTER(elem)) *++where = elem; */
/*     else { */
/*       // *++where = gc_copy ((size_t*) elem); */
/*       p = gc_copy ((size_t*) elem); */
/*       printf ("copy_elements: fix %x --> %x\n", *where, p); */
/*       *where = p; */
/*       where ++; */
/*     } */
/*   } */
/* } */

static void copy_elements (size_t *where, size_t *from, int len) {
  int  i = 0;
  void * p = NULL;
  for (i = 0; i < len; i++) {
    size_t elem = from[i];
    // if (UNBOXED(elem)) *++where = elem;
    if (!IS_VALID_HEAP_POINTER(elem)) {
      // *++where = elem;
      *where = elem;
      where++;
    }
    else {
      // *++where = gc_copy ((size_t*) elem);
      p = gc_copy ((size_t*) elem);
      *where = p;
#ifdef DEBUG_PRINT
      printf ("copy_elements: fix %x: %x\n", from, *where);
#endif
      where ++;
    }
  }
}

static void extend_spaces (void) {
  /* void *from_e = mmap(from_space.end, SPACE_SIZE, PROT_READ | PROT_WRITE, */
  /* 			  MAP_PRIVATE | MAP_ANONYMOUS | MAP_32BIT, -1, 0); */
  /* void *to_e   = mmap(to_space.end  , SPACE_SIZE, PROT_READ | PROT_WRITE, */
  /* 			  MAP_PRIVATE | MAP_ANONYMOUS | MAP_32BIT, -1, 0); */
  void *p1 = mremap(from_space.begin, SPACE_SIZE, 2*SPACE_SIZE, 0);
  void *p2 = mremap(to_space.begin  , SPACE_SIZE, 2*SPACE_SIZE, 0);
  if (p1   == MAP_FAILED || p2 == MAP_FAILED) {
    perror("EROOR: extend_spaces: mmap failed\n");
    exit(7);
  }
#ifdef DEBUG_PRINT
  printf ("extend: %x %x %x %x\n", p1, p2, from_space.begin, to_space.begin);
  printf ("extend: %x %x %x\n", from_space.end, to_space.end, current);
#endif
  from_space.end  += SPACE_SIZE;
  to_space.end    += SPACE_SIZE;
  SPACE_SIZE      += SPACE_SIZE;
  from_space.size =  SPACE_SIZE;
  to_space.size   =  SPACE_SIZE;
}

extern size_t * gc_copy (size_t *obj) {
  data   *d    = TO_DATA(obj);
  sexp   *s    = NULL;
  size_t *copy = NULL;
  int     i    = 0;
#ifdef DEBUG_PRINT
  int len1, len2, len3;
  void * objj;
  void * newobjj = (void*)current;
  printf("gc_copy: %x cur = %x starts\n", obj, current);
#endif

  if (!IS_VALID_HEAP_POINTER(obj)) {
#ifdef DEBUG_PRINT
    printf ("gc_copy: invalid ptr: %x\n", obj);
#endif
    return obj;
  }

  if (!IN_PASSIVE_SPACE(current)) {
#ifdef DEBUG_PRINT
    printf("ERROR: gc_copy: out-of-space %x %x %x\n", current, to_space.begin, to_space.end);
    fflush(stdout);
#endif
    perror("ERROR: gc_copy: out-of-space\n");
    exit (6);
    //    extend_spaces ();
    //    assert (IN_PASSIVE_SPACE(current));
  }

  if (IS_FORWARD_PTR(d->tag)) {
    printf ("gc_copy: IS_FORWARD_PTR: return! %x\n", (size_t *) d->tag);
    fflush(stdout);
    return (size_t *) d->tag;
  }

  copy = current;
#ifdef DEBUG_PRINT
  objj = d;
#endif
  switch (TAG(d->tag)) {
    case ARRAY_TAG:
      printf ("gc_copy:array_tag; len =  %zu\n", LEN(d->tag));
      fflush(stdout);
      current += (LEN(d->tag) + 1) * sizeof (int);
      *copy = d->tag;
      copy++;
      d->tag = (int) copy;
      copy_elements (copy, obj, LEN(d->tag));
      break;
    case STRING_TAG:
      printf ("gc_copy:string_tag \n");
      current += (LEN(d->tag) + 1) * sizeof (int);
      *copy = d->tag;
      copy++;
      d->tag = (int) copy;
      strcpy (&copy[1], (char*) obj);
      break;
    case SEXP_TAG  :
      s = TO_SEXP(obj);
#ifdef DEBUG_PRINT
      objj = s;
      len1 = LEN(s->contents.tag);
      len2 = LEN(s->tag);
      len3 = LEN(d->tag);
      printf("len1 = %li, len2=%li, len3 = %li\n",len1,len2,len3);
#endif
      current += (LEN(s->contents.tag) + 2) * sizeof (int);
      *copy = s->tag;
      copy++;
      *copy   = s->contents.tag;
      copy++;
      i = LEN(s->contents.tag);
      // s->contents.tag = (int) copy;
      d->tag = (int) copy;
      copy_elements (copy, obj, i);
      break;
  default:
#ifdef DEBUG_PRINT
    printf ("ERROR: gc_copy: weird tag: %x", TAG(d->tag));
    fflush(stdout);
#endif
    perror ("ERROR: gc_copy: weird tag");
    exit(5);
  }
#ifdef DEBUG_PRINT
  printf("gc_copy: %x (%x) -> %x (%x)\n", obj, objj, copy, newobjj);
  fflush(stdout);
#endif
  return copy;
}

extern void __gc_test_and_copy_root (size_t ** root) {
  if (IS_VALID_HEAP_POINTER(*root)) {
#ifdef DEBUG_PRINT
    printf ("__gc_test_and_copy_root: root %x %x\n", root, *root);
#endif
    *root = gc_copy (*root);
  }
}

extern void __gc_root_scan_data (void) {
  size_t * p = &__gc_data_start;
  while  (p != &__gc_data_end) {
    __gc_test_and_copy_root (p);
    p++;
  }
}

extern void init_pool (void) {
  from_space.begin = mmap(NULL, SPACE_SIZE, PROT_READ | PROT_WRITE,
			  MAP_PRIVATE | MAP_ANONYMOUS | MAP_32BIT, -1, 0);
  to_space.begin   = mmap(NULL, SPACE_SIZE, PROT_READ | PROT_WRITE,
			  MAP_PRIVATE | MAP_ANONYMOUS | MAP_32BIT, -1, 0);
  if (to_space.begin   == MAP_FAILED ||
      from_space.begin == MAP_FAILED) {
    perror("EROOR: init_pool: mmap failed\n");
    exit(1);
  }
  from_space.current = from_space.begin;
  from_space.end     = from_space.begin + SPACE_SIZE;
  from_space.size    = SPACE_SIZE;
  to_space.current   = to_space.begin;
  to_space.end       = to_space.begin + SPACE_SIZE;
  to_space.size      = SPACE_SIZE;
}

static int free_pool (pool * p) {
  return munmap((void *)p->begin, p->size);
}

static void * gc (size_t size) {
  current = to_space.begin;
#ifdef DEBUG_PRINT
  printf("gc: current: %x; to_space.b = %x; to_space.e = %x; f_space.b = %x; f_space.e = %x\n",
	 current, to_space.begin, to_space.end, from_space.begin, from_space.end);
#endif
  __gc_root_scan_data  ();
#ifdef DEBUG_PRINT
  printf("gc: data is scanned\n");
#endif
  __gc_root_scan_stack ();
  if (!IN_PASSIVE_SPACE(current)) {
    perror ("ASSERT: !IN_PASSIVE_SPACE(current)\n");
    exit(1);
  }

  if (current + size >= to_space.end) {
#ifdef DEBUG_PRINT
    printf ("gc pre-extend_spaces : %x %x %x \n", current, size, to_space.end);
#endif
    extend_spaces ();
#ifdef DEBUG_PRINT
    printf ("gc post-extend_spaces: %x %x %x \n", current, size, to_space.end);
#endif
    assert (IN_PASSIVE_SPACE(current));
    assert (current + size < to_space.end);
    //    perror ("ERROR: gc: out of memory\n");
    //    exit(4);
  }

  __gc_swap_spaces ();
  from_space.current = current + size;
  return current;
}

static void * alloc (size_t size) {
  void * p = BOX(NULL);
  if (from_space.current + size < from_space.end) {
#ifdef DEBUG_PRINT
    printf("alloc: current: %x %zu", from_space.current, size);
#endif
    p = (void*) from_space.current;
    from_space.current += size;
#ifdef DEBUG_PRINT
    printf(";new current: %x \n", from_space.current);
#endif
    return p;
  }
#ifdef DEBUG_PRINT
  printf("alloc: call gc: %zu\n", size);
#endif
  __pre_gc () ;
  return gc (size);
}
