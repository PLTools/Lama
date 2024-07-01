#ifndef __LAMA_RUNTIME_COMMON__
#define __LAMA_RUNTIME_COMMON__
#include <stddef.h>
#include <inttypes.h>
#include <limits.h>

// this flag makes GC behavior a bit different for testing purposes.
//#define DEBUG_VERSION
//#define FULL_INVARIANT_CHECKS

#if defined(__x86_64__) || defined(__ppc64__)
#define X86_64
#endif

typedef size_t ptrt;  // pointer type, because can hold a pointer on a corresponding platform

#ifdef X86_64
typedef int64_t aint;  // adaptive int
typedef uint64_t auint;  // adaptive unsigned int
#define PRIdAI PRId64
#define SCNdAI SCNd64
#else
typedef int32_t aint;  // adaptive int
typedef uint32_t auint;  // adaptive unsigned int
#define PRIdAI PRId32
#define SCNdAI SCNd32
#endif

#define STRING_TAG 0x00000001
#define ARRAY_TAG 0x00000003
#define SEXP_TAG 0x00000005
#define CLOSURE_TAG 0x00000007
#define UNBOXED_TAG 0x00000009   // Not actually a data_header; used to return from LkindOf
#ifdef X86_64
#define LEN_MASK (UINT64_MAX^7)
#else
#define LEN_MASK (UINT32_MAX^7)
#endif
#define LEN(x) (ptrt)(((ptrt)x & LEN_MASK) >> 3)
#define TAG(x) (x & 7)

#ifndef DEBUG_VERSION
#  define DATA_HEADER_SZ (sizeof(auint) + sizeof(ptrt))
#else
#  define DATA_HEADER_SZ (sizeof(auint) + sizeof(ptrt) + sizeof(auint))
#endif

#define MEMBER_SIZE sizeof(ptrt)

#define TO_DATA(x) ((data *)((char *)(x)-DATA_HEADER_SZ))
#define TO_SEXP(x) ((sexp *)((char *)(x)-DATA_HEADER_SZ))

#define UNBOXED(x) (((aint)(x)) & 1)
#define UNBOX(x) (((aint)(x)) >> 1)
#define BOX(x) ((((aint)(x)) << 1) | 1)

#define BYTES_TO_WORDS(bytes) (((bytes) - 1) / sizeof(size_t) + 1)
#define WORDS_TO_BYTES(words) ((words) * sizeof(size_t))

// CAREFUL WITH DOUBLE EVALUATION!
#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

typedef struct {
  // store tag in the last three bits to understand what structure this is, other bits are filled with
  // other utility info (i.e., size for array, number of fields for s-expression)
  auint data_header;

#ifdef DEBUG_VERSION
  size_t id;
#endif

  // last bit is used as MARK-BIT, the rest are used to store address where object should move
  // last bit can be used because due to alignment we can assume that last two bits are always 0's
  ptrt forward_address;
  char   contents[];
} data;

typedef struct {
  // store tag in the last three bits to understand what structure this is, other bits are filled with
  // other utility info (i.e., size for array, number of fields for s-expression)
  auint data_header;

#ifdef DEBUG_VERSION
  size_t id;
#endif

  // last bit is used as MARK-BIT, the rest are used to store address where object should move
  // last bit can be used because due to alignment we can assume that last two bits are always 0's
  ptrt forward_address;
  auint   tag;
  char   contents[];
} sexp;

#endif
