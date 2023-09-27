#ifndef __LAMA_RUNTIME_COMMON__
#define __LAMA_RUNTIME_COMMON__
#include <stddef.h>

// this flag makes GC behavior a bit different for testing purposes.
//#define DEBUG_VERSION
//#define FULL_INVARIANT_CHECKS

#define STRING_TAG 0x00000001
#define ARRAY_TAG 0x00000003
#define SEXP_TAG 0x00000005
#define CLOSURE_TAG 0x00000007
#define UNBOXED_TAG 0x00000009   // Not actually a data_header; used to return from LkindOf

#define LEN(x) ((x & 0xFFFFFFF8) >> 3)
#define TAG(x) (x & 0x00000007)

#define SEXP_ONLY_HEADER_SZ (sizeof(int))

#ifndef DEBUG_VERSION
#  define DATA_HEADER_SZ (sizeof(size_t) + sizeof(int))
#else
#  define DATA_HEADER_SZ (sizeof(size_t) + sizeof(size_t) + sizeof(int))
#endif

#define MEMBER_SIZE sizeof(int)

#define TO_DATA(x) ((data *)((char *)(x)-DATA_HEADER_SZ))
#define TO_SEXP(x) ((sexp *)((char *)(x)-DATA_HEADER_SZ))

#define UNBOXED(x) (((int)(x)) & 0x0001)
#define UNBOX(x) (((int)(x)) >> 1)
#define BOX(x) ((((int)(x)) << 1) | 0x0001)

#define BYTES_TO_WORDS(bytes) (((bytes)-1) / sizeof(size_t) + 1)
#define WORDS_TO_BYTES(words) ((words) * sizeof(size_t))

// CAREFUL WITH DOUBLE EVALUATION!
#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

typedef struct {
  // store tag in the last three bits to understand what structure this is, other bits are filled with
  // other utility info (i.e., size for array, number of fields for s-expression)
  int data_header;

#ifdef DEBUG_VERSION
  size_t id;
#endif

  // last bit is used as MARK-BIT, the rest are used to store address where object should move
  // last bit can be used because due to alignment we can assume that last two bits are always 0's
  size_t forward_address;
  char   contents[0];
} data;

typedef struct {
  // store tag in the last three bits to understand what structure this is, other bits are filled with
  // other utility info (i.e., size for array, number of fields for s-expression)
  int data_header;

#ifdef DEBUG_VERSION
  size_t id;
#endif

  // last bit is used as MARK-BIT, the rest are used to store address where object should move
  // last bit can be used because due to alignment we can assume that last two bits are always 0's
  size_t forward_address;
  int    tag;
  int    contents[0];
} sexp;

#endif
