#ifndef __LAMA_RUNTIME_COMMON__
#define __LAMA_RUNTIME_COMMON__

#define DEBUG_VERSION

# define STRING_TAG  0x00000001
//# define STRING_TAG  0x00000000
# define ARRAY_TAG   0x00000003
//# define ARRAY_TAG   0x00000002
# define SEXP_TAG    0x00000005
//# define SEXP_TAG    0x00000004
# define CLOSURE_TAG 0x00000007
//# define CLOSURE_TAG 0x00000006
# define UNBOXED_TAG 0x00000009 // Not actually a data_header; used to return from LkindOf

# define LEN(x) ((x & 0xFFFFFFF8) >> 3)
# define TAG(x)  (x & 0x00000007)
//# define TAG(x)  (x & 0x00000006)


# define SEXP_ONLY_HEADER_SZ (2 * sizeof(int))
# ifndef DEBUG_VERSION
# define DATA_HEADER_SZ (sizeof(size_t) + sizeof(int))
# else
# define DATA_HEADER_SZ (sizeof(size_t) + sizeof(size_t) + sizeof(int))
#endif
# define MEMBER_SIZE sizeof(int)

# define TO_DATA(x) ((data*)((char*)(x)-DATA_HEADER_SZ))
# define TO_SEXP(x) ((sexp*)((char*)(x)-DATA_HEADER_SZ-SEXP_ONLY_HEADER_SZ))

# define UNBOXED(x)  (((int) (x)) &  0x0001)
# define UNBOX(x)    (((int) (x)) >> 1)
# define BOX(x)      ((((int) (x)) << 1) | 0x0001)

# define BYTES_TO_WORDS(bytes) (((bytes) - 1) / sizeof(size_t) + 1)
# define WORDS_TO_BYTES(words) ((words) * sizeof(size_t))

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
    char contents[0];
} data;

typedef struct {
    // duplicates contents.data_header in order to be able to understand if it is s-exp during iteration over heap
    int sexp_header;
    // stores hashed s-expression constructor name
    int tag;
    data contents;
} sexp;

#endif