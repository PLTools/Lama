/* Runtime library */

#define _GNU_SOURCE 1

#include "runtime.h"

#include "gc.h"
#include "runtime_common.h"

extern size_t __gc_stack_top, __gc_stack_bottom;

#define PRE_GC()                                                                                   \
  bool flag = false;                                                                               \
  flag      = __gc_stack_top == 0;                                                                 \
  if (flag) { __gc_stack_top = (size_t)__builtin_frame_address(0); }                               \
  assert(__gc_stack_top != 0);                                                                     \
  assert(__builtin_frame_address(0) <= (void *)__gc_stack_top);

#define POST_GC()                                                                                  \
  assert(__builtin_frame_address(0) <= (void *)__gc_stack_top);                                    \
  if (flag) { __gc_stack_top = 0; }

static void vfailure (char *s, va_list args) {
  fprintf(stderr, "*** FAILURE: ");
  vfprintf(stderr, s, args);   // vprintf (char *, va_list) <-> printf (char *, ...)
  exit(255);
}

void failure (char *s, ...) {
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

extern void *Bsexp (int n, ...);
extern int   LtagHash (char *);

void *global_sysargs;

// Gets a raw data_header
extern int LkindOf (void *p) {
  if (UNBOXED(p)) return UNBOXED_TAG;

  return TAG(TO_DATA(p)->data_header);
}

// Compare s-exprs tags
extern int LcompareTags (void *p, void *q) {
  data *pd, *qd;

  ASSERT_BOXED("compareTags, 0", p);
  ASSERT_BOXED("compareTags, 1", q);

  pd = TO_DATA(p);
  qd = TO_DATA(q);

  if (TAG(pd->data_header) == SEXP_TAG && TAG(qd->data_header) == SEXP_TAG) {
    return BOX((TO_SEXP(p)->tag) - (TO_SEXP(q)->tag));
  } else {
    failure("not a sexpr in compareTags: %d, %d\n", TAG(pd->data_header), TAG(qd->data_header));
  }
  // dead code
  return 0;
}

// Functional synonym for built-in operator ":";
void *Ls__Infix_58 (void *p, void *q) {
  void *res;

  PRE_GC();

  push_extra_root(&p);
  push_extra_root(&q);
  res = Bsexp(BOX(3), p, q, LtagHash("cons"));   //BOX(848787));
  pop_extra_root(&q);
  pop_extra_root(&p);

  POST_GC();

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
int Ls__Infix_6161 (void *p, void *q) { return BOX(p == q); }

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
  ASSERT_BOXED(".length", p);
  return BOX(LEN(TO_DATA(p)->data_header));
}

static char *chars = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'";

extern char *de_hash (int);

extern int LtagHash (char *s) {
  char *p;
  int   h = 0, limit = 0;

  p = s;

  while (*p && limit++ <= 4) {
    char *q   = chars;
    int   pos = 0;

    for (; *q && *q != *p; q++, pos++)
      ;

    if (*q) h = (h << 6) | pos;
    else failure("tagHash: character not found: %c\n", *p);

    p++;
  }

  if (strncmp(s, de_hash(h), 5) != 0) { failure("%s <-> %s\n", s, de_hash(h)); }

  return BOX(h);
}

char *de_hash (int n) {
  static char buf[6] = {0, 0, 0, 0, 0, 0};
  char       *p      = (char *)BOX(NULL);
  p                  = &buf[5];

  *p-- = 0;

  while (n != 0) {
    *p-- = chars[n & 0x003F];
    n    = n >> 6;
  }

  return ++p;
}

typedef struct {
  char *contents;
  int   ptr;
  int   len;
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
  int len = stringBuf.len << 1;

  stringBuf.contents = (char *)realloc(stringBuf.contents, len);
  stringBuf.len      = len;
}

static void vprintStringBuf (char *fmt, va_list args) {
  int     written = 0, rest = 0;
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
  int   i = BOX(0);
  if (UNBOXED(p)) {
    printStringBuf("%d", UNBOX(p));
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
          if (i) printValue((void *)((int *)a->contents)[i]);
          else printStringBuf("0x%x", (void *)((int *)a->contents)[i]);
          if (i != LEN(a->data_header) - 1) printStringBuf(", ");
        }
        printStringBuf(">");
        break;
      }
      case ARRAY_TAG: {
        printStringBuf("[");
        for (i = 0; i < LEN(a->data_header); i++) {
          printValue((void *)((int *)a->contents)[i]);
          if (i != LEN(a->data_header) - 1) printStringBuf(", ");
        }
        printStringBuf("]");
        break;
      }

      case SEXP_TAG: {
        sexp *sa  = (sexp *)a;
        char *tag = de_hash(sa->tag);
        if (strcmp(tag, "cons") == 0) {
          sexp *sb = sa;
          printStringBuf("{");
          while (LEN(sb->data_header)) {
            printValue((void *)((int *)sb->contents)[0]);
            int list_next = ((int *)sb->contents)[1];
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
              printValue((void *)((int *)sexp_a->contents)[i]);
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
  int   i;

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
            stringcat((void *)((int *)b->contents)[0]);
            int next_b = ((int *)b->contents)[1];
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

extern int Luppercase (void *v) {
  ASSERT_UNBOXED("Luppercase:1", v);
  return BOX(toupper((int)UNBOX(v)));
}

extern int Llowercase (void *v) {
  ASSERT_UNBOXED("Llowercase:1", v);
  return BOX(tolower((int)UNBOX(v)));
}

extern int LmatchSubString (char *subj, char *patt, int pos) {
  data *p = TO_DATA(patt), *s = TO_DATA(subj);
  int   n;

  ASSERT_STRING("matchSubString:1", subj);
  ASSERT_STRING("matchSubString:2", patt);
  ASSERT_UNBOXED("matchSubString:3", pos);

  n = LEN(p->data_header);

  if (n + UNBOX(pos) > LEN(s->data_header)) return BOX(0);

  return BOX(strncmp(subj + UNBOX(pos), patt, n) == 0);
}

extern void *Lsubstring (void *subj, int p, int l) {
  data *d  = TO_DATA(subj);
  int   pp = UNBOX(p), ll = UNBOX(l);

  ASSERT_STRING("substring:1", subj);
  ASSERT_UNBOXED("substring:2", p);
  ASSERT_UNBOXED("substring:3", l);

  if (pp + ll <= LEN(d->data_header)) {
    data *r;

    PRE_GC();

    push_extra_root(&subj);
    r = (data *)alloc_string(ll);
    pop_extra_root(&subj);

    strncpy(r->contents, (char *)subj + pp, ll);

    POST_GC();

    return r->contents;
  }

  failure("substring: index out of bounds (position=%d, length=%d, \
            subject length=%d)",
          pp,
          ll,
          LEN(d->data_header));
}

extern struct re_pattern_buffer *Lregexp (char *regexp) {
  regex_t *b = (regex_t *)malloc(sizeof(regex_t));

  /* printf ("regexp: %s,\t%x\n", regexp, b); */

  memset(b, 0, sizeof(regex_t));

  int n = (int)re_compile_pattern(regexp, strlen(regexp), b);

  if (n != 0) { failure("%", strerror(n)); };

  return b;
}

extern int LregexpMatch (struct re_pattern_buffer *b, char *s, int pos) {
  int res;

  ASSERT_BOXED("regexpMatch:1", b);
  ASSERT_STRING("regexpMatch:2", s);
  ASSERT_UNBOXED("regexpMatch:3", pos);

  res = re_match(b, s, LEN(TO_DATA(s)->data_header), UNBOX(pos), 0);

  /* printf ("regexpMatch %x: %s, res=%d\n", b, s+UNBOX(pos), res); */

  if (res) { return BOX(res); }

  return BOX(res);
}

extern void *Bstring (void *);

void *Lclone (void *p) {
  data *obj;
  sexp *sobj;
  void *res;
  int   n;
  if (UNBOXED(p)) return p;

  PRE_GC();

  data *a = TO_DATA(p);
  int   t = TAG(a->data_header), l = LEN(a->data_header);

  push_extra_root(&p);
  switch (t) {
    case STRING_TAG: res = Bstring(TO_DATA(p)->contents); break;

    case ARRAY_TAG:
      obj = (data *)alloc_array(l);
      memcpy(obj, TO_DATA(p), array_size(l));
      res = (void *)obj->contents;
      break;
    case CLOSURE_TAG:
      obj = (data *)alloc_closure(l);
      memcpy(obj, TO_DATA(p), closure_size(l));
      res = (void *)(obj->contents);
      break;

    case SEXP_TAG:
      obj = (data *)alloc_sexp(l);
      memcpy(obj, TO_DATA(p), sexp_size(l));
      res = (void *)obj->contents;
      break;

    default: failure("invalid data_header %d in clone *****\n", t);
  }
  pop_extra_root(&p);

  POST_GC();
  return res;
}

#define HASH_DEPTH 3
#define HASH_APPEND(acc, x)                                                                        \
  (((acc + (unsigned)x) << (WORD_SIZE / 2)) | ((acc + (unsigned)x) >> (WORD_SIZE / 2)))

int inner_hash (int depth, unsigned acc, void *p) {
  if (depth > HASH_DEPTH) return acc;

  if (UNBOXED(p)) return HASH_APPEND(acc, UNBOX(p));
  else if (is_valid_heap_pointer(p)) {
    data *a = TO_DATA(p);
    int   t = TAG(a->data_header), l = LEN(a->data_header), i;

    acc = HASH_APPEND(acc, t);
    acc = HASH_APPEND(acc, l);

    switch (t) {
      case STRING_TAG: {
        char *p = a->contents;

        while (*p) {
          int n = (int)*p++;
          acc   = HASH_APPEND(acc, n);
        }

        return acc;
      }

      case CLOSURE_TAG:
        acc = HASH_APPEND(acc, ((void **)a->contents)[0]);
        i   = 1;
        break;

      case ARRAY_TAG: i = 0; break;

      case SEXP_TAG: {
        int ta = TO_SEXP(p)->tag;
        acc    = HASH_APPEND(acc, ta);
        i      = 1;
        ++l;
        break;
      }

      default: failure("invalid data_header %d in hash *****\n", t);
    }

    for (; i < l; i++) acc = inner_hash(depth + 1, acc, ((void **)a->contents)[i]);

    return acc;
  } else return HASH_APPEND(acc, p);
}

extern void *LstringInt (char *b) {
  int n;
  sscanf(b, "%d", &n);
  return (void *)BOX(n);
}

extern int Lhash (void *p) { return BOX(0x3fffff & inner_hash(0, 0, p)); }

extern int LflatCompare (void *p, void *q) {
  if (UNBOXED(p)) {
    if (UNBOXED(q)) { return BOX(UNBOX(p) - UNBOX(q)); }

    return -1;
  } else if (~UNBOXED(q)) {
    return BOX(p - q);
  } else BOX(1);
}

extern int Lcompare (void *p, void *q) {
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
        int   ta = TAG(a->data_header), tb = TAG(b->data_header);
        int   la = LEN(a->data_header), lb = LEN(b->data_header);
        int   i;
        int   shift = 0;

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
            int tag_a = TO_SEXP(p)->tag, tag_b = TO_SEXP(q)->tag;
            COMPARE_AND_RETURN(tag_a, tag_b);
            COMPARE_AND_RETURN(la, lb);
            i     = 0;
            shift = 1;
            break;
          }

          default: failure("invalid data_header %d in compare *****\n", ta);
        }

        for (; i < la; i++) {
          int c = Lcompare(((void **)a->contents)[i + shift], ((void **)b->contents)[i + shift]);
          if (c != BOX(0)) return c;
        }
        return BOX(0);
      } else return BOX(-1);
    } else if (is_valid_heap_pointer(q)) return BOX(1);
    else return BOX(p - q);
  }
}

extern void *Belem (void *p, int i) {
  data *a = (data *)BOX(NULL);

  if (UNBOXED(p)) { ASSERT_BOXED(".elem:1", p); }
  ASSERT_UNBOXED(".elem:2", i);

  a = TO_DATA(p);
  i = UNBOX(i);

  switch (TAG(a->data_header)) {
    case STRING_TAG: return (void *)BOX(a->contents[i]);
    case SEXP_TAG: return (void *)((int *)a->contents)[i + 1];
    default: return (void *)((int *)a->contents)[i];
  }
}

extern void *LmakeArray (int length) {
  data *r;
  int   n, *p;

  ASSERT_UNBOXED("makeArray:1", length);

  PRE_GC();

  n = UNBOX(length);
  r = (data *)alloc_array(n);

  p = (int *)r->contents;
  while (n--) *p++ = BOX(0);

  POST_GC();

  return r->contents;
}

extern void *LmakeString (int length) {
  int   n = UNBOX(length);
  data *r;

  ASSERT_UNBOXED("makeString", length);

  PRE_GC();

  r = (data *)alloc_string(n);   // '\0' in the end of the string is taken into account

  POST_GC();

  return r->contents;
}

extern void *Bstring (void *p) {
  int   n = strlen(p);
  void *s = NULL;

  PRE_GC();

  push_extra_root(&p);
  s = LmakeString(BOX(n));
  pop_extra_root(&p);
  strncpy((char *)&TO_DATA(s)->contents, p, n + 1);   // +1 because of '\0' in the end of C-strings

  POST_GC();

  return s;
}

extern void *Lstringcat (void *p) {
  void *s;

  /* ASSERT_BOXED("stringcat", p); */

  PRE_GC();

  createStringBuf();
  stringcat(p);

  push_extra_root(&p);
  s = Bstring(stringBuf.contents);
  pop_extra_root(&p);

  deleteStringBuf();

  POST_GC();

  return s;
}

extern void *Lstring (void *p) {
  void *s = (void *)BOX(NULL);

  PRE_GC();

  createStringBuf();
  printValue(p);

  push_extra_root(&p);
  s = Bstring(stringBuf.contents);
  pop_extra_root(&p);

  deleteStringBuf();

  POST_GC();

  return s;
}

extern void *Bclosure (int bn, void *entry, ...) {
  va_list       args;
  int           i, ai;
  register int *ebp asm("ebp");
  size_t       *argss;
  data         *r;
  int           n = UNBOX(bn);

  PRE_GC();

  argss = (ebp + 12);
  for (i = 0; i < n; i++, argss++) { push_extra_root((void **)argss); }

  r = (data *)alloc_closure(n + 1);
  push_extra_root((void **)&r);
  ((void **)r->contents)[0] = entry;

  va_start(args, entry);

  for (i = 0; i < n; i++) {
    ai                          = va_arg(args, int);
    ((int *)r->contents)[i + 1] = ai;
  }

  va_end(args);

  POST_GC();

  pop_extra_root((void **)&r);
  argss--;
  for (i = 0; i < n; i++, argss--) { pop_extra_root((void **)argss); }
  return r->contents;
}

extern void *Barray (int bn, ...) {
  va_list args;
  int     i, ai;
  data   *r;
  int     n = UNBOX(bn);

  PRE_GC();

  r = (data *)alloc_array(n);

  va_start(args, bn);

  for (i = 0; i < n; i++) {
    ai                      = va_arg(args, int);
    ((int *)r->contents)[i] = ai;
  }

  va_end(args);

  POST_GC();
  return r->contents;
}

#ifdef DEBUG_VERSION
extern memory_chunk heap;
#endif

extern void *Bsexp (int bn, ...) {
  va_list args;
  int     i;
  int     ai;
  size_t *p;
  data   *r;
  int     n = UNBOX(bn);

  PRE_GC();

  int fields_cnt   = n - 1;
  r                = (data *)alloc_sexp(fields_cnt);
  ((sexp *)r)->tag = 0;

  va_start(args, bn);

  for (i = 1; i < n; i++) {
    ai                      = va_arg(args, int);
    p                       = (size_t *)ai;
    ((int *)r->contents)[i] = ai;
  }

  ((sexp *)r)->tag = UNBOX(va_arg(args, int));

  va_end(args);

  POST_GC();
  return (int *)r->contents;
}

extern int Btag (void *d, int t, int n) {
  data *r;

  if (UNBOXED(d)) return BOX(0);
  else {
    r = TO_DATA(d);
    return BOX(TAG(r->data_header) == SEXP_TAG && TO_SEXP(d)->tag == UNBOX(t)
               && LEN(r->data_header) == UNBOX(n));
  }
}

int get_tag (data *d) { return TAG(d->data_header); }

int get_len (data *d) { return LEN(d->data_header); }

extern int Barray_patt (void *d, int n) {
  data *r;

  if (UNBOXED(d)) return BOX(0);
  else {
    r = TO_DATA(d);
    return BOX(get_tag(r) == ARRAY_TAG && get_len(r) == UNBOX(n));
  }
}

extern int Bstring_patt (void *x, void *y) {
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

extern int Bclosure_tag_patt (void *x) {
  if (UNBOXED(x)) return BOX(0);

  return BOX(TAG(TO_DATA(x)->data_header) == CLOSURE_TAG);
}

extern int Bboxed_patt (void *x) { return BOX(UNBOXED(x) ? 0 : 1); }

extern int Bunboxed_patt (void *x) { return BOX(UNBOXED(x) ? 1 : 0); }

extern int Barray_tag_patt (void *x) {
  if (UNBOXED(x)) return BOX(0);

  return BOX(TAG(TO_DATA(x)->data_header) == ARRAY_TAG);
}

extern int Bstring_tag_patt (void *x) {
  if (UNBOXED(x)) return BOX(0);

  return BOX(TAG(TO_DATA(x)->data_header) == STRING_TAG);
}

extern int Bsexp_tag_patt (void *x) {
  if (UNBOXED(x)) return BOX(0);

  return BOX(TAG(TO_DATA(x)->data_header) == SEXP_TAG);
}

extern void *Bsta (void *v, int i, void *x) {
  if (UNBOXED(i)) {
    ASSERT_BOXED(".sta:3", x);
    data *d = TO_DATA(x);

    switch (TAG(d->data_header)) {
      case STRING_TAG: {
        ((char *)x)[UNBOX(i)] = (char)UNBOX(v);
        break;
      }
      case SEXP_TAG: {
        ((int *)x)[UNBOX(i) + 1] = (int)v;
        break;
      }
      default: {
        ((int *)x)[UNBOX(i)] = (int)v;
      }
    }
  } else {
    *(void **)x = v;
  }

  return v;
}

static void fix_unboxed (char *s, va_list va) {
  size_t *p = (size_t *)va;
  int     i = 0;

  while (*s) {
    if (*s == '%') {
      size_t n = p[i];
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

extern void Bmatch_failure (void *v, char *fname, int line, int col) {
  createStringBuf();
  printValue(v);
  failure("match failure at %s:%d:%d, value '%s'\n",
          fname,
          UNBOX(line),
          UNBOX(col),
          stringBuf.contents);
}

extern void * /*Lstrcat*/ Li__Infix_4343 (void *a, void *b) {
  data *da = (data *)BOX(NULL);
  data *db = (data *)BOX(NULL);
  data *d  = (data *)BOX(NULL);

  ASSERT_STRING("++:1", a);
  ASSERT_STRING("++:2", b);

  da = TO_DATA(a);
  db = TO_DATA(b);

  PRE_GC();

  push_extra_root(&a);
  push_extra_root(&b);
  d = alloc_string(LEN(da->data_header) + LEN(db->data_header));
  pop_extra_root(&b);
  pop_extra_root(&a);

  da = TO_DATA(a);
  db = TO_DATA(b);

  strncpy(d->contents, da->contents, LEN(da->data_header));
  strncpy(d->contents + LEN(da->data_header), db->contents, LEN(db->data_header));
  d->contents[LEN(da->data_header) + LEN(db->data_header)] = 0;

  POST_GC();

  return d->contents;
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
  s = Bstring(stringBuf.contents);
  pop_extra_root((void **)&fmt);

  POST_GC();

  deleteStringBuf();

  return s;
}

extern void *LgetEnv (char *var) {
  char *e = getenv(var);
  void *s;

  if (e == NULL) return (void *)BOX(0);

  PRE_GC();

  s = Bstring(e);

  POST_GC();

  return s;
}

extern int Lsystem (char *cmd) { return BOX(system(cmd)); }

extern void Lfprintf (FILE *f, char *s, ...) {
  va_list args = (va_list)BOX(NULL);

  ASSERT_BOXED("fprintf:1", f);
  ASSERT_STRING("fprintf:2", s);

  va_start(args, s);
  fix_unboxed(s, args);

  if (vfprintf(f, s, args) < 0) { failure("fprintf (...): %s\n", strerror(errno)); }
}

extern void Lprintf (char *s, ...) {
  va_list args = (va_list)BOX(NULL);

  ASSERT_STRING("printf:1", s);

  va_start(args, s);
  fix_unboxed(s, args);

  if (vprintf(s, args) < 0) { failure("fprintf (...): %s\n", strerror(errno)); }

  fflush(stdout);
}

extern FILE *Lfopen (char *f, char *m) {
  FILE *h;

  ASSERT_STRING("fopen:1", f);
  ASSERT_STRING("fopen:2", m);

  h = fopen(f, m);

  if (h) return h;

  failure("fopen (\"%s\", \"%s\"): %s, %s, %s\n", f, m, strerror(errno));
}

extern void Lfclose (FILE *f) {
  ASSERT_BOXED("fclose", f);

  fclose(f);
}

extern void *LreadLine () {
  char *buf;

  if (scanf("%m[^\n]", &buf) == 1) {
    void *s = Bstring(buf);

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
extern int Lread () {
  int result = BOX(0);

  printf("> ");
  fflush(stdout);
  scanf("%d", &result);

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
extern int Lwrite (int n) {
  printf("%d\n", UNBOX(n));
  fflush(stdout);

  return 0;
}

extern int Lrandom (int n) {
  ASSERT_UNBOXED("Lrandom, 0", n);

  if (UNBOX(n) <= 0) { failure("invalid range in random: %d\n", UNBOX(n)); }

  return BOX(random() % UNBOX(n));
}

extern int Ltime () {
  struct timespec t;

  clock_gettime(CLOCK_MONOTONIC_RAW, &t);

  return BOX(t.tv_sec * 1000000 + t.tv_nsec / 1000);
}

extern void set_args (int argc, char *argv[]) {
  data *a;
  int   n = argc;
  int  *p = NULL;
  int   i;

  PRE_GC();

  p = LmakeArray(BOX(n));
  push_extra_root((void **)&p);

  for (i = 0; i < n; i++) { ((int *)p)[i] = (int)Bstring(argv[i]); }

  pop_extra_root((void **)&p);
  POST_GC();

  global_sysargs = p;

  push_extra_root((void **)&global_sysargs);
}
