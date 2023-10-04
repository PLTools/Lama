#define _GNU_SOURCE 1

#include "gc.h"

#include "runtime_common.h"

#include <assert.h>
#include <execinfo.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

static const size_t INIT_HEAP_SIZE = MINIMUM_HEAP_CAPACITY;

#ifdef DEBUG_VERSION
size_t cur_id = 0;
#endif

static extra_roots_pool extra_roots;

size_t __gc_stack_top = 0, __gc_stack_bottom = 0;
#ifdef LAMA_ENV
extern const size_t __start_custom_data, __stop_custom_data;
#endif

#ifdef DEBUG_VERSION
memory_chunk heap;
#else
static memory_chunk heap;
#endif

#ifdef DEBUG_VERSION
void dump_heap ();
#endif

void handler (int sig) {
  void *array[10];
  int   size;

  // get void*'s for all entries on the stack
  size = backtrace(array, 10);
  fprintf(stderr, "heap size is %zu\n", heap.size);
  backtrace_symbols_fd(array, size, STDERR_FILENO);
  exit(1);
}

void *alloc (size_t size) {
#ifdef DEBUG_VERSION
  ++cur_id;
#endif
  size_t bytes_sz = size;
  size            = BYTES_TO_WORDS(size);
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "allocation of size %zu words (%zu bytes): ", size, bytes_sz);
#endif
  void *p = gc_alloc_on_existing_heap(size);
  if (!p) {
    // not enough place in the heap, need to perform GC cycle
    p = gc_alloc(size);
  }
  return p;
}

#ifdef FULL_INVARIANT_CHECKS

// precondition: obj_content is a valid address pointing to the content of an object
static void print_object_info (FILE *f, void *obj_content) {
  data  *d       = TO_DATA(obj_content);
  size_t obj_tag = TAG(d->data_header);
  size_t obj_id  = d->id;
  fprintf(f, "id %zu tag %zu | ", obj_id, obj_tag);
}

static void print_unboxed (FILE *f, int unboxed) { fprintf(f, "unboxed %zu | ", unboxed); }

static FILE *print_stack_content (char *filename) {
  FILE *f = fopen(filename, "w+");
  ftruncate(fileno(f), 0);
  fprintf(f, "Stack content:\n");
  for (size_t *stack_ptr = (size_t *)((void *)__gc_stack_top + 4);
       stack_ptr < (size_t *)__gc_stack_bottom;
       ++stack_ptr) {
    size_t value = *stack_ptr;
    if (is_valid_heap_pointer((size_t *)value)) {
      fprintf(f, "%p, ", (void *)value);
      print_object_info(f, (void *)value);
    } else {
      print_unboxed(f, (int)value);
    }
    fprintf(f, "\n");
  }
  fprintf(f, "Stack content end.\n");
  return f;
}

// precondition: obj_content is a valid address pointing to the content of an object
static void objects_dfs (FILE *f, void *obj_content) {
  void *obj_header = get_obj_header_ptr(obj_content);
  data *obj_data   = TO_DATA(obj_content);
  // internal mark-bit for this dfs, should be recovered by the caller
  if ((obj_data->forward_address & 2) != 0) { return; }
  // set this bit as 1
  obj_data->forward_address |= 2;
  fprintf(f, "object at addr %p: ", obj_content);
  print_object_info(f, obj_content);
  /*fprintf(f, "object id: %zu | ", obj_data->id);*/
  // first cycle: print object's fields
  for (obj_field_iterator field_it = ptr_field_begin_iterator(obj_header);
       !field_is_done_iterator(&field_it);
       obj_next_field_iterator(&field_it)) {
    size_t field_value = *(size_t *)field_it.cur_field;
    if (is_valid_heap_pointer((size_t *)field_value)) {
      print_object_info(f, (void *)field_value);
      /*fprintf(f, "%zu ", TO_DATA(field_value)->id);*/
    } else {
      print_unboxed(f, (int)field_value);
    }
  }
  fprintf(f, "\n");
  for (obj_field_iterator field_it = ptr_field_begin_iterator(obj_header);
       !field_is_done_iterator(&field_it);
       obj_next_field_iterator(&field_it)) {
    size_t field_value = *(size_t *)field_it.cur_field;
    if (is_valid_heap_pointer((size_t *)field_value)) { objects_dfs(f, (void *)field_value); }
  }
}

FILE *print_objects_traversal (char *filename, bool marked) {
  FILE *f = fopen(filename, "w+");
  ftruncate(fileno(f), 0);
  for (heap_iterator it = heap_begin_iterator(); !heap_is_done_iterator(&it);
       heap_next_obj_iterator(&it)) {
    void *obj_header = it.current;
    data *obj_data   = TO_DATA(get_object_content_ptr(obj_header));
    if ((obj_data->forward_address & 1) == marked) {
      objects_dfs(f, get_object_content_ptr(obj_header));
    }
  }

  // resetting bit that represent mark-bit for this internal dfs-traversal
  for (heap_iterator it = heap_begin_iterator(); !heap_is_done_iterator(&it);
       heap_next_obj_iterator(&it)) {
    void *obj_header = it.current;
    data *obj_data   = TO_DATA(get_object_content_ptr(obj_header));
    obj_data->forward_address &= (~2);
  }
  fflush(f);

  // print extra roots
  for (int i = 0; i < extra_roots.current_free; i++) {
    fprintf(f, "extra root %p %p: ", extra_roots.roots[i], *(size_t **)extra_roots.roots[i]);
  }
  fflush(f);
  return f;
}

int files_cmp (FILE *f1, FILE *f2) {
  int symbol1, symbol2;
  int position = 0;
  while (true) {
    symbol1 = fgetc(f1);
    symbol2 = fgetc(f2);
    if (symbol1 == EOF && symbol2 == EOF) { return -1; }
    if (symbol1 != symbol2) { return position; }
    ++position;
  }
}

#endif

void *gc_alloc_on_existing_heap (size_t size) {
  if (heap.current + size <= heap.end) {
    void *p = (void *)heap.current;
    heap.current += size;
    memset(p, 0, size * sizeof(size_t));
    return p;
  }
  return NULL;
}

void *gc_alloc (size_t size) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "===============================GC cycle has started\n");
#endif
#ifdef FULL_INVARIANT_CHECKS
  FILE *stack_before = print_stack_content("stack-dump-before-compaction");
  FILE *heap_before  = print_objects_traversal("before-mark", 0);
  fclose(heap_before);
#endif
  mark_phase();
#ifdef FULL_INVARIANT_CHECKS
  FILE *heap_before_compaction = print_objects_traversal("after-mark", 1);
#endif

  compact_phase(size);
#ifdef FULL_INVARIANT_CHECKS
  FILE *stack_after           = print_stack_content("stack-dump-after-compaction");
  FILE *heap_after_compaction = print_objects_traversal("after-compaction", 0);

  int pos = files_cmp(stack_before, stack_after);
  if (pos >= 0) {   // position of difference is found
    fprintf(stderr, "Stack is modified incorrectly, see position %d\n", pos);
    exit(1);
  }
  fclose(stack_before);
  fclose(stack_after);
  pos = files_cmp(heap_before_compaction, heap_after_compaction);
  if (pos >= 0) {   // position of difference is found
    fprintf(stderr, "GC invariant is broken, pos is %d\n", pos);
    exit(1);
  }
  fclose(heap_before_compaction);
  fclose(heap_after_compaction);
#endif
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "===============================GC cycle has finished\n");
#endif
  return gc_alloc_on_existing_heap(size);
}

static void gc_root_scan_stack () {
  for (size_t *p = (size_t *)(__gc_stack_top + 4); p < (size_t *)__gc_stack_bottom; ++p) {
    gc_test_and_mark_root((size_t **)p);
  }
}

void mark_phase (void) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "marking has started\n");
  fprintf(stderr,
          "gc_root_scan_stack has started: gc_top=%p bot=%p\n",
          (void *)__gc_stack_top,
          (void *)__gc_stack_bottom);
#endif
  gc_root_scan_stack();
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "gc_root_scan_stack has finished\n");
  fprintf(stderr, "scan_extra_roots has started\n");
#endif
  scan_extra_roots();
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "scan_extra_roots has finished\n");
  fprintf(stderr, "scan_global_area has started\n");
#endif
#ifdef LAMA_ENV
  scan_global_area();
#endif
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "scan_global_area has finished\n");
  fprintf(stderr, "marking has finished\n");
#endif
}

void compact_phase (size_t additional_size) {
  size_t live_size = compute_locations();

  // all in words
  size_t next_heap_size =
      MAX(live_size * EXTRA_ROOM_HEAP_COEFFICIENT + additional_size, MINIMUM_HEAP_CAPACITY);
  size_t next_heap_pseudo_size = MAX(next_heap_size, heap.size);

  memory_chunk old_heap = heap;
  heap.begin            = mremap(
      heap.begin, WORDS_TO_BYTES(heap.size), WORDS_TO_BYTES(next_heap_pseudo_size), MREMAP_MAYMOVE);
  if (heap.begin == MAP_FAILED) {
    perror("ERROR: compact_phase: mremap failed\n");
    exit(1);
  }
  heap.end     = heap.begin + next_heap_pseudo_size;
  heap.size    = next_heap_pseudo_size;
  heap.current = heap.begin + (old_heap.current - old_heap.begin);

  update_references(&old_heap);
  physically_relocate(&old_heap);

  heap.current = heap.begin + live_size;
}

size_t compute_locations () {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC compute_locations started\n");
#endif
  size_t       *free_ptr  = heap.begin;
  heap_iterator scan_iter = heap_begin_iterator();

  for (; !heap_is_done_iterator(&scan_iter); heap_next_obj_iterator(&scan_iter)) {
    void *header_ptr  = scan_iter.current;
    void *obj_content = get_object_content_ptr(header_ptr);
    if (is_marked(obj_content)) {
      size_t sz = BYTES_TO_WORDS(obj_size_header_ptr(header_ptr));
      // forward address is responsible for object header pointer
      set_forward_address(obj_content, (size_t)free_ptr);
      free_ptr += sz;
    }
  }

#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC compute_locations finished\n");
#endif
  // it will return number of words
  return free_ptr - heap.begin;
}

void scan_and_fix_region (memory_chunk *old_heap, void *start, void *end) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC scan_and_fix_region started\n");
#endif
  for (size_t *ptr = (size_t *)start; ptr < (size_t *)end; ++ptr) {
    size_t ptr_value = *ptr;
    // this can't be expressed via is_valid_heap_pointer, because this pointer may point area corresponding to the old
    // heap
    if (is_valid_pointer((size_t *)ptr_value) && (size_t)old_heap->begin <= ptr_value
        && ptr_value <= (size_t)old_heap->current) {
      void *obj_ptr = (void *)heap.begin + ((void *)ptr_value - (void *)old_heap->begin);
      void *new_addr =
          (void *)heap.begin + ((void *)get_forward_address(obj_ptr) - (void *)old_heap->begin);
      size_t content_offset = get_header_size(get_type_row_ptr(obj_ptr));
      *(void **)ptr         = new_addr + content_offset;
    }
  }
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC scan_and_fix_region finished\n");
#endif
}

void scan_and_fix_region_roots (memory_chunk *old_heap) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "extra roots started: number of extra roots %i\n", extra_roots.current_free);
#endif
  for (int i = 0; i < extra_roots.current_free; i++) {
    size_t *ptr       = (size_t *)extra_roots.roots[i];
    size_t  ptr_value = *ptr;
    if (!is_valid_pointer((size_t *)ptr_value)) { continue; }
    // skip this one since it was already fixed from scanning the stack
    if ((extra_roots.roots[i] >= (void **)__gc_stack_top
         && extra_roots.roots[i] < (void **)__gc_stack_bottom)
#ifdef LAMA_ENV
        || (extra_roots.roots[i] <= (void **)&__stop_custom_data
            && extra_roots.roots[i] >= (void **)&__start_custom_data)
#endif
    ) {
#ifdef DEBUG_VERSION
      if (is_valid_heap_pointer((size_t *)ptr_value)) {
#  ifdef DEBUG_PRINT
        fprintf(stderr,
                "|\tskip extra root: %p (%p), since it points to Lama's stack top=%p bot=%p\n",
                extra_roots.roots[i],
                (void *)ptr_value,
                (void *)__gc_stack_top,
                (void *)__gc_stack_bottom);
#  endif
      }
#  ifdef LAMA_ENV
      else if ((extra_roots.roots[i] <= (void *)&__stop_custom_data
                && extra_roots.roots[i] >= (void *)&__start_custom_data)) {
        fprintf(
            stderr,
            "|\tskip extra root: %p (%p), since it points to Lama's static area stop=%p start=%p\n",
            extra_roots.roots[i],
            (void *)ptr_value,
            (void *)&__stop_custom_data,
            (void *)&__start_custom_data);
        exit(1);
      }
#  endif
      else {
#  ifdef DEBUG_PRINT
        fprintf(stderr,
                "|\tskip extra root: %p (%p): not a valid Lama pointer \n",
                extra_roots.roots[i],
                (void *)ptr_value);
#  endif
      }
#endif
      continue;
    }
    if ((size_t)old_heap->begin <= ptr_value && ptr_value <= (size_t)old_heap->current) {
      void *obj_ptr = (void *)heap.begin + ((void *)ptr_value - (void *)old_heap->begin);
      void *new_addr =
          (void *)heap.begin + ((void *)get_forward_address(obj_ptr) - (void *)old_heap->begin);
      size_t content_offset = get_header_size(get_type_row_ptr(obj_ptr));
      *(void **)ptr         = new_addr + content_offset;
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
      fprintf(stderr,
              "|\textra root (%p) %p -> %p\n",
              extra_roots.roots[i],
              (void *)ptr_value,
              (void *)*ptr);
#endif
    }
  }
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "|\textra roots finished\n");
#endif
}

void update_references (memory_chunk *old_heap) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC update_references started\n");
#endif
  heap_iterator it = heap_begin_iterator();
  while (!heap_is_done_iterator(&it)) {
    if (is_marked(get_object_content_ptr(it.current))) {
      for (obj_field_iterator field_iter = ptr_field_begin_iterator(it.current);
           !field_is_done_iterator(&field_iter);
           obj_next_ptr_field_iterator(&field_iter)) {

        size_t *field_value = *(size_t **)field_iter.cur_field;
        if (field_value < old_heap->begin || field_value > old_heap->current) { continue; }
        // this pointer should also be modified according to old_heap->begin
        void *field_obj_content_addr =
            (void *)heap.begin + (*(void **)field_iter.cur_field - (void *)old_heap->begin);
        // important, we calculate new_addr very carefully here, because objects may relocate to another memory chunk
        void *new_addr =
            heap.begin
            + ((size_t *)get_forward_address(field_obj_content_addr) - (size_t *)old_heap->begin);
        // update field reference to point to new_addr
        // since, we want fields to point to an actual content, we need to add this extra content_offset
        // because forward_address itself is a pointer to the object's header
        size_t content_offset = get_header_size(get_type_row_ptr(field_obj_content_addr));
#ifdef DEBUG_VERSION
        if (!is_valid_heap_pointer((void *)(new_addr + content_offset))) {
#  ifdef DEBUG_PRINT
          fprintf(stderr,
                  "ur: incorrect pointer assignment: on object with id %d",
                  TO_DATA(get_object_content_ptr(it.current))->id);
#  endif
          exit(1);
        }
#endif
        *(void **)field_iter.cur_field = new_addr + content_offset;
      }
    }
    heap_next_obj_iterator(&it);
  }
  // fix pointers from stack
  scan_and_fix_region(old_heap, (void *)__gc_stack_top + 4, (void *)__gc_stack_bottom + 4);

  // fix pointers from extra_roots
  scan_and_fix_region_roots(old_heap);

#ifdef LAMA_ENV
  assert((void *)&__stop_custom_data >= (void *)&__start_custom_data);
  scan_and_fix_region(old_heap, (void *)&__start_custom_data, (void *)&__stop_custom_data);
#endif
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC update_references finished\n");
#endif
}

void physically_relocate (memory_chunk *old_heap) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC physically_relocate started\n");
#endif
  heap_iterator from_iter = heap_begin_iterator();

  while (!heap_is_done_iterator(&from_iter)) {
    void         *obj       = get_object_content_ptr(from_iter.current);
    heap_iterator next_iter = from_iter;
    heap_next_obj_iterator(&next_iter);
    if (is_marked(obj)) {
      // Move the object from its old location to its new location relative to
      // the heap's (possibly new) location, 'to' points to future object header
      size_t *to = heap.begin + ((size_t *)get_forward_address(obj) - (size_t *)old_heap->begin);
      memmove(to, from_iter.current, obj_size_header_ptr(from_iter.current));
      unmark_object(get_object_content_ptr(to));
    }
    from_iter = next_iter;
  }
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC physically_relocate finished\n");
#endif
}

inline bool is_valid_heap_pointer (const size_t *p) {
  return !UNBOXED(p) && (size_t)heap.begin <= (size_t)p && (size_t)p <= (size_t)heap.current;
}

static inline bool is_valid_pointer (const size_t *p) { return !UNBOXED(p); }

static inline void queue_enqueue (heap_iterator *tail_iter, void *obj) {
  void *tail         = tail_iter->current;
  void *tail_content = get_object_content_ptr(tail);
  set_forward_address(tail_content, (size_t)obj);
  make_enqueued(obj);
  heap_next_obj_iterator(tail_iter);
}

static inline void *queue_dequeue (heap_iterator *head_iter) {
  void *head         = head_iter->current;
  void *head_content = get_object_content_ptr(head);
  void *value        = (void *)get_forward_address(head_content);
  make_dequeued(value);
  heap_next_obj_iterator(head_iter);
  return value;
}

void mark (void *obj) {
  if (!is_valid_heap_pointer(obj) || is_marked(obj)) { return; }

  // TL;DR: [q_head_iter, q_tail_iter) q_head_iter -- current dequeue's victim, q_tail_iter -- place for next enqueue
  // in forward_address of corresponding element we store address of element to be removed after dequeue operation
  heap_iterator q_head_iter = heap_begin_iterator();
  // iterator where we will write address of the element that is going to be enqueued
  heap_iterator q_tail_iter = q_head_iter;
  queue_enqueue(&q_tail_iter, obj);

  // invariant: queue contains only objects that are valid heap pointers (each corresponding to content of unmarked
  // object) also each object is in queue only once
  while (q_head_iter.current != q_tail_iter.current) {
    // while the queue is non-empty
    void *cur_obj = queue_dequeue(&q_head_iter);
    mark_object(cur_obj);
    void *header_ptr = get_obj_header_ptr(cur_obj);
    for (obj_field_iterator ptr_field_it = ptr_field_begin_iterator(header_ptr);
         !field_is_done_iterator(&ptr_field_it);
         obj_next_ptr_field_iterator(&ptr_field_it)) {
      void *field_value = *(void **)ptr_field_it.cur_field;
      if (!is_valid_heap_pointer(field_value) || is_marked(field_value)
          || is_enqueued(field_value)) {
        continue;
      }
      // if we came to this point it must be true that field_value is unmarked and not currently in queue
      // thus, we maintain the invariant
      queue_enqueue(&q_tail_iter, field_value);
    }
  }
}

void scan_extra_roots (void) {
  for (int i = 0; i < extra_roots.current_free; ++i) {
    // this dereferencing is safe since runtime is pushing correct pointers into extra_roots
    mark(*extra_roots.roots[i]);
  }
}

#ifdef LAMA_ENV
void scan_global_area (void) {
  // __start_custom_data is pointing to beginning of global area, thus all dereferencings are safe
  for (size_t *ptr = (size_t *)&__start_custom_data; ptr < (size_t *)&__stop_custom_data; ++ptr) {
    mark(*(void **)ptr);
  }
}
#endif

extern void gc_test_and_mark_root (size_t **root) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr,
          "\troot = %p (%p), stack addresses: [%p, %p)\n",
          root,
          *root,
          (void *)__gc_stack_top + 4,
          (void *)__gc_stack_bottom);
#endif
  mark((void *)*root);
}

void __gc_init (void) {
  __gc_stack_bottom = (size_t)__builtin_frame_address(1) + 4;
  __init();
}

void __init (void) {
  signal(SIGSEGV, handler);
  size_t space_size = INIT_HEAP_SIZE * sizeof(size_t);

  srandom(time(NULL));

  heap.begin = mmap(
      NULL, space_size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_32BIT, -1, 0);
  if (heap.begin == MAP_FAILED) {
    perror("ERROR: __init: mmap failed\n");
    exit(1);
  }
  heap.end     = heap.begin + INIT_HEAP_SIZE;
  heap.size    = INIT_HEAP_SIZE;
  heap.current = heap.begin;
  clear_extra_roots();
}

extern void __shutdown (void) {
  munmap(heap.begin, heap.size);
#ifdef DEBUG_VERSION
  cur_id = 0;
#endif
  heap.begin        = NULL;
  heap.end          = NULL;
  heap.size         = 0;
  heap.current      = NULL;
  __gc_stack_top    = 0;
  __gc_stack_bottom = 0;
}

void clear_extra_roots (void) { extra_roots.current_free = 0; }

void push_extra_root (void **p) {
  if (extra_roots.current_free >= MAX_EXTRA_ROOTS_NUMBER) {
    perror("ERROR: push_extra_roots: extra_roots_pool overflow\n");
    exit(1);
  }
  assert(p >= (void **)__gc_stack_top || p < (void **)__gc_stack_bottom);
  extra_roots.roots[extra_roots.current_free] = p;
  extra_roots.current_free++;
}

void pop_extra_root (void **p) {
  if (extra_roots.current_free == 0) {
    perror("ERROR: pop_extra_root: extra_roots are empty\n");
    exit(1);
  }
  extra_roots.current_free--;
  if (extra_roots.roots[extra_roots.current_free] != p) {
    perror("ERROR: pop_extra_root: stack invariant violation\n");
    exit(1);
  }
}

/* Functions for tests */

#if defined(DEBUG_VERSION)
size_t objects_snapshot (int *object_ids_buf, size_t object_ids_buf_size) {
  size_t *ids_ptr = (size_t *)object_ids_buf;
  size_t  i       = 0;
  for (heap_iterator it = heap_begin_iterator();
       !heap_is_done_iterator(&it) && i < object_ids_buf_size;
       heap_next_obj_iterator(&it), ++i) {
    void *header_ptr = it.current;
    data *d          = TO_DATA(get_object_content_ptr(header_ptr));
    ids_ptr[i]       = d->id;
  }
  return i;
}
#endif

#ifdef DEBUG_VERSION
extern char *de_hash (int);

void dump_heap () {
  size_t i = 0;
  for (heap_iterator it = heap_begin_iterator(); !heap_is_done_iterator(&it);
       heap_next_obj_iterator(&it), ++i) {
    void     *header_ptr  = it.current;
    void     *content_ptr = get_object_content_ptr(header_ptr);
    data     *d           = TO_DATA(content_ptr);
    lama_type t           = get_type_header_ptr(header_ptr);
    switch (t) {
      case ARRAY: fprintf(stderr, "of kind ARRAY\n"); break;
      case CLOSURE: fprintf(stderr, "of kind CLOSURE\n"); break;
      case STRING: fprintf(stderr, "of kind STRING\n"); break;
      case SEXP:
        fprintf(stderr, "of kind SEXP with tag %s\n", de_hash(TO_SEXP(content_ptr)->tag));
        break;
    }
  }
}

void set_stack (size_t stack_top, size_t stack_bottom) {
  __gc_stack_top    = stack_top;
  __gc_stack_bottom = stack_bottom;
}

void set_extra_roots (size_t extra_roots_size, void **extra_roots_ptr) {
  memcpy(extra_roots.roots, extra_roots_ptr, MIN(sizeof(extra_roots.roots), extra_roots_size));
  clear_extra_roots();
}

#endif

/* Utility functions */

size_t get_forward_address (void *obj) {
  data *d = TO_DATA(obj);
  return GET_FORWARD_ADDRESS(d->forward_address);
}

void set_forward_address (void *obj, size_t addr) {
  data *d = TO_DATA(obj);
  SET_FORWARD_ADDRESS(d->forward_address, addr);
}

bool is_marked (void *obj) {
  data *d        = TO_DATA(obj);
  int   mark_bit = GET_MARK_BIT(d->forward_address);
  return mark_bit;
}

void mark_object (void *obj) {
  data *d = TO_DATA(obj);
  SET_MARK_BIT(d->forward_address);
}

void unmark_object (void *obj) {
  data *d = TO_DATA(obj);
  RESET_MARK_BIT(d->forward_address);
}

bool is_enqueued (void *obj) {
  data *d = TO_DATA(obj);
  return IS_ENQUEUED(d->forward_address) != 0;
}

void make_enqueued (void *obj) {
  data *d = TO_DATA(obj);
  MAKE_ENQUEUED(d->forward_address);
}

void make_dequeued (void *obj) {
  data *d = TO_DATA(obj);
  MAKE_DEQUEUED(d->forward_address);
}

heap_iterator heap_begin_iterator () {
  heap_iterator it = {.current = heap.begin};
  return it;
}

void heap_next_obj_iterator (heap_iterator *it) {
  void  *ptr      = it->current;
  size_t obj_size = obj_size_header_ptr(ptr);
  // make sure we take alignment into consideration
  obj_size = BYTES_TO_WORDS(obj_size);
  it->current += obj_size;
}

bool heap_is_done_iterator (heap_iterator *it) { return it->current >= heap.current; }

lama_type get_type_row_ptr (void *ptr) {
  data *data_ptr = TO_DATA(ptr);
  return get_type_header_ptr(data_ptr);
}

lama_type get_type_header_ptr (void *ptr) {
  int *header = (int *)ptr;
  switch (TAG(*header)) {
    case ARRAY_TAG: return ARRAY;
    case STRING_TAG: return STRING;
    case CLOSURE_TAG: return CLOSURE;
    case SEXP_TAG: return SEXP;
    default: {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
      fprintf(stderr, "ERROR: get_type_header_ptr: unknown object header, cur_id=%d", cur_id);
      raise(SIGINT);   // only for debug purposes
#else
#  ifdef FULL_INVARIANT_CHECKS
#    ifdef DEBUG_PRINT
      fprintf(stderr,
              "ERROR: get_type_header_ptr: unknown object header, ptr is %p, tag %i, heap size is "
              "%d cur_id=%d stack_top=%p stack_bot=%p ",
              ptr,
              TAG(*header),
              heap.size,
              cur_id,
              (void *)__gc_stack_top,
              (void *)__gc_stack_bottom);
#    endif
      FILE *heap_before_compaction = print_objects_traversal("dump_kill", 1);
      fclose(heap_before_compaction);
#  endif
      kill(getpid(), SIGSEGV);
#endif
      exit(1);
    }
  }
}

size_t obj_size_row_ptr (void *ptr) {
  data *data_ptr = TO_DATA(ptr);
  return obj_size_header_ptr(data_ptr);
}

size_t obj_size_header_ptr (void *ptr) {
  int len = LEN(*(int *)ptr);
  switch (get_type_header_ptr(ptr)) {
    case ARRAY: return array_size(len);
    case STRING: return string_size(len);
    case CLOSURE: return closure_size(len);
    case SEXP: return sexp_size(len);
    default: {
#ifdef DEBUG_VERSION
      fprintf(stderr, "ERROR: obj_size_header_ptr: unknown object header, cur_id=%d", cur_id);
      raise(SIGINT);   // only for debug purposes
#else
      perror("ERROR: obj_size_header_ptr: unknown object header\n");
#endif
      exit(1);
    }
  }
}

size_t array_size (size_t sz) { return get_header_size(ARRAY) + MEMBER_SIZE * sz; }

size_t string_size (size_t len) {
  // string should be null terminated
  return get_header_size(STRING) + len + 1;
}

size_t closure_size (size_t sz) { return get_header_size(CLOSURE) + MEMBER_SIZE * sz; }

size_t sexp_size (size_t members) { return get_header_size(SEXP) + MEMBER_SIZE * (members + 1); }

obj_field_iterator field_begin_iterator (void *obj) {
  lama_type          type = get_type_header_ptr(obj);
  obj_field_iterator it = {.type = type, .obj_ptr = obj, .cur_field = get_object_content_ptr(obj)};
  switch (type) {
    case STRING: {
      it.cur_field = get_end_of_obj(it.obj_ptr);
      break;
    }
    case CLOSURE:
    case SEXP: {
      it.cur_field += MEMBER_SIZE;
      break;
    }
    default: break;
  }
  return it;
}

obj_field_iterator ptr_field_begin_iterator (void *obj) {
  obj_field_iterator it = field_begin_iterator(obj);
  // corner case when obj has no fields
  if (field_is_done_iterator(&it)) { return it; }
  if (is_valid_pointer(*(size_t **)it.cur_field)) { return it; }
  obj_next_ptr_field_iterator(&it);
  return it;
}

void obj_next_field_iterator (obj_field_iterator *it) { it->cur_field += MEMBER_SIZE; }

void obj_next_ptr_field_iterator (obj_field_iterator *it) {
  do {
    obj_next_field_iterator(it);
  } while (!field_is_done_iterator(it) && !is_valid_pointer(*(size_t **)it->cur_field));
}

bool field_is_done_iterator (obj_field_iterator *it) {
  return it->cur_field >= get_end_of_obj(it->obj_ptr);
}

void *get_obj_header_ptr (void *ptr) {
  lama_type type = get_type_row_ptr(ptr);
  return ptr - get_header_size(type);
}

void *get_object_content_ptr (void *header_ptr) {
  lama_type type = get_type_header_ptr(header_ptr);
  return header_ptr + get_header_size(type);
}

void *get_end_of_obj (void *header_ptr) { return header_ptr + obj_size_header_ptr(header_ptr); }

size_t get_header_size (lama_type type) {
  switch (type) {
    case STRING:
    case CLOSURE:
    case ARRAY:
    case SEXP: return DATA_HEADER_SZ;
    default: perror("ERROR: get_header_size: unknown object type\n");
#ifdef DEBUG_VERSION
      raise(SIGINT);   // only for debug purposes
#endif
      exit(1);
  }
}

void *alloc_string (int len) {
  data *obj        = alloc(string_size(len));
  obj->data_header = STRING_TAG | (len << 3);
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "%p, [STRING] tag=%zu\n", obj, TAG(obj->data_header));
#endif
#ifdef DEBUG_VERSION
  obj->id = cur_id;
#endif
  obj->forward_address = 0;
  return obj;
}

void *alloc_array (int len) {
  data *obj        = alloc(array_size(len));
  obj->data_header = ARRAY_TAG | (len << 3);
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "%p, [ARRAY] tag=%zu\n", obj, TAG(obj->data_header));
#endif
#ifdef DEBUG_VERSION
  obj->id = cur_id;
#endif
  obj->forward_address = 0;
  return obj;
}

void *alloc_sexp (int members) {
  sexp *obj        = alloc(sexp_size(members));
  obj->data_header = SEXP_TAG | (members << 3);
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "%p, SEXP tag=%zu\n", obj, TAG(obj->data_header));
#endif
#ifdef DEBUG_VERSION
  obj->id = cur_id;
#endif
  obj->forward_address = 0;
  obj->tag             = 0;
  return obj;
}

void *alloc_closure (int captured) {

  data *obj        = alloc(closure_size(captured));
  obj->data_header = CLOSURE_TAG | (captured << 3);
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "%p, [CLOSURE] tag=%zu\n", obj, TAG(obj->data_header));
#endif
#ifdef DEBUG_VERSION
  obj->id = cur_id;
#endif
  obj->forward_address = 0;
  return obj;
}
