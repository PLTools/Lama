/* Runtime library */

# define _GNU_SOURCE 1

# include "runtime.h"
# include "gc.h"

extern size_t __gc_stack_top, __gc_stack_bottom;

#ifdef LAMA_ENV
#define PRE_GC()                                                                                   \
  bool flag = false;                                                                               \
  flag      = __gc_stack_top == 0;                                                                 \
  if (flag) { __gc_stack_top = (size_t)__builtin_frame_address(0); }                               \
  assert(__gc_stack_top != 0);                                                                     \
  assert((__gc_stack_top & 0xF) == 0);                                                             \
  assert(__builtin_frame_address(0) <= (void *)__gc_stack_top);
#define POST_GC()                                                                                  \
  assert(__builtin_frame_address(0) <= (void *)__gc_stack_top);                                    \
  if (flag) { __gc_stack_top = 0; }
#else
#define PRE_GC() (void)0
#define POST_GC() (void)0
#endif

_Noreturn static void vfailure (char *s, va_list args) {
  fprintf(stderr, "*** FAILURE: ");
  vfprintf(stderr, s, args);   // vprintf (char *, va_list) <-> printf (char *, ...)
  exit(255);
}

_Noreturn void failure (char *s, ...) {
  va_list args;

  va_start(args, s);
  vfailure(s, args);
}

void Lassert (void *f, char *s, ...) {
  if (!UNBOX(f)) {
    va_list args;

    va_start(args, s);
    vfailure(s, args);
  }
}

#define ASSERT_BOXED(memo, x)                                                                      \
  do                                                                                               \
    if (UNBOXED(x)) failure("boxed value expected in %s\n", memo);                                 \
  while (0)
#define ASSERT_UNBOXED(memo, x)                                                                    \
  do                                                                                               \
    if (!UNBOXED(x)) failure("unboxed value expected in %s\n", memo);                              \
  while (0)
#define ASSERT_STRING(memo, x)                                                                     \
  do                                                                                               \
    if (!UNBOXED(x) && TAG(TO_DATA(x)->data_header) != STRING_TAG)                                 \
      failure("string value expected in %s\n", memo);                                              \
  while (0)

extern void *Bsexp (intptr_t* args, intptr_t bn);
extern intptr_t LtagHash (char *);

void *global_sysargs;

// Gets a raw data_header
extern intptr_t LkindOf (void *p) {
  if (UNBOXED(p)) return UNBOXED_TAG;

  return TAG(TO_DATA(p)->data_header);
}

// Compare s-exprs tags
extern intptr_t LcompareTags (void *p, void *q) {
  data *pd, *qd;

  ASSERT_BOXED("compareTags, 0", p);
  ASSERT_BOXED("compareTags, 1", q);

  pd = TO_DATA(p);
  qd = TO_DATA(q);

  if (TAG(pd->data_header) == SEXP_TAG && TAG(qd->data_header) == SEXP_TAG) {
    return BOX((TO_SEXP(p)->tag) - (TO_SEXP(q)->tag));
  } else {
    failure("not a sexpr in compareTags: %ld, %ld\n", TAG(pd->data_header), TAG(qd->data_header));
  }
  // dead code
  return 0;
}

// Functional synonym for built-in operator ":";
void *Ls__Infix_58 (void** args) {
  void *res;

  PRE_GC();

  intptr_t bsexp_args[] = {(intptr_t)args[0], (intptr_t)args[1], LtagHash("cons")};
  res = Bsexp(bsexp_args, BOX(3));

  POST_GC();

  return res;
}

// Functional synonym for built-in operator "!!";
intptr_t Ls__Infix_3333 (void *p, void *q) {
  ASSERT_UNBOXED("captured !!:1", p);
  ASSERT_UNBOXED("captured !!:2", q);

  return BOX(UNBOX(p) || UNBOX(q));
}

// Functional synonym for built-in operator "&&";
intptr_t Ls__Infix_3838 (void *p, void *q) {
  ASSERT_UNBOXED("captured &&:1", p);
  ASSERT_UNBOXED("captured &&:2", q);

  return BOX(UNBOX(p) && UNBOX(q));
}

// Functional synonym for built-in operator "==";
intptr_t Ls__Infix_6161 (void *p, void *q) { return BOX(p == q); }

// Functional synonym for built-in operator "!=";
intptr_t Ls__Infix_3361 (void *p, void *q) {
  ASSERT_UNBOXED("captured !=:1", p);
  ASSERT_UNBOXED("captured !=:2", q);

  return BOX(UNBOX(p) != UNBOX(q));
}

// Functional synonym for built-in operator "<=";
intptr_t Ls__Infix_6061 (void *p, void *q) {
  ASSERT_UNBOXED("captured <=:1", p);
  ASSERT_UNBOXED("captured <=:2", q);

  return BOX(UNBOX(p) <= UNBOX(q));
}

// Functional synonym for built-in operator "<";
intptr_t Ls__Infix_60 (void *p, void *q) {
  ASSERT_UNBOXED("captured <:1", p);
  ASSERT_UNBOXED("captured <:2", q);

  return BOX(UNBOX(p) < UNBOX(q));
}

// Functional synonym for built-in operator ">=";
intptr_t Ls__Infix_6261 (void *p, void *q) {
  ASSERT_UNBOXED("captured >=:1", p);
  ASSERT_UNBOXED("captured >=:2", q);

  return BOX(UNBOX(p) >= UNBOX(q));
}

// Functional synonym for built-in operator ">";
intptr_t Ls__Infix_62 (void *p, void *q) {
  ASSERT_UNBOXED("captured >:1", p);
  ASSERT_UNBOXED("captured >:2", q);

  return BOX(UNBOX(p) > UNBOX(q));
}

// Functional synonym for built-in operator "+";
intptr_t Ls__Infix_43 (void *p, void *q) {
  ASSERT_UNBOXED("captured +:1", p);
  ASSERT_UNBOXED("captured +:2", q);

  return BOX(UNBOX(p) + UNBOX(q));
}

// Functional synonym for built-in operator "-";
intptr_t Ls__Infix_45 (void *p, void *q) {
  if (UNBOXED(p)) {
    ASSERT_UNBOXED("captured -:2", q);
    return BOX(UNBOX(p) - UNBOX(q));
  }

  ASSERT_BOXED("captured -:1", q);
  return BOX(p - q);
}

// Functional synonym for built-in operator "*";
intptr_t Ls__Infix_42 (void *p, void *q) {
  ASSERT_UNBOXED("captured *:1", p);
  ASSERT_UNBOXED("captured *:2", q);

  return BOX(UNBOX(p) * UNBOX(q));
}

// Functional synonym for built-in operator "/";
intptr_t Ls__Infix_47 (void *p, void *q) {
  ASSERT_UNBOXED("captured /:1", p);
  ASSERT_UNBOXED("captured /:2", q);

  return BOX(UNBOX(p) / UNBOX(q));
}

// Functional synonym for built-in operator "%";
intptr_t Ls__Infix_37 (void *p, void *q) {
  ASSERT_UNBOXED("captured %:1", p);
  ASSERT_UNBOXED("captured %:2", q);

  return BOX(UNBOX(p) % UNBOX(q));
}

extern intptr_t Llength (void *p) {
  ASSERT_BOXED(".length", p);
  return BOX(LEN(TO_DATA(p)->data_header));
}

static char *chars = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'";
#ifdef X86_64
#define MAX_SEXP_TAGLEN 10
#else
#define MAX_SEXP_TAGLEN 5
#endif

extern char *de_hash (intptr_t);

extern intptr_t LtagHash (char *s) {
  char *p;
  intptr_t h = 0, limit = 0;

  p = s;
  while (*p && limit++ < MAX_SEXP_TAGLEN) {
    char *q   = chars;
    intptr_t pos = 0;

    for (; *q && *q != *p; q++, pos++)
      ;

    if (*q) h = (h << 6) | pos;
    else failure("tagHash: character not found: %c\n", *p);

    p++;
  }

  if (strncmp(s, de_hash(h), MAX_SEXP_TAGLEN) != 0) { failure("%s <-> %s\n", s, de_hash(h)); }

  return BOX(h);
}

char *de_hash (intptr_t n) {
  static char buf[MAX_SEXP_TAGLEN + 1] = {0, 0, 0, 0, 0, 0};
  char       *p      = (char *)BOX(NULL);
  p                  = &buf[MAX_SEXP_TAGLEN];

  *p-- = 0;

  while (n != 0) {
    *p-- = chars[n & 0b111111];
    n    = n >> 6;
  }

  return ++p;
}

typedef struct {
  char *contents;
  intptr_t ptr;
  intptr_t len;
} StringBuf;

static StringBuf stringBuf;

#define STRINGBUF_INIT 128

static void createStringBuf () {
  stringBuf.contents = (char *)malloc(STRINGBUF_INIT);
  memset(stringBuf.contents, 0, STRINGBUF_INIT);
  stringBuf.ptr = 0;
  stringBuf.len = STRINGBUF_INIT;
}

static void deleteStringBuf () { free(stringBuf.contents); }

static void extendStringBuf () {
  intptr_t len = stringBuf.len << 1;

  stringBuf.contents = (char *)realloc(stringBuf.contents, len);
  stringBuf.len      = len;
}

static void vprintStringBuf (char *fmt, va_list args) {
  intptr_t written = 0, rest = 0;
  char   *buf = (char *)BOX(NULL);
  va_list vsnargs;

again:
  va_copy(vsnargs, args);

  buf  = &stringBuf.contents[stringBuf.ptr];
  rest = stringBuf.len - stringBuf.ptr;

  written = vsnprintf(buf, rest, fmt, vsnargs);

  va_end(vsnargs);

  if (written >= rest) {
    extendStringBuf();
    goto again;
  }

  stringBuf.ptr += written;
}

static void printStringBuf (char *fmt, ...) {
  va_list args;

  va_start(args, fmt);
  vprintStringBuf(fmt, args);
}

static void printValue (void *p) {
  data *a = (data *)BOX(NULL);
  intptr_t i = BOX(0);
  if (UNBOXED(p)) {
    printStringBuf("%ld", UNBOX(p));
  } else {
    if (!is_valid_heap_pointer(p)) {
      printStringBuf("0x%x", p);
      return;
    }

    a = TO_DATA(p);

    switch (TAG(a->data_header)) {
      case STRING_TAG: printStringBuf("\"%s\"", a->contents); break;

      case CLOSURE_TAG: {

        printStringBuf("<closure ");
        for (i = 0; i < LEN(a->data_header); i++) {
          if (i) printValue((void *)((intptr_t *)a->contents)[i]);
          else printStringBuf("0x%x", (void *)((intptr_t *)a->contents)[i]);
          if (i != LEN(a->data_header) - 1) printStringBuf(", ");
        }
        printStringBuf(">");
        break;
      }
      case ARRAY_TAG: {
        printStringBuf("[");
        for (i = 0; i < LEN(a->data_header); i++) {
          printValue((void *)((intptr_t *)a->contents)[i]);
          if (i != LEN(a->data_header) - 1) printStringBuf(", ");
        }
        printStringBuf("]");
        break;
      }

      case SEXP_TAG: {
        sexp *sa  = (sexp *)a;
        char *tag = de_hash((intptr_t)sa->tag);
        if (strcmp(tag, "cons") == 0) {
          sexp *sb = sa;
          printStringBuf("{");
          while (LEN(sb->data_header)) {
            printValue((void *)((intptr_t *)sb->contents)[0]);
            intptr_t list_next = ((intptr_t *)sb->contents)[1];
            if (!UNBOXED(list_next)) {
              printStringBuf(", ");
              sb = TO_SEXP(list_next);
            } else break;
          }
          printStringBuf("}");
        } else {
          printStringBuf("%s", tag);
          sexp *sexp_a = (sexp *)a;
          if (LEN(a->data_header)) {
            printStringBuf(" (");
            for (i = 0; i < LEN(sexp_a->data_header); i++) {
              printValue((void *)((intptr_t *)sexp_a->contents)[i]);
              if (i != LEN(sexp_a->data_header) - 1) printStringBuf(", ");
            }
            printStringBuf(")");
          }
        }
      } break;

      default: printStringBuf("*** invalid data_header: 0x%x ***", TAG(a->data_header));
    }
  }
}

static void stringcat (void *p) {
  data *a;
  intptr_t i;

  if (UNBOXED(p))
    ;
  else {
    a = TO_DATA(p);

    switch (TAG(a->data_header)) {
      case STRING_TAG: printStringBuf("%s", a->contents); break;

      case SEXP_TAG: {
        char *tag = de_hash(TO_SEXP(p)->tag);

        if (strcmp(tag, "cons") == 0) {
          sexp *b = (sexp *)a;

          while (LEN(b->data_header)) {
            stringcat((void *)((intptr_t *)b->contents)[0]);
            intptr_t next_b = ((intptr_t *)b->contents)[1];
            if (!UNBOXED(next_b)) {
              b = TO_SEXP(next_b);
            } else break;
          }
        } else printStringBuf("*** non-list data_header: %s ***", tag);
      } break;

      default: printStringBuf("*** invalid data_header: 0x%x ***", TAG(a->data_header));
    }
  }
}

extern intptr_t Luppercase (void *v) {
  ASSERT_UNBOXED("Luppercase:1", v);
  return BOX(toupper((int)UNBOX(v)));
}

extern intptr_t Llowercase (void *v) {
  ASSERT_UNBOXED("Llowercase:1", v);
  return BOX(tolower((int)UNBOX(v)));
}

extern intptr_t LmatchSubString (char *subj, char *patt, intptr_t pos) {
  data *p = TO_DATA(patt), *s = TO_DATA(subj);
  intptr_t n;

  ASSERT_STRING("matchSubString:1", subj);
  ASSERT_STRING("matchSubString:2", patt);
  ASSERT_UNBOXED("matchSubString:3", pos);

#ifdef DEBUG_PRINT
  printf("substring: %s, pattern: %s\n", subj + UNBOX(pos), patt);
#endif

  n = LEN(p->data_header);

  if (n + UNBOX(pos) > LEN(s->data_header)) return BOX(0);

  return BOX(strncmp(subj + UNBOX(pos), patt, n) == 0);
}

extern void *Lsubstring (intptr_t* args /*void *subj, intptr_t p, intptr_t l*/) {
  data *d  = TO_DATA(args[0]);
  intptr_t pp = UNBOX(args[1]), ll = UNBOX(args[2]);

  ASSERT_STRING("substring:1", args[0]);
  ASSERT_UNBOXED("substring:2", args[1]);
  ASSERT_UNBOXED("substring:3", args[2]);

  if (pp + ll <= LEN(d->data_header)) {
    data *r;

    PRE_GC();

    push_extra_root((void**)&args[0]);
    r = (data *)alloc_string(ll);
    pop_extra_root((void**)&args[0]);

    char *r_contents = r->contents;
    strncpy(r_contents, (char *)args[0] + pp, ll);

    POST_GC();

    return r->contents;
  }

  failure("substring: index out of bounds (position=%ld, length=%ld, subject length=%ld)",
          pp,
          ll,
          LEN(d->data_header));
  exit(1);
  return NULL;
}

extern regex_t *Lregexp (char *regexp) {
  regex_t *regexp_compiled = (regex_t *)malloc(sizeof(regex_t));

  memset(regexp_compiled, 0, sizeof(regex_t));

  int res = regcomp(regexp_compiled, regexp, REG_EXTENDED);

  //printf("Lregexp: got compiled regexp %p, for string %s\n", regexp_compiled, regexp);

  if (res != 0) {
      char buf[100];
      regerror(res, regexp_compiled, buf, 100);
      failure("%s", buf);
  }

  return regexp_compiled;
}

extern intptr_t LregexpMatch (regex_t *b, char *s, intptr_t pos) {
  regmatch_t match;

  ASSERT_BOXED("regexpMatch:1", b);
  ASSERT_STRING("regexpMatch:2", s);
  ASSERT_UNBOXED("regexpMatch:3", pos);

  int res = regexec(b, s + UNBOX(pos), (size_t) 1, &match, 0);

  //printf("regexpMatch %p: %s, res=%d so=%d eo=%d\n", b, s + UNBOX(pos), res, match.rm_so, match.rm_eo);

  if (res == 0 && match.rm_so == 0) {
      return BOX(match.rm_eo);
  } else {
      return BOX(-1);
  }
}

extern void *Bstring (intptr_t* args);

void *Lclone (intptr_t* args /*void *p*/) {
  data *obj;
  void *res;
  if (UNBOXED(args[0])) return (void*)args[0];

  PRE_GC();

  data *a = TO_DATA(args[0]);
  intptr_t t = TAG(a->data_header), l = LEN(a->data_header);

  push_extra_root((void**)&args[0]);
  switch (t) {
    case STRING_TAG: {
      void* p = TO_DATA(args[0])->contents;
      res = Bstring((intptr_t*)&p);
      break;
    }

    case ARRAY_TAG:
      obj = (data *)alloc_array(l);
      memcpy(obj, TO_DATA(args[0]), array_size(l));
      res = (void *)obj->contents;
      break;
    case CLOSURE_TAG:
      obj = (data *)alloc_closure(l);
      memcpy(obj, TO_DATA(args[0]), closure_size(l));
      res = (void *)(obj->contents);
      break;

    case SEXP_TAG:
      obj = (data *)alloc_sexp(l);
      memcpy(obj, TO_DATA(args[0]), sexp_size(l));
      res = (void *)obj->contents;
      break;

    default: failure("invalid data_header %ld in clone *****\n", t);
  }
  pop_extra_root((void**)&args[0]);

  POST_GC();
  return res;
}

#define HASH_DEPTH 3
#define HASH_APPEND(acc, x)                                                                        \
  (((acc + (uintptr_t)x) << (WORD_SIZE / 2)) | ((acc + (uintptr_t)x) >> (WORD_SIZE / 2)))

intptr_t inner_hash (intptr_t depth, uintptr_t acc, void *p) {
  if (depth > HASH_DEPTH) return acc;

  if (UNBOXED(p)) return HASH_APPEND(acc, UNBOX(p));
  else if (is_valid_heap_pointer(p)) {
    data *a = TO_DATA(p);
    intptr_t t = TAG(a->data_header), l = LEN(a->data_header), i;

    acc = HASH_APPEND(acc, t);
    acc = HASH_APPEND(acc, l);

    switch (t) {
      case STRING_TAG: {
        char *p = a->contents;

        while (*p) {
          intptr_t n = (intptr_t)*p++;
          acc   = HASH_APPEND(acc, n);
        }

        return (intptr_t)acc;
      }

      case CLOSURE_TAG:
        acc = HASH_APPEND(acc, ((void **)a->contents)[0]);
        i   = 1;
        break;

      case ARRAY_TAG: i = 0; break;

      case SEXP_TAG: {
        intptr_t ta = TO_SEXP(p)->tag;
        acc    = HASH_APPEND(acc, ta);
        i      = 1;
        ++l;
        break;
      }

      default: failure("invalid data_header %ld in hash *****\n", t);
    }

    for (; i < l; i++) acc = inner_hash(depth + 1, acc, ((void **)a->contents)[i]);

    return (intptr_t)acc;
  } else return HASH_APPEND(acc, p);
}

extern void *LstringInt (char *b) {
  intptr_t n;
  sscanf(b, "%" SCNdPTR, &n);
  return (void *)BOX(n);
}

extern intptr_t Lhash (void *p) { return BOX(0x3fffff & inner_hash(0, 0, p)); }

extern intptr_t LflatCompare (void *p, void *q) {
  if (UNBOXED(p)) {
    if (UNBOXED(q)) { return BOX(UNBOX(p) - UNBOX(q)); }
    return -1;
  } else if (~UNBOXED(q)) {
    return BOX(p - q);
  } else return BOX(1);
}

extern intptr_t Lcompare (void *p, void *q) {
#define COMPARE_AND_RETURN(x, y)                                                                   \
  do                                                                                               \
    if (x != y) return BOX(x - y);                                                                 \
  while (0)

  if (p == q) return BOX(0);

  if (UNBOXED(p)) {
    if (UNBOXED(q)) return BOX(UNBOX(p) - UNBOX(q));
    else return BOX(-1);
  } else if (UNBOXED(q)) return BOX(1);
  else {
    if (is_valid_heap_pointer(p)) {
      if (is_valid_heap_pointer(q)) {
        data *a = TO_DATA(p), *b = TO_DATA(q);
        intptr_t ta = TAG(a->data_header), tb = TAG(b->data_header);
        intptr_t la = LEN(a->data_header), lb = LEN(b->data_header);
        intptr_t i;
        intptr_t shift = 0;

        COMPARE_AND_RETURN(ta, tb);

        switch (ta) {
          case STRING_TAG: return BOX(strcmp(a->contents, b->contents));

          case CLOSURE_TAG:
            COMPARE_AND_RETURN(((void **)a->contents)[0], ((void **)b->contents)[0]);
            COMPARE_AND_RETURN(la, lb);
            i = 1;
            break;

          case ARRAY_TAG:
            COMPARE_AND_RETURN(la, lb);
            i = 0;
            break;

          case SEXP_TAG: {
            intptr_t tag_a = TO_SEXP(p)->tag, tag_b = TO_SEXP(q)->tag;
            COMPARE_AND_RETURN(tag_a, tag_b);
            COMPARE_AND_RETURN(la, lb);
            i     = 0;
            shift = 1;
            break;
          }

          default: failure("invalid data_header %ld in compare *****\n", ta);
        }

        for (; i < la; i++) {
          intptr_t c = Lcompare(((void **)a->contents)[i + shift], ((void **)b->contents)[i + shift]);
          if (c != BOX(0)) return c;
        }
        return BOX(0);
      } else return BOX(-1);
    } else if (is_valid_heap_pointer(q)) return BOX(1);
    else return BOX(p - q);
  }
}

extern void *Belem (void *p, intptr_t i) {
  data *a = (data *)BOX(NULL);

  if (UNBOXED(p)) { ASSERT_BOXED(".elem:1", p); }
  ASSERT_UNBOXED(".elem:2", i);

  a = TO_DATA(p);
  i = UNBOX(i);

  switch (TAG(a->data_header)) {
    case STRING_TAG: return (void *)BOX((char)a->contents[i]);
    case SEXP_TAG: return (void *)((intptr_t *)((sexp *)a)->contents)[i];
    default: return (void *)((intptr_t *)a->contents)[i];
  }
}

extern void *LmakeArray (intptr_t length) {
  data *r;
  intptr_t n, *p;

  ASSERT_UNBOXED("makeArray:1", length);

  PRE_GC();

  n = UNBOX(length);
  r = (data *)alloc_array(n);

  p = (intptr_t *)r->contents;
  while (n--) *p++ = BOX(0);

  POST_GC();

  return r->contents;
}

extern void *LmakeString (intptr_t length) {
  intptr_t n = UNBOX(length);
  data *r;

  ASSERT_UNBOXED("makeString", length);

  PRE_GC();

  r = (data *)alloc_string(n);   // '\0' in the end of the string is taken into account

  POST_GC();

  return r->contents;
}

extern void *Bstring (intptr_t* args/*void *p*/) {
  size_t   n = strlen((char*)args[0]);
  void *s = NULL;

  PRE_GC();

  push_extra_root((void**)&args[0]);
  s = LmakeString(BOX(n));
  pop_extra_root((void**)&args[0]);
  char *s_contents = (char *)&TO_DATA(s)->contents;
  strncpy(s_contents, (char*)args[0], n + 1);   // +1 because of '\0' in the end of C-strings

  POST_GC();

  return s;
}

extern void *Lstringcat (intptr_t *args /* void* p */) {
  void *s;

  /* ASSERT_BOXED("stringcat", p); */

  PRE_GC();

  createStringBuf();
  stringcat((void*)args[0]);

  push_extra_root((void**)&args[0]);
  void* content = stringBuf.contents;
  s = Bstring((intptr_t*) &content);
  pop_extra_root((void**)&args[0]);

  deleteStringBuf();

  POST_GC();

  return s;
}

extern void *Lstring (intptr_t* args /* void *p */) {
  void *s = (void *)BOX(NULL);

  PRE_GC();

  createStringBuf();
  printValue((void*)args[0]);

  push_extra_root((void**)&args[0]);
  void* content = stringBuf.contents;
  s = Bstring((intptr_t*)&content);
  pop_extra_root((void**)&args[0]);

  deleteStringBuf();

  POST_GC();

  return s;
}

extern void *Bclosure (intptr_t* args, intptr_t bn) {
  data         *r;
  intptr_t       n = UNBOX(bn);

  PRE_GC();

  for (intptr_t i = 0; i < n; ++i) {
    push_extra_root((void**)&args[i + 1]);
  }

  r = (data *)alloc_closure(n + 1);
  ((void **)r->contents)[0] = (void*) args[0];

  for (int i = 0; i < n; i++) {
    ((intptr_t *)r->contents)[i + 1] = args[i + 1];
  }

  for (intptr_t i = n - 1; i >= 0; --i) {
    pop_extra_root((void**)&args[i + 1]);
  }

  POST_GC();

  return r->contents;
}

extern void *Barray (intptr_t* args, intptr_t bn) {
  data   *r;
  intptr_t n = UNBOX(bn);
  
  PRE_GC();

  for (intptr_t i = 0; i < n; i++) {
    push_extra_root((void**)&args[i]);
  }

  r = (data *)alloc_array(n);

  for (int i = 0; i < n; i++) {
    ((intptr_t *)r->contents)[i] = args[i];
  }

  for (intptr_t i = n - 1; i >= 0; --i) {
    pop_extra_root((void**)&args[i]);
  }

  POST_GC();
  return r->contents;
}

#ifdef DEBUG_VERSION
extern memory_chunk heap;
#endif

extern void *Bsexp (intptr_t* args, intptr_t bn) {
  sexp   *r;
  intptr_t n = UNBOX(bn);

  PRE_GC();

  intptr_t fields_cnt = n - 1;

  for (intptr_t i = 0; i < fields_cnt; i++) {
    push_extra_root((void**)&args[i]);
  }

  r              = alloc_sexp(fields_cnt);
  r->tag         = 0;

  for (int i = 0; i < fields_cnt; i++) {
    ((uintptr_t *)r->contents)[i] = args[i];
  }

  r->tag = UNBOX(args[fields_cnt]);

  for (intptr_t i = fields_cnt - 1; i >= 0; --i) {
    pop_extra_root((void**)&args[i]);
  }

  POST_GC();
  return (void *)((data *)r)->contents;
}

extern intptr_t Btag (void *d, intptr_t t, intptr_t n) {
  data *r;

  if (UNBOXED(d)) return BOX(0);
  else {
    r = TO_DATA(d);
    return (intptr_t)BOX(TAG(r->data_header) == SEXP_TAG && TO_SEXP(d)->tag == UNBOX(t)
                     && LEN(r->data_header) == UNBOX(n));
  }
}

intptr_t get_tag (data *d) { return TAG(d->data_header); }

intptr_t get_len (data *d) { return LEN(d->data_header); }

extern intptr_t Barray_patt (void *d, intptr_t n) {
  data *r;

  if (UNBOXED(d)) return BOX(0);
  else {
    r = TO_DATA(d);
    return BOX(get_tag(r) == ARRAY_TAG && get_len(r) == UNBOX(n));
  }
}

extern intptr_t Bstring_patt (void *x, void *y) {
  data *rx = (data *)BOX(NULL), *ry = (data *)BOX(NULL);

  ASSERT_STRING(".string_patt:2", y);

  if (UNBOXED(x)) return BOX(0);
  else {
    rx = TO_DATA(x);
    ry = TO_DATA(y);

    if (TAG(rx->data_header) != STRING_TAG) return BOX(0);

    return BOX(strcmp(rx->contents, ry->contents) == 0 ? 1 : 0);
  }
}

extern intptr_t Bclosure_tag_patt (void *x) {
  if (UNBOXED(x)) return BOX(0);

  return BOX(TAG(TO_DATA(x)->data_header) == CLOSURE_TAG);
}

extern intptr_t Bboxed_patt (void *x) { return BOX(UNBOXED(x) ? 0 : 1); }

extern intptr_t Bunboxed_patt (void *x) { return BOX(UNBOXED(x) ? 1 : 0); }

extern intptr_t Barray_tag_patt (void *x) {
  if (UNBOXED(x)) return BOX(0);

  return BOX(TAG(TO_DATA(x)->data_header) == ARRAY_TAG);
}

extern intptr_t Bstring_tag_patt (void *x) {
  if (UNBOXED(x)) return BOX(0);

  return BOX(TAG(TO_DATA(x)->data_header) == STRING_TAG);
}

extern intptr_t Bsexp_tag_patt (void *x) {
  if (UNBOXED(x)) return BOX(0);

  return BOX(TAG(TO_DATA(x)->data_header) == SEXP_TAG);
}

extern void *Bsta (void *x, intptr_t i, void *v) {
  if (UNBOXED(i)) {
    ASSERT_BOXED(".sta:3", x);
    data *d = TO_DATA(x);

    switch (TAG(d->data_header)) {
      case STRING_TAG: {
        ((char *)x)[UNBOX(i)] = (char)UNBOX(v);
        break;
      }
      case SEXP_TAG: {
        ((intptr_t *)((sexp *)d)->contents)[UNBOX(i)] = (intptr_t)v;
        break;
      }
      default: {
        ((intptr_t *)x)[UNBOX(i)] = (intptr_t)v;
      }
    }
  } else {
    *(void **)x = v;
  }

  return v;
}

extern void Bmatch_failure (void *v, char *fname, intptr_t line, intptr_t col) {
  createStringBuf();
  printValue(v);
  failure("match failure at %s:%ld:%ld, value '%s'\n",
          fname,
          UNBOX(line),
          UNBOX(col),
          stringBuf.contents);
}

extern void * /*Lstrcat*/ Li__Infix_4343 (intptr_t* args /* void *a, void *b */) {
  data *da = (data *)BOX(NULL);
  data *db = (data *)BOX(NULL);
  data *d  = (data *)BOX(NULL);

  ASSERT_STRING("++:1", args[0]);
  ASSERT_STRING("++:2", args[1]);

  da = TO_DATA(args[0]);
  db = TO_DATA(args[1]);

  PRE_GC();

  push_extra_root((void**)&args[0]);
  push_extra_root((void**)&args[1]);
  d = alloc_string(LEN(da->data_header) + LEN(db->data_header));
  pop_extra_root((void**)&args[1]);
  pop_extra_root((void**)&args[0]);

  da = TO_DATA(args[0]);
  db = TO_DATA(args[1]);

  char *d_contents = d->contents;
  const char *da_contents = da->contents;
  const char *db_contents = db->contents;
  strncpy(d_contents, da_contents, LEN(da->data_header));
  strncpy(d_contents + LEN(da->data_header), db_contents, LEN(db->data_header));
  d->contents[LEN(da->data_header) + LEN(db->data_header)] = 0;

  POST_GC();

  return d->contents;
}

extern void *LgetEnv (char *var) {
  char *e = getenv(var);
  void *s;

  if (e == NULL) return (void *)BOX(0);

  PRE_GC();

  s = Bstring((intptr_t*)&e);

  POST_GC();

  return s;
}

extern intptr_t Lsystem (char *cmd) { return BOX(system(cmd)); }

#ifndef X86_64
// In X86_64 we are not able to modify va_arg

static void fix_unboxed (char *s, va_list va) {
  intptr_t *p = (intptr_t *)va;
  intptr_t i = 0;

  while (*s) {
    if (*s == '%') {
      intptr_t n = p[i];
      if (UNBOXED(n)) { p[i] = UNBOX(n); }
      i++;
    }
    s++;
  }
}

extern void Lfailure (char *s, ...) {
  va_list args;

  va_start(args, s);
  fix_unboxed(s, args);
  vfailure(s, args);
}

extern void Lprintf (char *s, ...) {
    va_list args;   // = (va_list)BOX(NULL);

    ASSERT_STRING("printf:1", s);

    va_start(args, s);
    fix_unboxed(s, args);

    if (vprintf(s, args) < 0) { failure("fprintf (...): %s\n", strerror(errno)); }

    fflush(stdout);
}

extern void *Lsprintf (char *fmt, ...) {
    va_list args;
    void   *s;

    ASSERT_STRING("sprintf:1", fmt);

    va_start(args, fmt);
    fix_unboxed(fmt, args);

    createStringBuf();

    vprintStringBuf(fmt, args);

    PRE_GC();

    push_extra_root((void **)&fmt);
    void* content = stringBuf.contents;
    s = Bstring((intptr_t*)&content);
    pop_extra_root((void **)&fmt);

    POST_GC();

    deleteStringBuf();

    return s;
}

extern void Lfprintf (FILE *f, char *s, ...) {
    va_list args;   // = (va_list)BOX(NULL);

    ASSERT_BOXED("fprintf:1", f);
    ASSERT_STRING("fprintf:2", s);

    va_start(args, s);
    fix_unboxed(s, args);

    if (vfprintf(f, s, args) < 0) { failure("fprintf (...): %s\n", strerror(errno)); }
}

#else

extern void *Bsprintf (char *fmt, ...) {
    va_list args;
    void   *s;

    ASSERT_STRING("sprintf:1", fmt);

    va_start(args, fmt);

    createStringBuf();

    vprintStringBuf(fmt, args);

    PRE_GC();

    push_extra_root((void **)&fmt);
    void* content = stringBuf.contents;
    s = Bstring((intptr_t*)&content);
    pop_extra_root((void **)&fmt);

    POST_GC();

    deleteStringBuf();

    return s;
}

extern void Bprintf (char *s, ...) {
    va_list args;   // = (va_list)BOX(NULL);

    ASSERT_STRING("printf:1", s);

    va_start(args, s);

    if (vprintf(s, args) < 0) { failure("fprintf (...): %s\n", strerror(errno)); }

    fflush(stdout);
}

extern void Bfprintf (FILE *f, char *s, ...) {
    va_list args;   // = (va_list)BOX(NULL);

    ASSERT_BOXED("fprintf:1", f);
    ASSERT_STRING("fprintf:2", s);

    va_start(args, s);

    if (vfprintf(f, s, args) < 0) { failure("fprintf (...): %s\n", strerror(errno)); }
}

#endif

extern FILE *Lfopen (char *f, char *m) {
  FILE *h;

  ASSERT_STRING("fopen:1", f);
  ASSERT_STRING("fopen:2", m);

  h = fopen(f, m);

  if (h) return h;

  failure("fopen (\"%s\", \"%s\"): %s, %s, %s\n", f, m, strerror(errno));
  exit(1);
  return NULL;
}

extern void Lfclose (FILE *f) {
  ASSERT_BOXED("fclose", f);

  fclose(f);
}

extern void *LreadLine () {
  char *buf;

  errno = 0;

  if (scanf("%m[^\n]", &buf) == 1) {
    void *s = Bstring((intptr_t*)&buf);

    getchar();

    free(buf);
    return s;
  }

  if (errno != 0) failure("readLine (): %s\n", strerror(errno));

  return (void *)BOX(0);
}

extern void *Lfread (char *fname) {
  FILE *f;

  ASSERT_STRING("fread", fname);

  f = fopen(fname, "r");

  if (f && fseek(f, 0l, SEEK_END) >= 0) {
    long  size = ftell(f);
    void *s    = LmakeString(BOX(size));

    rewind(f);

    if (fread(s, 1, size, f) == size) {
      fclose(f);
      return s;
    }
  }

  failure("fread (\"%s\"): %s\n", fname, strerror(errno));
  exit(1);
  return NULL;
}

extern void Lfwrite (char *fname, char *contents) {
  FILE *f;

  ASSERT_STRING("fwrite:1", fname);
  ASSERT_STRING("fwrite:2", contents);

  f = fopen(fname, "w");

  if (f && !(fprintf(f, "%s", contents) < 0)) {
    fclose(f);
  } else {
    failure("fwrite (\"%s\"): %s\n", fname, strerror(errno));
  }
}

extern void *Lfexists (char *fname) {
  FILE *f;

  ASSERT_STRING("fexists", fname);

  f = fopen(fname, "r");

  if (f) return (void *)BOX(1);

  return (void *)BOX(0);
}

extern void *Lfst (void *v) { return Belem(v, BOX(0)); }

extern void *Lsnd (void *v) { return Belem(v, BOX(1)); }

extern void *Lhd (void *v) { return Belem(v, BOX(0)); }

extern void *Ltl (void *v) { return Belem(v, BOX(1)); }

/* Lread is an implementation of the "read" construct */
extern intptr_t Lread () {
  // int result = BOX(0);
  intptr_t result = BOX(0);

  printf(" > ");
  fflush(stdout);
  scanf("%" SCNdPTR, &result);

  return BOX(result);
}

extern int Lbinoperror (void) {
  fprintf(stderr, "ERROR: POINTER ARITHMETICS is forbidden; EXIT\n");
  exit(1);
}

extern int Lbinoperror2 (void) {
  fprintf(stderr, "ERROR: Comparing BOXED and UNBOXED value ; EXIT\n");
  exit(1);
}

/* Lwrite is an implementation of the "write" construct */
extern intptr_t Lwrite (intptr_t n) {
  printf("%" PRIdPTR "\n", UNBOX(n));
  fflush(stdout);

  return BOX(0);
}

extern intptr_t Lrandom (intptr_t n) {
  ASSERT_UNBOXED("Lrandom, 0", n);

  if (UNBOX(n) <= 0) { failure("invalid range in random: %ld\n", UNBOX(n)); }

  return BOX(random() % UNBOX(n));
}

extern intptr_t Ltime () {
  struct timespec t;

  clock_gettime(CLOCK_MONOTONIC_RAW, &t);

  return BOX(t.tv_sec * 1000000 + t.tv_nsec / 1000);
}

extern void set_args (intptr_t argc, char *argv[]) {
  intptr_t n = argc;
  intptr_t *p = NULL;
  intptr_t i;

  PRE_GC();

  p = LmakeArray(BOX(n));
  push_extra_root((void **)&p);

  for (i = 0; i < n; i++) {
    ((intptr_t *)p)[i] = (intptr_t)Bstring((intptr_t*)&argv[i]);
  }

  pop_extra_root((void **)&p);
  POST_GC();

  global_sysargs = p;

  push_extra_root((void **)&global_sysargs);
}
