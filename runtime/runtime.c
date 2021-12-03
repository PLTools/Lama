/* Runtime library */

# define _GNU_SOURCE 1

# include "runtime.h"

# define __ENABLE_GC__
# ifndef __ENABLE_GC__
# define alloc malloc
# endif

/* # define DEBUG_PRINT 1 */

#ifdef DEBUG_PRINT
int indent = 0;
void print_indent (void) {
  for (int i = 0; i < indent; i++) printf (" ");
  printf("| ");
}
#endif

extern size_t __gc_stack_top, __gc_stack_bottom;

/* GC pool structure and data; declared here in order to allow debug print */
typedef struct {
  size_t * begin;
  size_t * end;
  size_t * current;
  size_t   size;
} pool;

static pool from_space;
static pool to_space;
size_t      *current;
/* end */

# ifdef __ENABLE_GC__

/* GC extern invariant for built-in functions */
extern void __pre_gc  ();
extern void __post_gc ();

# else

# define __pre_gc __pre_gc_subst
# define __post_gc __post_gc_subst

void __pre_gc_subst () {}
void __post_gc_subst () {}

# endif
/* end */

# define STRING_TAG  0x00000001
# define ARRAY_TAG   0x00000003
# define SEXP_TAG    0x00000005
# define CLOSURE_TAG 0x00000007 
# define UNBOXED_TAG 0x00000009 // Not actually a tag; used to return from LkindOf

# define LEN(x) ((x & 0xFFFFFFF8) >> 3)
# define TAG(x)  (x & 0x00000007)

# define TO_DATA(x) ((data*)((char*)(x)-sizeof(int)))
# define TO_SEXP(x) ((sexp*)((char*)(x)-2*sizeof(int)))
# ifdef DEBUG_PRINT // GET_SEXP_TAG is necessary for printing from space
# define GET_SEXP_TAG(x) (LEN(x))
#endif

# define UNBOXED(x)  (((int) (x)) &  0x0001)
# define UNBOX(x)    (((int) (x)) >> 1)
# define BOX(x)      ((((int) (x)) << 1) | 0x0001)

/* GC extra roots */
# define MAX_EXTRA_ROOTS_NUMBER 32
typedef struct {
  int current_free;
  void ** roots[MAX_EXTRA_ROOTS_NUMBER];
} extra_roots_pool;

static extra_roots_pool extra_roots;

void clear_extra_roots (void) {
  extra_roots.current_free = 0;
}

void push_extra_root (void ** p) {
# ifdef DEBUG_PRINT
  indent++; print_indent ();
  printf ("push_extra_root %p %p\n", p, &p); fflush (stdout);
# endif
  if (extra_roots.current_free >= MAX_EXTRA_ROOTS_NUMBER) {
    perror ("ERROR: push_extra_roots: extra_roots_pool overflow");
    exit   (1);
  }
  extra_roots.roots[extra_roots.current_free] = p;
  extra_roots.current_free++;
# ifdef DEBUG_PRINT
  indent--;
# endif
}

void pop_extra_root (void ** p) {
# ifdef DEBUG_PRINT
  indent++; print_indent ();
  printf ("pop_extra_root %p %p\n", p, &p); fflush (stdout);
# endif
  if (extra_roots.current_free == 0) {
    perror ("ERROR: pop_extra_root: extra_roots are empty");
    exit   (1);
  }
  extra_roots.current_free--;
  if (extra_roots.roots[extra_roots.current_free] != p) {
# ifdef DEBUG_PRINT
    print_indent ();
    printf ("%i %p %p", extra_roots.current_free,
	    extra_roots.roots[extra_roots.current_free], p);
    fflush (stdout);
# endif
    perror ("ERROR: pop_extra_root: stack invariant violation");
    exit   (1);
  }
# ifdef DEBUG_PRINT
  indent--;
# endif
}

/* end */

static void vfailure (char *s, va_list args) {
  fprintf  (stderr, "*** FAILURE: ");
  vfprintf (stderr, s, args); // vprintf (char *, va_list) <-> printf (char *, ...)
  exit     (255);
}

void failure (char *s, ...) {
  va_list args;

  va_start (args, s);
  vfailure (s, args);
}

void Lassert (void *f, char *s, ...) {
  if (!UNBOX(f)) {
    va_list args;

    va_start (args, s);
    vfailure (s, args);    
  }
}

# define ASSERT_BOXED(memo, x)               \
  do if (UNBOXED(x)) failure ("boxed value expected in %s\n", memo); while (0)
# define ASSERT_UNBOXED(memo, x)             \
  do if (!UNBOXED(x)) failure ("unboxed value expected in %s\n", memo); while (0)
# define ASSERT_STRING(memo, x)              \
  do if (!UNBOXED(x) && TAG(TO_DATA(x)->tag) \
	 != STRING_TAG) failure ("string value expected in %s\n", memo); while (0)

typedef struct {
  int tag; 
  char contents[0];
} data; 

typedef struct {
  int tag; 
  data contents; 
} sexp;

extern void* alloc    (size_t);
extern void* Bsexp    (int n, ...);
extern int   LtagHash (char*);

void *global_sysargs;

// Gets a raw tag
extern int LkindOf (void *p) {
  if (UNBOXED(p)) return UNBOXED_TAG;
  
  return TAG(TO_DATA(p)->tag);
}

// Compare sexprs tags
extern int LcompareTags (void *p, void *q) {
  data *pd, *qd;
  
  ASSERT_BOXED ("compareTags, 0", p);
  ASSERT_BOXED ("compareTags, 1", q);

  pd = TO_DATA(p);
  qd = TO_DATA(q);

  if (TAG(pd->tag) == SEXP_TAG && TAG(qd->tag) == SEXP_TAG) {
    return
    #ifndef DEBUG_PRINT
      BOX((TO_SEXP(p)->tag) - (TO_SEXP(q)->tag));
    #else
      BOX((GET_SEXP_TAG(TO_SEXP(p)->tag)) - (GET_SEXP_TAG(TO_SEXP(p)->tag)));
    #endif      
  }
  else failure ("not a sexpr in compareTags: %d, %d\n", TAG(pd->tag), TAG(qd->tag));    
          
  return 0; // never happens
}

// Functional synonym for built-in operator ":";
void* Ls__Infix_58 (void *p, void *q) {
  void *res;
  
  __pre_gc ();

  push_extra_root(&p);
  push_extra_root(&q);
  res = Bsexp (BOX(3), p, q, LtagHash ("cons")); //BOX(848787));
  pop_extra_root(&q);
  pop_extra_root(&p);

  __post_gc ();

  return res;
}

// Functional synonym for built-in operator "!!";
int Ls__Infix_3333 (void *p, void *q) {
  ASSERT_UNBOXED("captured !!:1", p);
  ASSERT_UNBOXED("captured !!:2", q);

  return BOX(UNBOX(p) || UNBOX(q));
}

// Functional synonym for built-in operator "&&";
int Ls__Infix_3838 (void *p, void *q) {
  ASSERT_UNBOXED("captured &&:1", p);
  ASSERT_UNBOXED("captured &&:2", q);

  return BOX(UNBOX(p) && UNBOX(q));
}

// Functional synonym for built-in operator "==";
int Ls__Infix_6161 (void *p, void *q) {
  return BOX(p == q);
}

// Functional synonym for built-in operator "!=";
int Ls__Infix_3361 (void *p, void *q) {
  ASSERT_UNBOXED("captured !=:1", p);
  ASSERT_UNBOXED("captured !=:2", q);

  return BOX(UNBOX(p) != UNBOX(q));
}

// Functional synonym for built-in operator "<=";
int Ls__Infix_6061 (void *p, void *q) {
  ASSERT_UNBOXED("captured <=:1", p);
  ASSERT_UNBOXED("captured <=:2", q);

  return BOX(UNBOX(p) <= UNBOX(q));
}

// Functional synonym for built-in operator "<";
int Ls__Infix_60 (void *p, void *q) {
  ASSERT_UNBOXED("captured <:1", p);
  ASSERT_UNBOXED("captured <:2", q);

  return BOX(UNBOX(p) < UNBOX(q));
}

// Functional synonym for built-in operator ">=";
int Ls__Infix_6261 (void *p, void *q) {
  ASSERT_UNBOXED("captured >=:1", p);
  ASSERT_UNBOXED("captured >=:2", q);

  return BOX(UNBOX(p) >= UNBOX(q));
}

// Functional synonym for built-in operator ">";
int Ls__Infix_62 (void *p, void *q) {
  ASSERT_UNBOXED("captured >:1", p);
  ASSERT_UNBOXED("captured >:2", q);

  return BOX(UNBOX(p) > UNBOX(q));
}

// Functional synonym for built-in operator "+";
int Ls__Infix_43 (void *p, void *q) {
  ASSERT_UNBOXED("captured +:1", p);
  ASSERT_UNBOXED("captured +:2", q);

  return BOX(UNBOX(p) + UNBOX(q));
}

// Functional synonym for built-in operator "-";
int Ls__Infix_45 (void *p, void *q) {
  if (UNBOXED(p)) {
    ASSERT_UNBOXED("captured -:2", q);
    return BOX(UNBOX(p) - UNBOX(q));
  }

  ASSERT_BOXED("captured -:1", q);
  return BOX(p - q);
}

// Functional synonym for built-in operator "*";
int Ls__Infix_42 (void *p, void *q) {
  ASSERT_UNBOXED("captured *:1", p);
  ASSERT_UNBOXED("captured *:2", q);

  return BOX(UNBOX(p) * UNBOX(q));
}

// Functional synonym for built-in operator "/";
int Ls__Infix_47 (void *p, void *q) {
  ASSERT_UNBOXED("captured /:1", p);
  ASSERT_UNBOXED("captured /:2", q);

  return BOX(UNBOX(p) / UNBOX(q));
}

// Functional synonym for built-in operator "%";
int Ls__Infix_37 (void *p, void *q) {
  ASSERT_UNBOXED("captured %:1", p);
  ASSERT_UNBOXED("captured %:2", q);

  return BOX(UNBOX(p) % UNBOX(q));
}

extern int Llength (void *p) {
  data *a = (data*) BOX (NULL);
  
  ASSERT_BOXED(".length", p);
  
  a = TO_DATA(p);
  return BOX(LEN(a->tag));
}

static char* chars = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'";

extern char* de_hash (int);

extern int LtagHash (char *s) {
  char *p;
  int  h = 0, limit = 0;
               
  p = s;

  while (*p && limit++ < 4) {
    char *q = chars;
    int pos = 0;
    
    for (; *q && *q != *p; q++, pos++);

    if (*q) h = (h << 6) | pos;    
    else failure ("tagHash: character not found: %c\n", *p);

    p++;
  }

  if (strcmp (s, de_hash (h)) != 0) {
    failure ("%s <-> %s\n", s, de_hash(h));
  }
  
  return BOX(h);
}

char* de_hash (int n) {
  //  static char *chars = (char*) BOX (NULL);
  static char buf[6] = {0,0,0,0,0,0};
  char *p = (char *) BOX (NULL);
  p = &buf[5];

#ifdef DEBUG_PRINT
  indent++; print_indent ();
  printf ("de_hash: tag: %d\n", n); fflush (stdout);
#endif
  
  *p-- = 0;

  while (n != 0) {
#ifdef DEBUG_PRINT
    print_indent ();
    printf ("char: %c\n", chars [n & 0x003F]); fflush (stdout);
#endif
    *p-- = chars [n & 0x003F];
    n = n >> 6;
  }

#ifdef DEBUG_PRINT
  indent--;
#endif
  
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

int is_valid_heap_pointer (void *p);

static void printValue (void *p) {
  data *a = (data*) BOX(NULL);
  int i   = BOX(0);
  if (UNBOXED(p)) printStringBuf ("%d", UNBOX(p));
  else {
    if (! is_valid_heap_pointer(p)) {
      printStringBuf ("0x%x", p);
      return;
    }
    
    a = TO_DATA(p);

    switch (TAG(a->tag)) {      
    case STRING_TAG:
      printStringBuf ("\"%s\"", a->contents);
      break;

    case CLOSURE_TAG:
      printStringBuf ("<closure ");
      for (i = 0; i < LEN(a->tag); i++) {
	if (i) printValue ((void*)((int*) a->contents)[i]);
	else printStringBuf ("0x%x", (void*)((int*) a->contents)[i]);
	
	if (i != LEN(a->tag) - 1) printStringBuf (", ");
      }
      printStringBuf (">");
      break;
      
    case ARRAY_TAG:
      printStringBuf ("[");
      for (i = 0; i < LEN(a->tag); i++) {
        printValue ((void*)((int*) a->contents)[i]);
	if (i != LEN(a->tag) - 1) printStringBuf (", ");
      }
      printStringBuf ("]");
      break;
      
    case SEXP_TAG: {
#ifndef DEBUG_PRINT
      char * tag = de_hash (TO_SEXP(p)->tag);
#else
      char * tag = de_hash (GET_SEXP_TAG(TO_SEXP(p)->tag));
#endif      
      
      if (strcmp (tag, "cons") == 0) {
	data *b = a;
	
	printStringBuf ("{");

	while (LEN(a->tag)) {
	  printValue ((void*)((int*) b->contents)[0]);
	  b = (data*)((int*) b->contents)[1];
	  if (! UNBOXED(b)) {
	    printStringBuf (", ");
	    b = TO_DATA(b);
	  }
	  else break;
	}
	
	printStringBuf ("}");
      }
      else {
	printStringBuf ("%s", tag);
	if (LEN(a->tag)) {
	  printStringBuf (" (");
	  for (i = 0; i < LEN(a->tag); i++) {
	    printValue ((void*)((int*) a->contents)[i]);
	    if (i != LEN(a->tag) - 1) printStringBuf (", ");
	  }
	  printStringBuf (")");
	}
      }
    }
    break;

    default:
      printStringBuf ("*** invalid tag: 0x%x ***", TAG(a->tag));
    }
  }
}

static void stringcat (void *p) {
  data *a;
  int i;
  
  if (UNBOXED(p)) ;
  else {
    a = TO_DATA(p);

    switch (TAG(a->tag)) {      
    case STRING_TAG:
      printStringBuf ("%s", a->contents);
      break;
      
    case SEXP_TAG: {
#ifndef DEBUG_PRINT
      char * tag = de_hash (TO_SEXP(p)->tag);
#else
      char * tag = de_hash (GET_SEXP_TAG(TO_SEXP(p)->tag));
#endif   
      if (strcmp (tag, "cons") == 0) {
	data *b = a;
	
	while (LEN(a->tag)) {
	  stringcat ((void*)((int*) b->contents)[0]);
	  b = (data*)((int*) b->contents)[1];
	  if (! UNBOXED(b)) {
	    b = TO_DATA(b);
	  }
	  else break;
	}
      }
      else printStringBuf ("*** non-list tag: %s ***", tag);
    }
    break;

    default:
      printStringBuf ("*** invalid tag: 0x%x ***", TAG(a->tag));
    }
  }
}

extern int Luppercase (void *v) {
  ASSERT_UNBOXED("Luppercase:1", v);
  return BOX(toupper ((int) UNBOX(v)));
}

extern int Llowercase (void *v) {
  ASSERT_UNBOXED("Llowercase:1", v);
  return BOX(tolower ((int) UNBOX(v)));
}

extern int LmatchSubString (char *subj, char *patt, int pos) {
  data *p = TO_DATA(patt), *s = TO_DATA(subj);
  int   n;

  ASSERT_STRING("matchSubString:1", subj);
  ASSERT_STRING("matchSubString:2", patt);
  ASSERT_UNBOXED("matchSubString:3", pos);
  
  n = LEN (p->tag);

  if (n + UNBOX(pos) > LEN(s->tag))
    return BOX(0);
  
  return BOX(strncmp (subj + UNBOX(pos), patt, n) == 0);
}

extern void* Lsubstring (void *subj, int p, int l) {
  data *d = TO_DATA(subj);
  int pp = UNBOX (p), ll = UNBOX (l);

  ASSERT_STRING("substring:1", subj);
  ASSERT_UNBOXED("substring:2", p);
  ASSERT_UNBOXED("substring:3", l);
      
  if (pp + ll <= LEN(d->tag)) {
    data *r;
    
    __pre_gc ();

    push_extra_root (&subj);
    r = (data*) alloc (ll + 1 + sizeof (int));
    pop_extra_root (&subj);

    r->tag = STRING_TAG | (ll << 3);

    strncpy (r->contents, (char*) subj + pp, ll);
    
    __post_gc ();

    return r->contents;    
  }
  
  failure ("substring: index out of bounds (position=%d, length=%d, \
            subject length=%d)", pp, ll, LEN(d->tag));
}

extern struct re_pattern_buffer *Lregexp (char *regexp) {
  regex_t *b = (regex_t*) malloc (sizeof (regex_t));

  memset (b, 0, sizeof (regex_t));
  
  int n = (int) re_compile_pattern (regexp, strlen (regexp), b);
  
  if (n != 0) {
    failure ("%", strerror (n));
  };

  return b;
}

extern int LregexpMatch (struct re_pattern_buffer *b, char *s, int pos) {
  int res;
  
  ASSERT_BOXED("regexpMatch:1", b);
  ASSERT_STRING("regexpMatch:2", s);
  ASSERT_UNBOXED("regexpMatch:3", pos);

  res = re_match (b, s, LEN(TO_DATA(s)->tag), UNBOX(pos), 0);

  if (res) {
    return BOX (res);
  }

  return BOX (res);
}

extern void* Bstring (void*);

void *Lclone (void *p) {
  data *obj;
  sexp *sobj;
  void* res;
  int n;
#ifdef DEBUG_PRINT
  register int * ebp asm ("ebp");
  indent++; print_indent ();
  printf ("Lclone arg: %p %p\n", &p, p); fflush (stdout);
#endif
  __pre_gc ();
  
  if (UNBOXED(p)) return p;
  else {
    data *a = TO_DATA(p);
    int t   = TAG(a->tag), l = LEN(a->tag);

    push_extra_root (&p);
    switch (t) {
    case STRING_TAG:
#ifdef DEBUG_PRINT
      print_indent ();
      printf ("Lclone: string1 &p=%p p=%p\n", &p, p); fflush (stdout);
#endif
      res = Bstring (TO_DATA(p)->contents);
#ifdef DEBUG_PRINT
      print_indent ();
      printf ("Lclone: string2 %p %p\n", &p, p); fflush (stdout);
#endif
      break;

    case ARRAY_TAG:      
    case CLOSURE_TAG:
#ifdef DEBUG_PRINT
      print_indent ();
      printf ("Lclone: closure or array &p=%p p=%p ebp=%p\n", &p, p, ebp); fflush (stdout);
#endif
      obj = (data*) alloc (sizeof(int) * (l+1));
      memcpy (obj, TO_DATA(p), sizeof(int) * (l+1));
      res = (void*) (obj->contents);
      break;
      
    case SEXP_TAG:
#ifdef DEBUG_PRINT
      print_indent (); printf ("Lclone: sexp\n"); fflush (stdout);
#endif
      sobj = (sexp*) alloc (sizeof(int) * (l+2));
      memcpy (sobj, TO_SEXP(p), sizeof(int) * (l+2));
      res = (void*) sobj->contents.contents;
      break;
       
    default:
      failure ("invalid tag %d in clone *****\n", t);
    }
    pop_extra_root (&p);
  }
#ifdef DEBUG_PRINT
  print_indent (); printf ("Lclone ends1\n"); fflush (stdout);
#endif

  __post_gc ();
#ifdef DEBUG_PRINT
  print_indent ();
  printf ("Lclone ends2\n"); fflush (stdout);
  indent--;
#endif
  return res;
}

# define HASH_DEPTH 3
# define HASH_APPEND(acc, x) (((acc + (unsigned) x) << (WORD_SIZE / 2)) | ((acc + (unsigned) x) >> (WORD_SIZE / 2)))

int inner_hash (int depth, unsigned acc, void *p) {
  if (depth > HASH_DEPTH) return acc;

  if (UNBOXED(p)) return HASH_APPEND(acc, UNBOX(p));
  else if (is_valid_heap_pointer (p)) {
    data *a = TO_DATA(p);
    int t = TAG(a->tag), l = LEN(a->tag), i;

    acc = HASH_APPEND(acc, t);
    acc = HASH_APPEND(acc, l);    

    switch (t) {
    case STRING_TAG: {
      char *p = a->contents;

      while (*p) {
        int n = (int) *p++;
	acc = HASH_APPEND(acc, n);
      }

      return acc;
    }
      
    case CLOSURE_TAG:
      acc = HASH_APPEND(acc, ((void**) a->contents)[0]);
      i = 1;
      break;
      
    case ARRAY_TAG:
      i = 0;
      break;

    case SEXP_TAG: {
#ifndef DEBUG_PRINT
      int ta = TO_SEXP(p)->tag;
#else
      int ta = GET_SEXP_TAG(TO_SEXP(p)->tag);
#endif
      acc = HASH_APPEND(acc, ta);
      i = 0;
      break;
    }

    default:
      failure ("invalid tag %d in hash *****\n", t);
    }

    for (; i<l; i++) 
      acc = inner_hash (depth+1, acc, ((void**) a->contents)[i]);

    return acc;
  }
  else return HASH_APPEND(acc, p);
}

extern void* LstringInt (char *b) {
  int n;
  sscanf (b, "%d", &n);
  return (void*) BOX(n);
}

extern int Lhash (void *p) {
  return BOX(0x3fffff & inner_hash (0, 0, p));
}

extern int LflatCompare (void *p, void *q) {
  if (UNBOXED(p)) {
    if (UNBOXED(q)) {
      return BOX (UNBOX(p) - UNBOX(q));
    }
    
    return -1;
  }
  else if (~UNBOXED(q)) {
    return BOX(p - q);
  }
  else BOX(1);
}

extern int Lcompare (void *p, void *q) {
# define COMPARE_AND_RETURN(x,y) do if (x != y) return BOX(x - y); while (0)
  
  if (p == q) return BOX(0);
 
  if (UNBOXED(p)) {
    if (UNBOXED(q)) return BOX(UNBOX(p) - UNBOX(q));    
    else return BOX(-1);
  }
  else if (UNBOXED(q)) return BOX(1);
  else {
    if (is_valid_heap_pointer (p)) {
      if (is_valid_heap_pointer (q)) {
        data *a = TO_DATA(p), *b = TO_DATA(q);
        int ta = TAG(a->tag), tb = TAG(b->tag);
        int la = LEN(a->tag), lb = LEN(b->tag);
        int i;
    
        COMPARE_AND_RETURN (ta, tb);
      
        switch (ta) {
        case STRING_TAG:
          return BOX(strcmp (a->contents, b->contents));
      
        case CLOSURE_TAG:
          COMPARE_AND_RETURN (((void**) a->contents)[0], ((void**) b->contents)[0]);
          COMPARE_AND_RETURN (la, lb);
          i = 1;
          break;
      
        case ARRAY_TAG:
          COMPARE_AND_RETURN (la, lb);
          i = 0;
          break;

        case SEXP_TAG: {
#ifndef DEBUG_PRINT
          int ta = TO_SEXP(p)->tag, tb = TO_SEXP(q)->tag;      
#else
          int ta = GET_SEXP_TAG(TO_SEXP(p)->tag), tb = GET_SEXP_TAG(TO_SEXP(q)->tag);
#endif      
          COMPARE_AND_RETURN (ta, tb);
          COMPARE_AND_RETURN (la, lb);
          i = 0;
          break;
        }

        default:
          failure ("invalid tag %d in compare *****\n", ta);
        }

        for (; i<la; i++) {
          int c = Lcompare (((void**) a->contents)[i], ((void**) b->contents)[i]);
          if (c != BOX(0)) return BOX(c);
        }
    
        return BOX(0);
      }
      else return BOX(-1);
    }
    else if (is_valid_heap_pointer (q)) return BOX(1);
    else return BOX (p - q);
  }
}

extern void* Belem (void *p, int i) {
  data *a = (data *)BOX(NULL);

  ASSERT_BOXED(".elem:1", p);
  ASSERT_UNBOXED(".elem:2", i);
  
  a = TO_DATA(p);
  i = UNBOX(i);
  
  if (TAG(a->tag) == STRING_TAG) {
    return (void*) BOX(a->contents[i]);
  }
  
  return (void*) ((int*) a->contents)[i];
}

extern void* LmakeArray (int length) {
  data *r;
  int n;

  ASSERT_UNBOXED("makeArray:1", length);
  
  __pre_gc ();

  n = UNBOX(length);
  r = (data*) alloc (sizeof(int) * (n+1));

  r->tag = ARRAY_TAG | (n << 3);

  memset (r->contents, 0, n * sizeof(int));
  
  __post_gc ();

  return r->contents;
}

extern void* LmakeString (int length) {
  int   n = UNBOX(length);
  data *r;

  ASSERT_UNBOXED("makeString", length);
  
  __pre_gc () ;
  
  r = (data*) alloc (n + 1 + sizeof (int));

  r->tag = STRING_TAG | (n << 3);

  __post_gc();
  
  return r->contents;
}

extern void* Bstring (void *p) {
  int   n = strlen (p);
  data *s = NULL;
  
  __pre_gc ();
#ifdef DEBUG_PRINT
  indent++; print_indent ();
  printf ("Bstring: call LmakeString %s %p %p %p %i\n", p, &p, p, s, n);
  fflush(stdout);
#endif
  push_extra_root (&p);
  s = LmakeString (BOX(n));  
  pop_extra_root(&p);
#ifdef DEBUG_PRINT
  print_indent ();
  printf ("\tBstring: call strncpy: %p %p %p %i\n", &p, p, s, n); fflush(stdout);
#endif
  strncpy ((char*)s, p, n + 1);
#ifdef DEBUG_PRINT
  print_indent ();
  printf ("\tBstring: ends\n"); fflush(stdout);
  indent--;
#endif
  __post_gc ();
  
  return s;
}

extern void* Lstringcat (void *p) {
  void *s;

  /* ASSERT_BOXED("stringcat", p); */
  
  __pre_gc ();
  
  createStringBuf ();
  stringcat (p);

  push_extra_root(&p);
  s = Bstring (stringBuf.contents);
  pop_extra_root(&p);
  
  deleteStringBuf ();

  __post_gc ();

  return s;  
}

extern void* Lstring (void *p) {
  void *s = (void *) BOX (NULL);

  __pre_gc () ;
  
  createStringBuf ();
  printValue (p);

  push_extra_root(&p);
  s = Bstring (stringBuf.contents);
  pop_extra_root(&p);
  
  deleteStringBuf ();

  __post_gc ();

  return s;
}

extern void* Bclosure (int bn, void *entry, ...) {
  va_list args; 
  int     i, ai;
  register int * ebp asm ("ebp");
  size_t  *argss;
  data    *r; 
  int     n = UNBOX(bn);
  
  __pre_gc ();
#ifdef DEBUG_PRINT
  indent++; print_indent ();
  printf ("Bclosure: create n = %d\n", n); fflush(stdout);
#endif
  argss = (ebp + 12);
  for (i = 0; i<n; i++, argss++) {
    push_extra_root ((void**)argss);
  }

  r = (data*) alloc (sizeof(int) * (n+2));
  
  r->tag = CLOSURE_TAG | ((n + 1) << 3);
  ((void**) r->contents)[0] = entry;
  
  va_start(args, entry);
  
  for (i = 0; i<n; i++) {
    ai = va_arg(args, int);
    ((int*)r->contents)[i+1] = ai;
  }
  
  va_end(args);

  __post_gc();

  argss--;
  for (i = 0; i<n; i++, argss--) {
    pop_extra_root ((void**)argss);
  }

#ifdef DEBUG_PRINT
  print_indent ();
  printf ("Bclosure: ends\n", n); fflush(stdout);
  indent--;
#endif

  return r->contents;
}

extern void* Barray (int bn, ...) {
  va_list args; 
  int     i, ai; 
  data    *r; 
  int     n = UNBOX(bn);
    
  __pre_gc ();
  
#ifdef DEBUG_PRINT
  indent++; print_indent ();
  printf ("Barray: create n = %d\n", n); fflush(stdout);
#endif
  r = (data*) alloc (sizeof(int) * (n+1));

  r->tag = ARRAY_TAG | (n << 3);
  
  va_start(args, bn);
  
  for (i = 0; i<n; i++) {
    ai = va_arg(args, int);
    ((int*)r->contents)[i] = ai;
  }
  
  va_end(args);

  __post_gc();
#ifdef DEBUG_PRINT
  indent--;
#endif
  return r->contents;
}

extern void* Bsexp (int bn, ...) {
  va_list args; 
  int     i;    
  int     ai;  
  size_t *p;  
  sexp   *r;  
  data   *d;  
  int n = UNBOX(bn); 

  __pre_gc () ;
  
#ifdef DEBUG_PRINT
  indent++; print_indent ();
  printf("Bsexp: allocate %zu!\n",sizeof(int) * (n+1)); fflush (stdout);
#endif
  r = (sexp*) alloc (sizeof(int) * (n+1));
  d = &(r->contents);
  r->tag = 0;
    
  d->tag = SEXP_TAG | ((n-1) << 3);
  
  va_start(args, bn);
  
  for (i=0; i<n-1; i++) {
    ai = va_arg(args, int);
    
    p = (size_t*) ai;
    ((int*)d->contents)[i] = ai;
  }

  r->tag = UNBOX(va_arg(args, int));

#ifdef DEBUG_PRINT
  r->tag = SEXP_TAG | ((r->tag) << 3);
  print_indent ();
  printf("Bsexp: ends\n"); fflush (stdout);
  indent--;
#endif

  va_end(args);

  __post_gc();

  return d->contents;
}

extern int Btag (void *d, int t, int n) {
  data *r; 
  
  if (UNBOXED(d)) return BOX(0);
  else {
    r = TO_DATA(d);
#ifndef DEBUG_PRINT
    return BOX(TAG(r->tag) == SEXP_TAG && TO_SEXP(d)->tag == UNBOX(t) && LEN(r->tag) == UNBOX(n));
#else
    return BOX(TAG(r->tag) == SEXP_TAG &&
               GET_SEXP_TAG(TO_SEXP(d)->tag) == UNBOX(t) && LEN(r->tag) == UNBOX(n));
#endif
  }
}

extern int Barray_patt (void *d, int n) {
  data *r; 
  
  if (UNBOXED(d)) return BOX(0);
  else {
    r = TO_DATA(d);
    return BOX(TAG(r->tag) == ARRAY_TAG && LEN(r->tag) == UNBOX(n));
  }
}

extern int Bstring_patt (void *x, void *y) {
  data *rx = (data *) BOX (NULL),
       *ry = (data *) BOX (NULL);
  
  ASSERT_STRING(".string_patt:2", y);
      
  if (UNBOXED(x)) return BOX(0);
  else {
    rx = TO_DATA(x); ry = TO_DATA(y);

    if (TAG(rx->tag) != STRING_TAG) return BOX(0);
    
    return BOX(strcmp (rx->contents, ry->contents) == 0 ? 1 : 0);
  }
}

extern int Bclosure_tag_patt (void *x) {
  if (UNBOXED(x)) return BOX(0);
  
  return BOX(TAG(TO_DATA(x)->tag) == CLOSURE_TAG);
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

extern void* Bsta (void *v, int i, void *x) {
  if (UNBOXED(i)) {
    ASSERT_BOXED(".sta:3", x);
    //    ASSERT_UNBOXED(".sta:2", i);
  
    if (TAG(TO_DATA(x)->tag) == STRING_TAG)((char*) x)[UNBOX(i)] = (char) UNBOX(v);
    else ((int*) x)[UNBOX(i)] = (int) v;

    return v;
  }

  * (void**) x = v;

  return v;
}

static void fix_unboxed (char *s, va_list va) {
  size_t *p = (size_t*)va;
  int i = 0;
  
  while (*s) {
    if (*s == '%') {
      size_t n = p [i];
      if (UNBOXED (n)) {
	p[i] = UNBOX(n);
      }
      i++;
    }
    s++;
  } 
}

extern void Lfailure (char *s, ...) {
  va_list args;
  
  va_start    (args, s);
  fix_unboxed (s, args);
  vfailure    (s, args);
}

extern void Bmatch_failure (void *v, char *fname, int line, int col) {
  createStringBuf ();
  printValue (v);
  failure ("match failure at %s:%d:%d, value '%s'\n",
	   fname, UNBOX(line), UNBOX(col), stringBuf.contents);
}

extern void* /*Lstrcat*/ Li__Infix_4343 (void *a, void *b) {
  data *da = (data*) BOX (NULL);
  data *db = (data*) BOX (NULL);
  data *d  = (data*) BOX (NULL);

  ASSERT_STRING("++:1", a);
  ASSERT_STRING("++:2", b);
  
  da = TO_DATA(a);
  db = TO_DATA(b);

  __pre_gc () ;

  push_extra_root (&a);
  push_extra_root (&b);
  d  = (data *) alloc (sizeof(int) + LEN(da->tag) + LEN(db->tag) + 1);
  pop_extra_root (&b);
  pop_extra_root (&a);

  da = TO_DATA(a);
  db = TO_DATA(b);
  
  d->tag = STRING_TAG | ((LEN(da->tag) + LEN(db->tag)) << 3);

  strncpy (d->contents               , da->contents, LEN(da->tag));
  strncpy (d->contents + LEN(da->tag), db->contents, LEN(db->tag));
  
  d->contents[LEN(da->tag) + LEN(db->tag)] = 0;

  __post_gc();
  
  return d->contents;
}

extern void* Lsprintf (char * fmt, ...) {
  va_list args;
  void *s;

  ASSERT_STRING("sprintf:1", fmt);
  
  va_start (args, fmt);
  fix_unboxed (fmt, args);
  
  createStringBuf ();

  vprintStringBuf (fmt, args);

  __pre_gc ();

  push_extra_root ((void**)&fmt);
  s = Bstring (stringBuf.contents);
  pop_extra_root ((void**)&fmt);

  __post_gc ();
  
  deleteStringBuf ();

  return s;
}

extern void* LgetEnv (char *var) {
  char *e = getenv (var);
  void *s;
  
  if (e == NULL)
    return BOX(0);

  __pre_gc ();

  s = Bstring (e);

  __post_gc ();

  return s;
}

extern int Lsystem (char *cmd) {
  return BOX (system (cmd));
}

extern void Lfprintf (FILE *f, char *s, ...) {
  va_list args = (va_list) BOX (NULL);

  ASSERT_BOXED("fprintf:1", f);
  ASSERT_STRING("fprintf:2", s);  
  
  va_start    (args, s);
  fix_unboxed (s, args);
  
  if (vfprintf (f, s, args) < 0) {
    failure ("fprintf (...): %s\n", strerror (errno));
  }
}

extern void Lprintf (char *s, ...) {
  va_list args = (va_list) BOX (NULL);

  ASSERT_STRING("printf:1", s);

  va_start    (args, s);
  fix_unboxed (s, args);
  
  if (vprintf (s, args) < 0) {
    failure ("fprintf (...): %s\n", strerror (errno));
  }

  fflush (stdout);
}

extern FILE* Lfopen (char *f, char *m) {
  FILE* h;

  ASSERT_STRING("fopen:1", f);
  ASSERT_STRING("fopen:2", m);

  h = fopen (f, m);
  
  if (h)
    return h;

  failure ("fopen (\"%s\", \"%s\"): %s, %s, %s\n", f, m, strerror (errno));
}

extern void Lfclose (FILE *f) {
  ASSERT_BOXED("fclose", f);

  fclose (f);
}

extern void* LreadLine () {
  char *buf;

  if (scanf ("%m[^\n]", &buf) == 1) {
    void * s = Bstring (buf);

    getchar ();
    
    free (buf);
    return s;
  }
  
  if (errno != 0)
    failure ("readLine (): %s\n", strerror (errno));

  return (void*) BOX (0);
}

extern void* Lfread (char *fname) {
  FILE *f;

  ASSERT_STRING("fread", fname);

  f = fopen (fname, "r");
  
  if (f) {
    if (fseek (f, 0l, SEEK_END) >= 0) {
      long size = ftell (f);
      void *s   = LmakeString (BOX(size));
      
      rewind (f);

      if (fread (s, 1, size, f) == size) {
	fclose (f);
	return s;
      }
    }
  }

  failure ("fread (\"%s\"): %s\n", fname, strerror (errno));
}

extern void Lfwrite (char *fname, char *contents) {
  FILE *f;

  ASSERT_STRING("fwrite:1", fname);
  ASSERT_STRING("fwrite:2", contents);
  
  f = fopen (fname, "w");

  if (f) {
    if (fprintf (f, "%s", contents) < 0);
    else {
      fclose (f);
      return;
    }
  }

  failure ("fwrite (\"%s\"): %s\n", fname, strerror (errno));
}

extern void* Lfexists (char *fname) {
  FILE *f;

  ASSERT_STRING("fexists", fname);

  f = fopen (fname, "r");
  
  if (f) return BOX(1);

  return BOX(0);
}

extern void* Lfst (void *v) {
  return Belem (v, BOX(0));  
}

extern void* Lsnd (void *v) {
  return Belem (v, BOX(1));  
}

extern void* Lhd (void *v) {
  return Belem (v, BOX(0));  
}

extern void* Ltl (void *v) {
  return Belem (v, BOX(1));  
}

/* Lread is an implementation of the "read" construct */
extern int Lread () {
  int result = BOX(0);

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

extern int Lrandom (int n) {
  ASSERT_UNBOXED("Lrandom, 0", n);

  if (UNBOX(n) <= 0) {
    failure ("invalid range in random: %d\n", UNBOX(n));
  }
  
  return BOX (random () % UNBOX(n));
}

extern int Ltime () {
  struct timespec t;
  
  clock_gettime (CLOCK_MONOTONIC_RAW, &t);
  
  return BOX(t.tv_sec * 1000000 + t.tv_nsec / 1000);
}

extern void set_args (int argc, char *argv[]) {
  data *a;
  int n = argc, *p = NULL;
  int i;
  
  __pre_gc ();

#ifdef DEBUG_PRINT
  indent++; print_indent ();
  printf ("set_args: call: n=%i &p=%p p=%p: ", n, &p, p); fflush(stdout);
  for (i = 0; i < n; i++)
    printf("%s ", argv[i]);
  printf("EE\n");
#endif

  p = LmakeArray (BOX(n));
  push_extra_root ((void**)&p);
  
  for (i=0; i<n; i++) {
#ifdef DEBUG_PRINT
    print_indent ();
    printf ("set_args: iteration %i %p %p ->\n", i, &p, p); fflush(stdout);
#endif
    ((int*)p) [i] = (int) Bstring (argv[i]);
#ifdef DEBUG_PRINT
    print_indent ();
    printf ("set_args: iteration %i <- %p %p\n", i, &p, p); fflush(stdout);
#endif
  }

  pop_extra_root ((void**)&p);
  __post_gc ();

  global_sysargs = p;
  push_extra_root ((void**)&global_sysargs);
#ifdef DEBUG_PRINT
  print_indent ();
  printf ("set_args: end\n", n, &p, p); fflush(stdout);
  indent--;
#endif
}

/* GC starts here */

static int enable_GC = 1;

extern void LenableGC () {
  enable_GC = 1;
}

extern void LdisableGC () {
  enable_GC = 0;
}

extern const size_t __start_custom_data, __stop_custom_data;

# ifdef __ENABLE_GC__

extern void __gc_init ();

# else

# define __gc_init __gc_init_subst
void __gc_init_subst () {}

# endif

extern void __gc_root_scan_stack ();

/* ======================================== */
/*           Mark-and-copy                  */
/* ======================================== */

//static size_t SPACE_SIZE = 16;
static size_t SPACE_SIZE = 256 * 1024 * 1024;
// static size_t SPACE_SIZE = 128;
// static size_t SPACE_SIZE = 1024 * 1024;

static int free_pool (pool * p) {
  size_t *a = p->begin, b = p->size;
  p->begin   = NULL;
  p->size    = 0;
  p->end     = NULL;
  p->current = NULL;
  return munmap((void *)a, b);
}

static void init_to_space (int flag) {
  size_t space_size = 0;
  if (flag) SPACE_SIZE = SPACE_SIZE << 1;
  space_size     = SPACE_SIZE * sizeof(size_t);
  to_space.begin = mmap (NULL, space_size, PROT_READ | PROT_WRITE,
			 MAP_PRIVATE | MAP_ANONYMOUS | MAP_32BIT, -1, 0);
  if (to_space.begin == MAP_FAILED) {
    perror ("EROOR: init_to_space: mmap failed\n");
    exit   (1);
  }
  to_space.current = to_space.begin;
  to_space.end     = to_space.begin + SPACE_SIZE;
  to_space.size    = SPACE_SIZE;
}

static void gc_swap_spaces (void) {
#ifdef DEBUG_PRINT
  indent++; print_indent ();
  printf ("gc_swap_spaces\n"); fflush (stdout);
#endif
  free_pool (&from_space);
  from_space.begin   = to_space.begin;
  from_space.current = current;
  from_space.end     = to_space.end;
  from_space.size    = to_space.size;
  to_space.begin   = NULL;
  to_space.current = NULL;
  to_space.end     = NULL;
  to_space.size    = 0;
#ifdef DEBUG_PRINT
  indent--;
#endif
}

# define IS_VALID_HEAP_POINTER(p)\
  (!UNBOXED(p) &&		 \
   (size_t)from_space.begin <= (size_t)p &&	 \
   (size_t)from_space.end   >  (size_t)p)

# define IN_PASSIVE_SPACE(p)	\
  ((size_t)to_space.begin <= (size_t)p	&&	\
   (size_t)to_space.end   >  (size_t)p)

# define IS_FORWARD_PTR(p)			\
  (!UNBOXED(p) && IN_PASSIVE_SPACE(p))

int is_valid_heap_pointer (void *p)  {
  return IS_VALID_HEAP_POINTER(p);
}

extern size_t * gc_copy (size_t *obj);

static void copy_elements (size_t *where, size_t *from, int len) {
  int    i = 0;
  void * p = NULL;
#ifdef DEBUG_PRINT
  indent++; print_indent ();
  printf ("copy_elements: start; len = %d\n", len); fflush (stdout);
#endif
  for (i = 0; i < len; i++) {
    size_t elem = from[i];
    if (!IS_VALID_HEAP_POINTER(elem)) {
      *where = elem;
      where++;
#ifdef DEBUG_PRINT
      print_indent ();	
      printf ("copy_elements: copy NON ptr: %zu %p \n", elem, elem); fflush (stdout);
#endif
    }
    else {
#ifdef DEBUG_PRINT
      print_indent ();	
      printf ("copy_elements: fix element: %p -> %p\n", elem, *where);
      fflush (stdout);
#endif
      p = gc_copy ((size_t*) elem);
      *where = (size_t) p;
      where ++;
    }
#ifdef DEBUG_PRINT
    print_indent ();
    printf ("copy_elements: iteration end: where = %p, *where = %p, i = %d, \
             len = %d\n", where, *where, i, len); fflush (stdout);
#endif

  }
#ifdef DEBUG_PRINT
  print_indent ();
  printf ("\tcopy_elements: end\n"); fflush (stdout);
  indent--;
#endif

}

static int extend_spaces (void) {
  void *p = (void *) BOX (NULL);
  size_t old_space_size = SPACE_SIZE        * sizeof(size_t),
         new_space_size = (SPACE_SIZE << 1) * sizeof(size_t);
  p = mremap(to_space.begin, old_space_size, new_space_size, 0);
#ifdef DEBUG_PRINT
  indent++; print_indent ();
#endif
  if (p == MAP_FAILED) {
#ifdef DEBUG_PRINT
    print_indent ();
    printf ("extend: extend_spaces: mremap failed\n"); fflush (stdout);
#endif
    return 1;
  }
#ifdef DEBUG_PRINT
  print_indent ();
  printf ("extend: %p %p %p %p\n", p, to_space.begin, to_space.end, current);
  fflush (stdout);
  indent--;
#endif
  to_space.end    += SPACE_SIZE;
  SPACE_SIZE      =  SPACE_SIZE << 1;
  to_space.size   =  SPACE_SIZE;
  return 0;
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
  indent++; print_indent ();
  printf ("gc_copy: %p cur = %p starts\n", obj, current);
  fflush (stdout);
#endif

  if (!IS_VALID_HEAP_POINTER(obj)) {
#ifdef DEBUG_PRINT
    print_indent ();
    printf ("gc_copy: invalid ptr: %p\n", obj); fflush (stdout);
    indent--;
#endif
    return obj;
  }

  if (!IN_PASSIVE_SPACE(current) && current != to_space.end) {
#ifdef DEBUG_PRINT
    print_indent ();
    printf("ERROR: gc_copy: out-of-space %p %p %p\n",
	   current, to_space.begin, to_space.end);
    fflush(stdout);
#endif
    perror("ERROR: gc_copy: out-of-space\n");
    exit (1);
  }

  if (IS_FORWARD_PTR(d->tag)) {
#ifdef DEBUG_PRINT
    print_indent ();
    printf ("gc_copy: IS_FORWARD_PTR: return! %p -> %p\n", obj, (size_t *) d->tag);
    fflush(stdout);
    indent--;
#endif
    return (size_t *) d->tag;
  }

  copy = current;
#ifdef DEBUG_PRINT
  objj = d;
#endif
  switch (TAG(d->tag)) {
    case CLOSURE_TAG:
#ifdef DEBUG_PRINT
      print_indent ();
      printf ("gc_copy:closure_tag; len =  %zu\n", LEN(d->tag)); fflush (stdout);
#endif
      i = LEN(d->tag);
      // current += LEN(d->tag) + 1;
      // current += ((LEN(d->tag) + 1) * sizeof(int) -1) / sizeof(size_t) + 1;
      current += i+1;
      *copy = d->tag;
      copy++;
      d->tag = (int) copy;
      copy_elements (copy, obj, i);
      break;
    
    case ARRAY_TAG:
#ifdef DEBUG_PRINT
      print_indent ();
      printf ("gc_copy:array_tag; len =  %zu\n", LEN(d->tag)); fflush (stdout);
#endif
      current += ((LEN(d->tag) + 1) * sizeof (int) - 1) / sizeof (size_t) + 1;
      *copy = d->tag;
      copy++;
      i = LEN(d->tag);
      d->tag = (int) copy;
      copy_elements (copy, obj, i);
      break;

    case STRING_TAG:
#ifdef DEBUG_PRINT
      print_indent ();
      printf ("gc_copy:string_tag; len = %d\n", LEN(d->tag) + 1); fflush (stdout);
#endif
      current += (LEN(d->tag) + sizeof(int)) / sizeof(size_t) + 1;
      *copy = d->tag;
      copy++;
      d->tag = (int) copy;
      strcpy ((char*)&copy[0], (char*) obj);
      break;

  case SEXP_TAG  :
      s = TO_SEXP(obj);
#ifdef DEBUG_PRINT
      objj = s;
      len1 = LEN(s->contents.tag);
      len2 = LEN(s->tag);
      len3 = LEN(d->tag);
      print_indent ();
      printf ("gc_copy:sexp_tag; len1 = %li, len2=%li, len3 = %li\n",
	      len1, len2, len3);
      fflush (stdout);
#endif
      i = LEN(s->contents.tag);
      current += i + 2;
      *copy = s->tag;
      copy++;
      *copy = d->tag;
      copy++;
      d->tag = (int) copy;
      copy_elements (copy, obj, i);
      break;

  default:
#ifdef DEBUG_PRINT
    print_indent ();
    printf ("ERROR: gc_copy: weird tag: %p", TAG(d->tag)); fflush (stdout);
    indent--;
#endif
    perror ("ERROR: gc_copy: weird tag");
    exit (1);
    return (obj);
  }
#ifdef DEBUG_PRINT
  print_indent ();
  printf ("gc_copy: %p(%p) -> %p (%p); new-current = %p\n",
	  obj, objj, copy, newobjj, current);
  fflush (stdout);
  indent--;
#endif
  return copy;
}

extern void gc_test_and_copy_root (size_t ** root) {
#ifdef DEBUG_PRINT
    indent++;
#endif
  if (IS_VALID_HEAP_POINTER(*root)) {
#ifdef DEBUG_PRINT
    print_indent ();
    printf ("gc_test_and_copy_root: root %p top=%p bot=%p  *root %p \n", root, __gc_stack_top, __gc_stack_bottom, *root);
    fflush (stdout);
#endif
    *root = gc_copy (*root);
  }
#ifdef DEBUG_PRINT
  else {
    print_indent ();
    printf ("gc_test_and_copy_root: INVALID HEAP POINTER root %p  *root %p\n", root, *root);
    fflush (stdout);
  }
  indent--;
#endif
}

extern void gc_root_scan_data (void) {
  size_t * p = (size_t*)&__start_custom_data;
  while  (p < (size_t*)&__stop_custom_data) {
    gc_test_and_copy_root ((size_t**)p);
    p++;
  }
}

static inline void init_extra_roots (void) {
  extra_roots.current_free = 0;
}

extern void __init (void) {
  size_t space_size = SPACE_SIZE * sizeof(size_t);

  srandom (time (NULL));
  
  from_space.begin = mmap (NULL, space_size, PROT_READ | PROT_WRITE,
    			   MAP_PRIVATE | MAP_ANONYMOUS | MAP_32BIT, -1, 0);
  to_space.begin   = NULL;
  if (to_space.begin == MAP_FAILED) {
    perror ("EROOR: init_pool: mmap failed\n");
    exit   (1);
  }
  from_space.current = from_space.begin;
  from_space.end     = from_space.begin + SPACE_SIZE;
  from_space.size    = SPACE_SIZE;
  to_space.current   = NULL;
  to_space.end       = NULL;
  to_space.size      = 0;
  init_extra_roots ();
}

static void* gc (size_t size) {
  if (! enable_GC) {
    Lfailure ("GC disabled");
  }
  
  current = to_space.begin;
#ifdef DEBUG_PRINT
  print_indent ();
  printf ("gc: current:%p; to_space.b =%p; to_space.e =%p; \
           f_space.b = %p; f_space.e = %p; __gc_stack_top=%p; __gc_stack_bottom=%p\n",
	  current, to_space.begin, to_space.end, from_space.begin, from_space.end,
	  __gc_stack_top, __gc_stack_bottom);
  fflush (stdout);
#endif
  gc_root_scan_data ();
#ifdef DEBUG_PRINT
  print_indent ();
  printf ("gc: data is scanned\n"); fflush (stdout);
#endif
  __gc_root_scan_stack ();
  for (int i = 0; i < extra_roots.current_free; i++) {
#ifdef DEBUG_PRINT
    print_indent ();
    printf ("gc: extra_root № %i: %p %p\n", i, extra_roots.roots[i],
	    (size_t*) extra_roots.roots[i]);
    fflush (stdout);
#endif
    gc_test_and_copy_root ((size_t**)extra_roots.roots[i]);
  }
#ifdef DEBUG_PRINT
  print_indent ();
  printf ("gc: no more extra roots\n"); fflush (stdout);
#endif

  if (!IN_PASSIVE_SPACE(current)) {
    printf ("gc: ASSERT: !IN_PASSIVE_SPACE(current) to_begin = %p to_end = %p \
             current = %p\n", to_space.begin, to_space.end, current);
    fflush (stdout);
    perror ("ASSERT: !IN_PASSIVE_SPACE(current)\n");
    exit   (1);
  }

  while (current + size >= to_space.end) {
#ifdef DEBUG_PRINT
    print_indent ();
    printf ("gc: pre-extend_spaces : %p %zu %p \n", current, size, to_space.end);
    fflush (stdout);
#endif
    if (extend_spaces ()) {
      gc_swap_spaces ();
      init_to_space (1);
      return gc (size);
    }
#ifdef DEBUG_PRINT
    print_indent ();
    printf ("gc: post-extend_spaces: %p %zu %p \n", current, size, to_space.end);
    fflush (stdout);
#endif
  }
  assert (IN_PASSIVE_SPACE(current));
  assert (current + size < to_space.end);

  gc_swap_spaces ();
  from_space.current = current + size;
#ifdef DEBUG_PRINT
  print_indent ();
  printf ("gc: end: (allocate!) return %p; from_space.current %p; \
           from_space.end %p \n\n",
	  current, from_space.current, from_space.end);
  fflush (stdout);
  indent--;
#endif
  return (void *) current;
}

#ifdef DEBUG_PRINT
static void printFromSpace (void) {
  size_t * cur = from_space.begin, *tmp = NULL;
  data   * d   = NULL;
  sexp   * s   = NULL;
  size_t   len = 0;
  size_t   elem_number = 0;
  
  printf ("\nHEAP SNAPSHOT\n===================\n");
  printf ("f_begin = %p, f_end = %p,\n", from_space.begin, from_space.end);
  while (cur < from_space.current) {
    printf ("data at %p", cur);
    d  = (data *) cur;

    switch (TAG(d->tag)) {

    case STRING_TAG:
      printf ("(=>%p): STRING\n\t%s; len = %i %zu\n",
	      d->contents, d->contents,
	      LEN(d->tag), LEN(d->tag) + 1 + sizeof(int));
      fflush (stdout);
      len = (LEN(d->tag) + sizeof(int)) / sizeof(size_t) + 1;
      break;

    case CLOSURE_TAG:
      printf ("(=>%p): CLOSURE\n\t", d->contents);
      len = LEN(d->tag);
      for (int i = 0; i < len; i++) {
	int elem = ((int*)d->contents)[i];
	if (UNBOXED(elem)) printf ("%d ", elem);
	else printf ("%p ", elem);
      }
      len += 1;
      printf ("\n");
      fflush (stdout);
      break;

    case ARRAY_TAG:
      printf ("(=>%p): ARRAY\n\t", d->contents);
      len = LEN(d->tag);
      for (int i = 0; i < len; i++) {
	int elem = ((int*)d->contents)[i];
	if (UNBOXED(elem)) printf ("%d ", elem);
	else printf ("%p ", elem);
      }
      len += 1;
      printf ("\n");
      fflush (stdout);
      break;

    case SEXP_TAG:
      s = (sexp *) d;
      d = (data *) &(s->contents);
      char * tag = de_hash (GET_SEXP_TAG(s->tag));
      printf ("(=>%p): SEXP\n\ttag(%s) ", s->contents.contents, tag);
      len = LEN(d->tag);
      tmp = (s->contents.contents);
      for (int i = 0; i < len; i++) {
	int elem = ((int*)tmp)[i];
	if (UNBOXED(elem)) printf ("%d ", UNBOX(elem));
	else printf ("%p ", elem);
      }
      len += 2;
      printf ("\n");
      fflush (stdout);
      break;

    case 0:
      printf ("\nprintFromSpace: end: %zu elements\n===================\n\n",
	      elem_number);
      return;

    default:
      printf ("\nprintFromSpace: ERROR: bad tag %d", TAG(d->tag));
      perror ("\nprintFromSpace: ERROR: bad tag");
      fflush (stdout);
      exit   (1);
    }
    cur += len;
    printf ("len = %zu, new cur = %p\n", len, cur);
    elem_number++;
  }
  printf ("\nprintFromSpace: end: the whole space is printed:\
            %zu elements\n===================\n\n", elem_number);
  fflush (stdout);
}
#endif

#ifdef __ENABLE_GC__
// alloc: allocates `size` bytes in heap
extern void * alloc (size_t size) {
  void * p = (void*)BOX(NULL);
  size = (size - 1) / sizeof(size_t) + 1; // convert bytes to words
#ifdef DEBUG_PRINT
  indent++; print_indent ();
  printf ("alloc: current: %p %zu words!", from_space.current, size);
  fflush (stdout);
#endif
  if (from_space.current + size < from_space.end) {
    p = (void*) from_space.current;
    from_space.current += size;
#ifdef DEBUG_PRINT
    print_indent ();
    printf (";new current: %p \n", from_space.current); fflush (stdout);
    indent--;
#endif
    return p;
  }
  
  init_to_space (0);
#ifdef DEBUG_PRINT
  print_indent ();
  printf ("alloc: call gc: %zu\n", size); fflush (stdout);
  printFromSpace(); fflush (stdout);
  p = gc (size);
  print_indent ();
  printf("alloc: gc END %p %p %p %p\n\n", from_space.begin,
	 from_space.end, from_space.current, p); fflush (stdout);
  printFromSpace(); fflush (stdout);
  indent--;
  return p;
#else
  return gc (size);
#endif
}
# endif
