// ============================================================================
//                              GC
// ============================================================================
// This is an implementation of a compactifying garbage collection algorithm.
// GC algorithm itself consists of two major stages:
//      1. Marking roots
//      2. Compacting stage
// Compacting is implemented in a very similar fashion to LISP2 algorithm,
// which is well-known.
// Most important pieces of code to discover to understand how everything works:
//  - void *gc_alloc (size_t): this function is basically called whenever we are
// not able to allocate memory on the existing heap via simple bump allocator.
//  - mark_phase(): this function will tell you everything you need to know
// about marking. I would also recommend to pay attention to the fact that
// marking is implemented without usage of any additional memory. Already
// allocated space is sufficient (for details see 'void mark (void *obj)').
//  - void compact_phase (size_t additional_size): the whole compaction phase
// can be understood by looking at this piece of code plus couple of other
// functions used in there. It is basically an implementation of LISP2.

#ifndef __LAMA_GC__
#define __LAMA_GC__

#include "runtime_common.h"

#define GET_MARK_BIT(x) (((int)(x)) & 1)
#define SET_MARK_BIT(x) (x = (((int)(x)) | 1))
#define IS_ENQUEUED(x) (((int)(x)) & 2)
#define MAKE_ENQUEUED(x) (x = (((int)(x)) | 2))
#define MAKE_DEQUEUED(x) (x = (((int)(x)) & (~2)))
#define RESET_MARK_BIT(x) (x = (((int)(x)) & (~1)))
// since last 2 bits are used for mark-bit and enqueued-bit and due to correct
// alignment we can expect that last 2 bits don't influence address (they
// should always be zero)
#define GET_FORWARD_ADDRESS(x) (((size_t)(x)) & (~3))
// take the last two bits as they are and make all others zero
#define SET_FORWARD_ADDRESS(x, addr) (x = ((x & 3) | ((int)(addr))))
// if heap is full after gc shows in how many times it has to be extended
#define EXTRA_ROOM_HEAP_COEFFICIENT 2
#ifdef DEBUG_VERSION
#  define MINIMUM_HEAP_CAPACITY (8)
#else
#  define MINIMUM_HEAP_CAPACITY (1 << 2)
#endif

#include <stdbool.h>
#include <stddef.h>

typedef enum { ARRAY, CLOSURE, STRING, SEXP } lama_type;

typedef struct {
  size_t *current;
} heap_iterator;

typedef struct {
  lama_type type;   // holds type of object, which fields we are iterating over
  void     *obj_ptr;   // place to store a pointer to the object header
  void     *cur_field;
} obj_field_iterator;

// Memory pool for linear memory allocation
typedef struct {
  size_t *begin;
  size_t *end;
  size_t *current;
  size_t  size;
} memory_chunk;


// the only GC-related function that should be exposed, others are useful for tests and internal implementation
// allocates object of the given size on the heap
void *alloc(size_t);
// takes number of words as a parameter
void *gc_alloc(size_t);
// takes number of words as a parameter
void *gc_alloc_on_existing_heap(size_t);

// specific for mark-and-compact_phase gc
void mark (void *obj);
void mark_phase (void);
// marks each pointer from extra roots
void scan_extra_roots (void);
#ifdef LAMA_ENV
// marks each valid pointer from global area
void scan_global_area (void);
#endif
// takes number of words that are required to be allocated somewhere on the heap
void compact_phase (size_t additional_size);
// specific for Lisp-2 algorithm
size_t compute_locations ();
void   update_references (memory_chunk *);
void   physically_relocate (memory_chunk *);


// ============================================================================
//                            GC extra roots
// ============================================================================
// Lama's program stack is continuous, i.e. it never interleaves with runtime
// function's activation records. But some valid Lama's pointers can escape
// into runtime. Those values (theirs stack addresses) has to be registered in
// an auxiliary data structure called `extra_roots_pool`.
// extra_roots_pool is a simple LIFO stack. During `pop` it compares that pop's
// argument is equal to the current stack top.
#define MAX_EXTRA_ROOTS_NUMBER 32

typedef struct {
  int    current_free;
  void **roots[MAX_EXTRA_ROOTS_NUMBER];
} extra_roots_pool;

void clear_extra_roots (void);
void push_extra_root (void **p);
void pop_extra_root (void **p);


// ============================================================================
//                   Implemented in GASM: see gc_runtime.s
// ============================================================================
// MANDATORY TO CALL BEFORE ANY INTERACTION WITH GC (apart from cases where we
// are working with virtual stack as happens in tests)
void __gc_init (void);

// should be called before interaction with GC in case of using in tests with
// virtual stack, otherwise it is automatically invoked by `__gc_init`
void __init (void);

// mostly useful for tests but basically you want to call this in case you want
// to deallocate all object allocated via GC
extern void __shutdown (void);


// ============================================================================
//                    invoked from GASM: see gc_runtime.s
// ============================================================================
extern void        gc_test_and_mark_root (size_t **root);
bool               is_valid_heap_pointer (const size_t *);
static inline bool is_valid_pointer (const size_t *);


// ============================================================================
//                     Auxiliary functions for tests
// ============================================================================
#if defined(DEBUG_VERSION)
// makes a snapshot of current objects in heap (both alive and dead), writes these ids to object_ids_buf,
// returns number of ids dumped
// object_ids_buf is pointer to area preallocated by user for dumping ids of objects in heap
// object_ids_buf_size is in WORDS, NOT BYTES
size_t objects_snapshot (int *object_ids_buf, size_t object_ids_buf_size);
#endif


#ifdef DEBUG_VERSION
// essential function to mock program stack
void set_stack (size_t stack_top, size_t stack_bottom);

// function to mock extra roots (Lama specific)
void set_extra_roots (size_t extra_roots_size, void **extra_roots_ptr);
#endif


// ============================================================================
//                          Utility functions
// ============================================================================
// accepts pointer to the start of the region and to the end of the region
// scans it and if it meets a pointer, it should be modified in according to forward address
void scan_and_fix_region (memory_chunk *old_heap, void *start, void *end);

// takes a pointer to an object content as an argument, returns forwarding address
size_t get_forward_address (void *obj);

// takes a pointer to an object content as an argument, sets forwarding address to value 'addr'
void set_forward_address (void *obj, size_t addr);

// takes a pointer to an object content as an argument, returns whether this object was marked as live
bool is_marked (void *obj);

// takes a pointer to an object content as an argument, marks the object as live
void mark_object (void *obj);

// takes a pointer to an object content as an argument, marks the object as dead
void unmark_object (void *obj);

// takes a pointer to an object content as an argument, returns whether this object was enqueued to the queue (which is used in mark phase)
bool is_enqueued (void *obj);

// takes a pointer to an object content as an argument, marks object as enqueued
void make_enqueued (void *obj);

// takes a pointer to an object content as an argument, unmarks object as enqueued
void make_dequeued (void *obj);

// returns iterator to an object with the lowest address
heap_iterator heap_begin_iterator ();
void          heap_next_obj_iterator (heap_iterator *it);
bool          heap_is_done_iterator (heap_iterator *it);

// returns correct type when pointer to actual data is passed (header is excluded)
lama_type get_type_row_ptr (void *ptr);
// returns correct type when pointer to an object header is passed
lama_type get_type_header_ptr (void *ptr);

// returns correct object size (together with header) of an object, ptr is pointer to an actual data is passed (header is excluded)
size_t obj_size_row_ptr (void *ptr);
// returns correct object size (together with header) of an object, ptr is pointer to an object header
size_t obj_size_header_ptr (void *ptr);

// returns total padding size that we need to store given object type
size_t get_header_size (lama_type type);

// returns number of bytes that are required to allocate array with 'sz' elements (header included)
size_t array_size (size_t sz);

// returns number of bytes that are required to allocate string of length 'l' (header included)
size_t string_size (size_t len);

// returns number of bytes that are required to allocate closure with 'sz-1' captured values (header included)
size_t closure_size (size_t sz);

// returns number of bytes that are required to allocate s-expression with 'members' fields (header included)
size_t sexp_size (size_t members);

// returns an iterator over object fields, obj is ptr to object header
// (in case of s-exp, it is mandatory that obj ptr is very beginning of the object,
// considering that now we store two versions of header in there)
obj_field_iterator field_begin_iterator (void *obj);

// returns an iterator over object fields which are actual pointers, obj is ptr to object header
// (in case of s-exp, it is mandatory that obj ptr is very beginning of the object,
// considering that now we store two versions of header in there)
obj_field_iterator ptr_field_begin_iterator (void *obj);

// moves the iterator to next object field
void obj_next_field_iterator (obj_field_iterator *it);

// moves the iterator to the next object field which is an actual pointer
void obj_next_ptr_field_iterator (obj_field_iterator *it);

// returns if we are done iterating over fields of the object
bool field_is_done_iterator (obj_field_iterator *it);

// ptr is pointer to the actual object content, returns pointer to the very beginning of the object (header)
void *get_obj_header_ptr (void *ptr);
void *get_object_content_ptr (void *header_ptr);
void *get_end_of_obj (void *header_ptr);

void *alloc_string (int len);
void *alloc_array (int len);
void *alloc_sexp (int members);
void *alloc_closure (int captured);

#endif
