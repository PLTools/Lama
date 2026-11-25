#ifndef __LAMA_RUNTIME_COMMON__
#define __LAMA_RUNTIME_COMMON__
#include <stddef.h>
#include <stdint.h>
#include <inttypes.h>
#include <limits.h>

// this flag makes GC behavior a bit different for testing purposes.
//#define DEBUG_VERSION
//#define FULL_INVARIANT_CHECKS

#if defined(__x86_64__) || defined(__ppc64__)
#define X86_64
#endif

// Every heap word, object header field and Lama value is pointer-sized: intptr_t for (boxed)
// Lama values, uintptr_t for header fields, addresses and raw heap words. C11 only guarantees
// that these types can hold a void * (they may be wider), so the runtime checks it here.
_Static_assert(sizeof(intptr_t) == sizeof(void *), "Lama runtime: intptr_t must be pointer-sized");
_Static_assert(sizeof(uintptr_t) == sizeof(void *), "Lama runtime: uintptr_t must be pointer-sized");

#define STRING_TAG 0x00000001
#define ARRAY_TAG 0x00000003
#define SEXP_TAG 0x00000005
#define CLOSURE_TAG 0x00000007
#define UNBOXED_TAG 0x00000009   // Not actually a data_header; used to return from LkindOf
#define LEN_MASK (UINTPTR_MAX ^ 7)
#define LEN(x) (uintptr_t)(((uintptr_t)x & LEN_MASK) >> 3)
#define TAG(x) (x & 7)

#ifndef DEBUG_VERSION
#  define DATA_HEADER_SZ (sizeof(uintptr_t) + sizeof(uintptr_t))
#else
#  define DATA_HEADER_SZ (sizeof(uintptr_t) + sizeof(uintptr_t) + sizeof(uintptr_t))
#endif

#define MEMBER_SIZE sizeof(uintptr_t)

#define TO_DATA(x) ((data *)((char *)(x)-DATA_HEADER_SZ))
#define TO_SEXP(x) ((sexp *)((char *)(x)-DATA_HEADER_SZ))

#define UNBOXED(x) (((intptr_t)(x)) & 1)
#define UNBOX(x) (((intptr_t)(x)) >> 1)
#define BOX(x) ((((intptr_t)(x)) << 1) | 1)

#define BYTES_TO_WORDS(bytes) (((bytes) - 1) / sizeof(size_t) + 1)
#define WORDS_TO_BYTES(words) ((words) * sizeof(size_t))

// CAREFUL WITH DOUBLE EVALUATION!
#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

typedef struct {
  // store tag in the last three bits to understand what structure this is, other bits are filled with
  // other utility info (i.e., size for array, number of fields for s-expression)
  uintptr_t data_header;

#ifdef DEBUG_VERSION
  size_t id;
#endif

  // last bit is used as MARK-BIT, the rest are used to store address where object should move
  // last bit can be used because due to alignment we can assume that last two bits are always 0's
  uintptr_t forward_address;
  char   contents[];
} data;

typedef struct {
  // store tag in the last three bits to understand what structure this is, other bits are filled with
  // other utility info (i.e., size for array, number of fields for s-expression)
  uintptr_t data_header;

#ifdef DEBUG_VERSION
  size_t id;
#endif

  // last bit is used as MARK-BIT, the rest are used to store address where object should move
  // last bit can be used because due to alignment we can assume that last two bits are always 0's
  uintptr_t forward_address;
  uintptr_t tag;
  char   contents[];
} sexp;

#endif
