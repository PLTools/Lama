# define _GNU_SOURCE 1

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/mman.h>
#include <string.h>
#include "gc.h"
#include "runtime_common.h"
#ifndef DEBUG_VERSION
static const size_t INIT_HEAP_SIZE = 1 << 18;
#else
static const size_t INIT_HEAP_SIZE = 8;
#endif
static const size_t SIZE_T_CHARS = sizeof(size_t)/sizeof(char);

#ifdef DEBUG_VERSION
static const size_t cur_id = 1;
#endif

static extra_roots_pool extra_roots;

extern size_t __gc_stack_top, __gc_stack_bottom;

static memory_chunk heap;

void* alloc(size_t size) {
    size = BYTES_TO_WORDS(size);
    void *p = gc_alloc_on_existing_heap(size);
    if (!p) {
        // not enough place in heap, need to perform GC cycle
        return gc_alloc(size);
    }
    return p;
}

void* gc_alloc_on_existing_heap(size_t size) {
    if (heap.current + size < heap.end) {
        void *p = (void *) heap.current;
        heap.current += size;
        return p;
    }
    return NULL;
}

void* gc_alloc(size_t size) {
    // mark phase
    // TODO: add extra roots and static area scan
    __gc_root_scan_stack();

    // compact phase
    compact(size);

    return gc_alloc_on_existing_heap(size);
}

void compact(size_t additional_size) {
    size_t live_size = compute_locations();

    size_t next_heap_size = MAX(live_size * EXTRA_ROOM_HEAP_COEFFICIENT + additional_size, MINIMUM_HEAP_CAPACITY);

    memory_chunk new_memory;
    new_memory.begin = mremap(
            heap.begin,
            WORDS_TO_BYTES(heap.size),
            WORDS_TO_BYTES(next_heap_size),
            MREMAP_MAYMOVE
            );
    if (new_memory.begin == MAP_FAILED) {
        perror ("ERROR: compact: mremap failed\n");
        exit   (1);
    }
    new_memory.end = new_memory.begin + next_heap_size;
    new_memory.size = next_heap_size;
    new_memory.current = new_memory.begin + live_size;

    update_references(&new_memory);
    physically_relocate(&new_memory);
}

size_t compute_locations() {
    size_t* free_ptr = heap.begin;
    heap_iterator scan_iter = heap_begin_iterator();

    for (; heap_is_done_iterator(&scan_iter); heap_next_obj_iterator(&scan_iter)) {
        void *header_ptr = scan_iter.current;
        void *obj_content = get_object_content_ptr(header_ptr);
        size_t sz = BYTES_TO_WORDS(obj_size_header_ptr(header_ptr));
        if (is_marked(obj_content)) {
            // forward address is responsible for object header pointer
            set_forward_address(obj_content, (size_t) free_ptr);
            free_ptr += sz;
        }
    }

    // it will return number of words
    return scan_iter.current - heap.begin;
}

// TODO: fix pointers on stack and in static area
void update_references(memory_chunk *next_memory) {
    heap_iterator it = heap_begin_iterator();
    while (!heap_is_done_iterator(&it)) {
        for (
                obj_field_iterator field_iter = ptr_field_begin_iterator(it.current);
                !field_is_done_iterator(&field_iter);
                obj_next_ptr_field_iterator(&field_iter)
                ) {
            void *field_obj_content = *(void **) field_iter.cur_field; // TODO: create iterator method 'dereference', so that code would be a bit more readable
            // important, we calculate new_addr very carefully here, because objects may relocate to another memory chunk
            size_t *new_addr = next_memory->begin + ((size_t *) get_forward_address(field_obj_content) - heap.begin);
            // update field reference to point to new_addr
            // since, we want fields to point to actual content, we need to add this extra content_offset
            // because forward_address itself is pointer to object header
            size_t content_offset = get_header_size(get_type_row_ptr(field_obj_content));
            * (void **) field_iter.cur_field = new_addr + content_offset;
        }
        heap_next_obj_iterator(&it);
    }
}

void physically_relocate(memory_chunk *next_memory) {
    heap_iterator from_iter = heap_begin_iterator();

    while (!heap_is_done_iterator(&from_iter)) {
        void *obj = get_object_content_ptr(from_iter.current);
        if (is_marked(obj)) {
            // Move the object from its old location to its new location relative to
            // the heap's (possibly new) location, 'to' points to future object header
            void* to = next_memory->begin + ((size_t *) get_forward_address(obj) - heap.begin);
            memmove(to, from_iter.current, BYTES_TO_WORDS(obj_size_header_ptr(obj)));
            unmark_object(to + ((size_t *) obj - from_iter.current));
        }
        heap_next_obj_iterator(&from_iter);
    }
}

bool is_valid_heap_pointer(const size_t *p) {
    return !UNBOXED(p) && (size_t) heap.begin <= (size_t) p && (size_t) p < (size_t) heap.end;
}

void mark(void *obj) {
    if (!is_valid_heap_pointer(obj)) {
        return;
    }
    if (is_marked(obj)) {
        return;
    }
    mark_object(obj);
    void *header_ptr = get_obj_header_ptr(obj, get_type_row_ptr(obj));
    for (
            obj_field_iterator ptr_field_it = ptr_field_begin_iterator(header_ptr);
            !field_is_done_iterator(&ptr_field_it);
            obj_next_ptr_field_iterator(&ptr_field_it)
    ) {
        mark(ptr_field_it.cur_field);
    }
}

extern void gc_test_and_mark_root(size_t ** root) {
    mark((void*) *root);
}

extern void __init (void) {
    size_t space_size = INIT_HEAP_SIZE * sizeof(size_t);

    srandom (time (NULL));

    heap.begin = mmap (NULL, space_size, PROT_READ | PROT_WRITE,
                             MAP_PRIVATE | MAP_ANONYMOUS | MAP_32BIT, -1, 0);
    if (heap.begin == MAP_FAILED) {
        perror ("ERROR: __init: mmap failed\n");
        exit   (1);
    }
    heap.end   = heap.begin + INIT_HEAP_SIZE;
    heap.size  = INIT_HEAP_SIZE;
    heap.current   = heap.begin;
    clear_extra_roots();
}

void clear_extra_roots (void) {
    extra_roots.current_free = 0;
}

void push_extra_root (void ** p) {
    if (extra_roots.current_free >= MAX_EXTRA_ROOTS_NUMBER) {
        perror ("ERROR: push_extra_roots: extra_roots_pool overflow");
        exit   (1);
    }
    extra_roots.roots[extra_roots.current_free] = p;
    extra_roots.current_free++;
}

void pop_extra_root (void ** p) {
    if (extra_roots.current_free == 0) {
        perror ("ERROR: pop_extra_root: extra_roots are empty");
        exit   (1);
    }
    extra_roots.current_free--;
    if (extra_roots.roots[extra_roots.current_free] != p) {
        perror ("ERROR: pop_extra_root: stack invariant violation");
        exit   (1);
    }
}

/* Functions for tests */

#ifdef DEBUG_VERSION

void objects_snapshot(void *objects_ptr, size_t objects_cnt) {
    size_t *ids_ptr = (size_t *) objects_ptr;
    size_t i = 0;
    for (
            heap_iterator it = heap_begin_iterator();
            !heap_is_done_iterator(&it) && i < objects_cnt;
            heap_next_obj_iterator(&it)
    ) {
        void *header_ptr = it.current;
        data *d = TO_DATA(get_object_content_ptr(header_ptr));
        ids_ptr[i] = d->id;
    }
}

void set_stack(size_t stack_top, size_t stack_bottom) {
    __gc_stack_top = stack_top;
    __gc_stack_bottom = stack_bottom;
}

void set_extra_roots(size_t extra_roots_size, void **extra_roots_ptr) {
    memcpy(extra_roots.roots, extra_roots_ptr, MIN(sizeof(extra_roots.roots), extra_roots_size));
    clear_extra_roots();
}

#endif


/* Utility functions */

size_t get_forward_address(void *obj) {
    data *d = TO_DATA(obj);
    return GET_FORWARD_ADDRESS(d->forward_address);
}

size_t set_forward_address(void *obj, size_t addr) {
    data *d = TO_DATA(obj);
    SET_FORWARD_ADDRESS(d->forward_address, addr);
}

bool is_marked(void *obj) {
    data *d = TO_DATA(obj);
    int mark_bit = GET_MARK_BIT(d->forward_address);
    return mark_bit;
}

void mark_object(void *obj) {
    data *d = TO_DATA(obj);
    SET_MARK_BIT(d->forward_address);
}

void unmark_object(void *obj) {
    data *d = TO_DATA(obj);
    RESET_MARK_BIT(d->forward_address);
}

heap_iterator heap_begin_iterator() {
    heap_iterator it = { .current=heap.begin };
    return it;
}

void heap_next_obj_iterator(heap_iterator *it) {
    void *ptr = it->current;
    size_t obj_size = obj_size_header_ptr(ptr);
    // make sure we take alignment into consideration
    obj_size = BYTES_TO_WORDS(obj_size);
    it->current += obj_size;
}

bool heap_is_done_iterator(heap_iterator *it) {
    return it->current >= heap.current;
}

lama_type get_type_row_ptr(void *ptr) {
    data *data_ptr = TO_DATA(ptr);
    return get_type_header_ptr(data_ptr);
}

lama_type get_type_header_ptr(void *ptr) {
    int *header = (int *) ptr;
    switch (TAG(*header)) {
        case ARRAY_TAG:
            return ARRAY;
        case STRING_TAG:
            return STRING;
        case CLOSURE_TAG:
            return CLOSURE;
        case SEXP_TAG:
            return SEXP;
        default:
            perror ("ERROR: get_type_header_ptr: unknown object header");
            exit   (1);
    }
}

size_t obj_size_row_ptr(void *ptr) {
    data *data_ptr = TO_DATA(ptr);
    return obj_size_header_ptr(data_ptr);
}

size_t obj_size_header_ptr(void *ptr) {
    int len = LEN(*(int *) ptr);
    switch (get_type_header_ptr(ptr)) {
        case ARRAY:
            return array_size(len);
        case STRING:
            return string_size(len);
        case CLOSURE:
            return closure_size(len);
        case SEXP:
            return sexp_size(len);
        default:
            perror ("ERROR: obj_size_header_ptr: unknown object header");
            exit   (1);
    }
}

size_t array_size(size_t sz) {
    return get_header_size(ARRAY) + MEMBER_SIZE * sz;
}

size_t string_size(size_t len) {
    // string should be null terminated
    return get_header_size(STRING) + len + 1;
}

size_t closure_size(size_t sz) {
    return get_header_size(CLOSURE) + MEMBER_SIZE * sz;
}

size_t sexp_size(size_t sz) {
    return get_header_size(SEXP) + MEMBER_SIZE * sz;
}


obj_field_iterator field_begin_iterator(void *obj) {
    lama_type type = get_type_row_ptr(obj);
    obj_field_iterator it = { .type=type, .obj_ptr=get_obj_header_ptr(obj, type), .cur_field=obj };
    // since string doesn't have any actual fields we set cur_field to the end of object
    if (type == STRING) {
        it.cur_field = get_end_of_obj(it.obj_ptr);
    }
    return it;
}

obj_field_iterator ptr_field_begin_iterator(void *obj) {
    obj_field_iterator it = field_begin_iterator(obj);
    // corner case when obj has no fields
    if (field_is_done_iterator(&it)) {
        return it;
    }
    if (is_valid_heap_pointer(it.cur_field)) {
        return it;
    }
    obj_next_ptr_field_iterator(&it);
    return it;
}

void obj_next_field_iterator(obj_field_iterator *it) {
    it->cur_field += MEMBER_SIZE;
}

void obj_next_ptr_field_iterator(obj_field_iterator *it) {
    do {
        obj_next_field_iterator(it);
    } while (!field_is_done_iterator(it) && !is_valid_heap_pointer(it->cur_field));
}

bool field_is_done_iterator(obj_field_iterator *it) {
    return it->cur_field >= get_end_of_obj(it->obj_ptr);
}

void* get_obj_header_ptr(void *ptr, lama_type type) {
    return ptr - get_header_size(type);
}

void* get_object_content_ptr(void *header_ptr) {
    lama_type type = get_type_header_ptr(header_ptr);
    return header_ptr + get_header_size(type);
}

void* get_end_of_obj(void *header_ptr) {
    return header_ptr + obj_size_header_ptr(header_ptr);
}

size_t get_header_size(lama_type type) {
    switch (type) {
        case STRING:
        case CLOSURE:
        case ARRAY:
            return DATA_HEADER_SZ;
        case SEXP:
            return SEXP_ONLY_HEADER_SZ + DATA_HEADER_SZ;
        default:
            perror ("ERROR: get_header_size: unknown object type");
            exit   (1);
    }
}

