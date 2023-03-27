#ifndef __LAMA_GC__
#define __LAMA_GC__

# define GET_MARK_BIT(x) (((int) (x)) & 1)
# define SET_MARK_BIT(x) (x = (((int) (x)) | 1))
# define RESET_MARK_BIT(x) (x = (((int) (x)) & (~1)))
# define GET_FORWARD_ADDRESS(x) (((int) (x)) & (~1)) // since last bit is used as mark-bit and due to correct alignment we can expect that last bit doesn't influence address (it should always be zero)
# define SET_FORWARD_ADDRESS(x, addr) (x = (((int) (x)) | ((int) (addr))))
# define EXTRA_ROOM_HEAP_COEFFICIENT 2 // TODO: tune this parameter
# define MINIMUM_HEAP_CAPACITY (1<<8) // TODO: tune this parameter


#include <stddef.h>
#include <stdbool.h>
#include "runtime_common.h"

// this flag makes GC behavior a bit different for testing purposes.
#define DEBUG_VERSION

typedef enum { ARRAY, CLOSURE, STRING, SEXP } lama_type;

typedef struct {
    size_t *current;
} heap_iterator;

typedef struct {
    // holds type of object, which fields we are iterating over
    lama_type type;
    // here a pointer to the object header is stored
    void *obj_ptr;
    void *cur_field;
} obj_field_iterator;

typedef struct {
    size_t * begin;
    size_t * end;
    size_t * current;
    size_t   size;
} memory_chunk;

/* GC extra roots */
# define MAX_EXTRA_ROOTS_NUMBER 32
typedef struct {
    int current_free;
    void ** roots[MAX_EXTRA_ROOTS_NUMBER];
} extra_roots_pool;

// the only GC-related function that should be exposed, others are useful for tests and internal implementation
// allocates object of the given size on the heap
void* alloc(size_t);
// takes number of words as a parameter
void* gc_alloc(size_t);
// takes number of words as a parameter
void *gc_alloc_on_existing_heap(size_t);

void collect();

// specific for mark-and-compact gc
void mark(void *obj);
// takes number of words that are required to be allocated somewhere on the heap
void compact(size_t additional_size);
// specific for Lisp-2 algorithm
size_t compute_locations();
void update_references(memory_chunk *);
void physically_relocate(memory_chunk *);


// written in ASM
extern void __gc_init           (void); // MANDATORY TO CALL BEFORE ANY INTERACTION WITH GC (apart from cases where we are working with virtual stack as happens in tests)
extern void __pre_gc            (void);
extern void __post_gc           (void);
extern void __gc_root_scan_stack(void); // TODO: write without ASM, since it is absolutely not necessary

// invoked from ASM
extern void gc_test_and_mark_root(size_t ** root);
inline bool is_valid_heap_pointer(const size_t *);

void clear_extra_roots (void);

void push_extra_root (void ** p);

void pop_extra_root (void ** p);


/* Functions for tests */

#ifdef DEBUG_VERSION

// test-only function, these pointer parameters are just a fancy way to return two values at a time
void objects_snapshot(void *objects_ptr, size_t objects_cnt);

// essential function to mock program stack
void set_stack(size_t stack_top, size_t stack_bottom);

// function to mock extra roots (Lama specific)
void set_extra_roots(size_t extra_roots_size, void** extra_roots_ptr);

#endif


/* Utility functions */

// takes a pointer to an object content as an argument, returns forwarding address
size_t get_forward_address(void *obj);

// takes a pointer to an object content as an argument, sets forwarding address to value 'addr'
size_t set_forward_address(void *obj, size_t addr);

// takes a pointer to an object content as an argument, returns whether this object was marked as live
bool is_marked(void *obj);

// takes a pointer to an object content as an argument, marks the object as live
void mark_object(void *obj);

// takes a pointer to an object content as an argument, marks the object as dead
void unmark_object(void *obj);

// returns iterator to an object with the lowest address
heap_iterator heap_begin_iterator();
void heap_next_obj_iterator(heap_iterator *it);
bool heap_is_done_iterator(heap_iterator *it);

// returns correct type when pointer to actual data is passed (header is excluded)
lama_type get_type_row_ptr(void *ptr);
// returns correct type when pointer to an object header is passed
lama_type get_type_header_ptr(void *ptr);

// returns correct object size (together with header) of an object, ptr is pointer to an actual data is passed (header is excluded)
size_t obj_size_row_ptr(void *ptr);
// returns correct object size (together with header) of an object, ptr is pointer to an object header
size_t obj_size_header_ptr(void *ptr);

// returns total padding size that we need to store given object type
size_t get_header_size(lama_type type);
// returns number of bytes that are required to allocate array with 'sz' elements (header included)
size_t array_size(size_t sz);
// returns number of bytes that are required to allocate string of length 'l' (header included)
size_t string_size(size_t len);
// TODO: ask if it is actually so? number of captured elements is actually sz-1 and 1 extra word is code ptr?
// returns number of bytes that are required to allocate closure with 'sz-1' captured values (header included)
size_t closure_size(size_t sz);
// returns number of bytes that are required to allocate s-expression with 'sz' fields (header included)
size_t sexp_size(size_t sz);

// returns an iterator over object fields, obj is ptr to object header
// (in case of s-exp, it is mandatory that obj ptr is very beginning of the object,
// considering that now we store two versions of header in there)
obj_field_iterator field_begin_iterator(void *obj);
// returns an iterator over object fields which are actual pointers, obj is ptr to object header
// (in case of s-exp, it is mandatory that obj ptr is very beginning of the object,
// considering that now we store two versions of header in there)
obj_field_iterator ptr_field_begin_iterator(void *obj);
// moves the iterator to next object field
void obj_next_field_iterator(obj_field_iterator *it);
// moves the iterator to the next object field which is an actual pointer
void obj_next_ptr_field_iterator(obj_field_iterator *it);
// returns if we are done iterating over fields of the object
bool field_is_done_iterator(obj_field_iterator *it);
// ptr is pointer to the actual object content, returns pointer to the very beginning of the object (header)
void* get_obj_header_ptr(void *ptr, lama_type type);
void* get_object_content_ptr(void *header_ptr);
void* get_end_of_obj(void *header_ptr);

#endif