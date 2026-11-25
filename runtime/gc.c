#define _GNU_SOURCE 1

#include "gc.h"

#include "runtime.h"

#include <assert.h>
#include <execinfo.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <time.h>
#include <unistd.h>

static const size_t INIT_HEAP_SIZE = MINIMUM_HEAP_CAPACITY;

#ifdef DEBUG_VERSION
size_t cur_id = 0;
#endif

static extra_roots_pool extra_roots;

static inline bool is_valid_pointer (const uintptr_t *p);
static void        gc_test_and_mark_root (uintptr_t **root);

// zero-initialised on purpose: it lives in .bss and does not shift the compiler's custom_data section
static bool gc_disabled;

uintptr_t __gc_stack_top = 0, __gc_stack_bottom = 0;
#ifdef LAMA_ENV
#ifdef __linux__
// declared as bytes: the section is not necessarily word-aligned (the compiler emits it without
// alignment, so it may follow the program's string constants)
extern char __start_custom_data[], __stop_custom_data[];
#elif defined(__APPLE__)
extern char __start_custom_data[] __asm("section$start$__DATA$custom_data");
extern char __stop_custom_data[] __asm("section$end$__DATA$custom_data");
#endif
#endif

#ifdef DEBUG_VERSION
memory_chunk heap;
#else
static memory_chunk heap;
#endif

#ifdef DEBUG_VERSION
void dump_heap ();
#endif

// Prints a best-effort backtrace, then lets the default action terminate the process with SIGSEGV.
// backtrace is not async-signal-safe on its first call (it may load the unwinder), so __init calls
// it once in advance.
static void segv_handler (int sig) {
  static const char msg[] = "Segmentation fault in a Lama program, backtrace:\n";
  void             *frames[32];

  if (write(STDERR_FILENO, msg, sizeof(msg) - 1) > 0) {
    backtrace_symbols_fd(frames, backtrace(frames, 32), STDERR_FILENO);
  }
  signal(sig, SIG_DFL);
  raise(sig);
}

// commits the heap so that it spans at least `words` words; the heap never moves
static void heap_commit (size_t words) {
  if (words <= heap.size) { return; }
  if (words > heap.reserved) {
    fprintf(stderr,
            "ERROR: out of memory: the heap cannot grow beyond %zu bytes\n",
            WORDS_TO_BYTES(heap.reserved));
    exit(1);
  }
  size_t page_words = (size_t)sysconf(_SC_PAGESIZE) / sizeof(uintptr_t);
  words             = MIN((words + page_words - 1) / page_words * page_words, heap.reserved);
  if (mprotect(heap.begin, WORDS_TO_BYTES(words), PROT_READ | PROT_WRITE) != 0) {
    perror("ERROR: heap_commit: mprotect failed");
    exit(1);
  }
  heap.size = words;
  heap.end  = heap.begin + words;
}

// used while GC is disabled: the heap grows instead of being collected
static void *alloc_without_gc (size_t size) {
  size_t used = heap.current - heap.begin;
  heap_commit(MAX(used + size, MIN(heap.size * EXTRA_ROOM_HEAP_COEFFICIENT, heap.reserved)));
  return gc_alloc_on_existing_heap(size);
}

extern intptr_t LenableGC (void) {
  gc_disabled = false;
  return BOX(0);
}

extern intptr_t LdisableGC (void) {
  gc_disabled = true;
  return BOX(0);
}

void *alloc (size_t obj_size) {
#ifdef DEBUG_VERSION
  ++cur_id;
#endif
  size_t size = BYTES_TO_WORDS(obj_size);
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "allocation of size %zu words (%zu bytes): ", size, obj_size);
#endif
  void *p = gc_alloc_on_existing_heap(size);
  if (!p) {
    // not enough place in the heap, need to perform GC cycle
    p = gc_disabled ? alloc_without_gc(size) : gc_alloc(size);
  }
#ifdef DEBUG_PRINT
  printf("Object allocated: content [%p, %p) padding [%p, %p)\n",
         p,
         (char *)p + obj_size,
         (char *)p + obj_size,
         (char *)p + WORDS_TO_BYTES(size));
  fflush(stdout);
#endif
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

static void print_unboxed (FILE *f, intptr_t unboxed) { fprintf(f, "unboxed %" PRIdPTR " | ", unboxed); }

static FILE *open_dump (char *filename) {
  FILE *f = fopen(filename, "w+");
  if (f == NULL) {
    perror("ERROR: cannot open a GC dump file");
    exit(1);
  }
  return f;
}

static FILE *print_stack_content (char *filename) {
  FILE *f = open_dump(filename);
  fprintf(f, "Stack content:\n");
  for (uintptr_t *stack_ptr = (uintptr_t *)(__gc_stack_top + sizeof(uintptr_t));
       stack_ptr < (uintptr_t *)__gc_stack_bottom;
       ++stack_ptr) {
    uintptr_t value = *stack_ptr;
    if (is_valid_heap_pointer((uintptr_t *)value)) {
      print_object_info(f, (void *)value);
    } else {
      print_unboxed(f, (intptr_t)value);
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
  fprintf(f, "object: ");
  print_object_info(f, obj_content);
  // first cycle: print object's fields
  for (obj_field_iterator field_it = ptr_field_begin_iterator(obj_header);
       !field_is_done_iterator(&field_it);
       obj_next_field_iterator(&field_it)) {
    uintptr_t field_value = *(uintptr_t *)field_it.cur_field;
    if (is_valid_heap_pointer((uintptr_t *)field_value)) {
      print_object_info(f, (void *)field_value);
    } else {
      print_unboxed(f, (intptr_t)field_value);
    }
  }
  fprintf(f, "\n");
  for (obj_field_iterator field_it = ptr_field_begin_iterator(obj_header);
       !field_is_done_iterator(&field_it);
       obj_next_field_iterator(&field_it)) {
    uintptr_t field_value = *(uintptr_t *)field_it.cur_field;
    if (is_valid_heap_pointer((uintptr_t *)field_value)) { objects_dfs(f, (void *)field_value); }
  }
}

FILE *print_objects_traversal (char *filename, bool marked) {
  FILE *f = open_dump(filename);
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
    fprintf(f, "extra root %p: ", (void *)extra_roots.roots[i]);
    void *value = *extra_roots.roots[i];
    if (is_valid_heap_pointer(value)) {
      print_object_info(f, value);
    } else {
      print_unboxed(f, (intptr_t)value);
    }
    fprintf(f, "\n");
  }
  fflush(f);
  return f;
}

int files_cmp (FILE *f1, FILE *f2) {
  int symbol1, symbol2;
  int position = 0;
  rewind(f1);
  rewind(f2);
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
  if (size <= (size_t)(heap.end - heap.current)) {
    void *p = (void *)heap.current;
    heap.current += size;
    return p;
  }
  return NULL;
}

void *gc_alloc (size_t size) {
#ifdef DEBUG_PRINT
  printf("Reallocation!\n");
#endif
  fflush(stdout);
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
  for (uintptr_t *p = (uintptr_t *)(__gc_stack_top + sizeof(uintptr_t)); p < (uintptr_t *)__gc_stack_bottom; ++p) {
    gc_test_and_mark_root((uintptr_t **)p);
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
  update_references();
  physically_relocate();
  heap.current = heap.begin + live_size;

  // all in words; the heap only grows, and never beyond its reservation
  size_t next_heap_size =
      MAX(live_size * EXTRA_ROOM_HEAP_COEFFICIENT + additional_size, MINIMUM_HEAP_CAPACITY);
  heap_commit(MAX(live_size + additional_size, MIN(next_heap_size, heap.reserved)));
}

size_t compute_locations () {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC compute_locations started\n");
#endif
  uintptr_t    *free_ptr  = heap.begin;
  heap_iterator scan_iter = heap_begin_iterator();

  for (; !heap_is_done_iterator(&scan_iter); heap_next_obj_iterator(&scan_iter)) {
    void *header_ptr  = scan_iter.current;
    void *obj_content = get_object_content_ptr(header_ptr);
    if (is_marked(obj_content)) {
      size_t sz = BYTES_TO_WORDS(obj_size_header_ptr(header_ptr));
      // forward address is responsible for object header pointer
      set_forward_address(obj_content, (uintptr_t)free_ptr);
      free_ptr += sz;
    }
  }

#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC compute_locations finished\n");
#endif
  // it will return number of words
  return free_ptr - heap.begin;
}

// obj_content points to the content of a live object that has not been moved yet;
// returns the address its content will have after compaction
static void *forwarded_content (void *obj_content) {
  char *new_header = (char *)get_forward_address(obj_content);
  return new_header + get_header_size(get_type_row_ptr(obj_content));
}

void scan_and_fix_region (void *start, void *end) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC scan_and_fix_region started\n");
#endif
  for (uintptr_t *ptr = (uintptr_t *)start; ptr < (uintptr_t *)end; ++ptr) {
    void *value = (void *)*ptr;
    if (is_valid_heap_pointer(value)) { *(void **)ptr = forwarded_content(value); }
  }
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC scan_and_fix_region finished\n");
#endif
}

bool gc_stack_contains (void *begin, void *end) {
  return __gc_stack_top != 0 && (uintptr_t)begin >= __gc_stack_top + sizeof(uintptr_t)
         && (uintptr_t)end <= __gc_stack_bottom;
}

// whether update_references fixes this root slot anyway: it lies on Lama's stack or in the global area
static bool root_slot_is_scanned (void **slot) {
  if (gc_stack_contains(slot, slot + 1)) { return true; }
#ifdef LAMA_ENV
  if (slot >= (void **)&__start_custom_data && slot < (void **)&__stop_custom_data) { return true; }
#endif
  return false;
}

static bool root_needs_fixing (void **slot) {
  return !root_slot_is_scanned(slot) && is_valid_heap_pointer(*slot);
}

typedef struct {
  void **slot;
  void  *value;
} fixed_root;

// Every slot is read before any slot is written: a slot registered more than once must get one
// new value, and a pointer that is already fixed still looks like a heap pointer (the heap does
// not move). Linear in the number of extra roots.
static void scan_and_fix_region_roots (void) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "extra roots started: number of extra roots %i\n", extra_roots.current_free);
#endif
  size_t n = 0;
  for (int i = 0; i < extra_roots.current_free; i++) {
    if (root_needs_fixing(extra_roots.roots[i])) { n++; }
  }

  fixed_root *fixed = NULL;
  if (n > 0) {
    fixed = malloc(n * sizeof(fixed_root));
    if (fixed == NULL) {
      fprintf(stderr, "ERROR: scan_and_fix_region_roots: out of memory\n");
      exit(1);
    }
  }

  size_t k = 0;
  for (int i = 0; i < extra_roots.current_free; i++) {
    void **slot  = extra_roots.roots[i];
    void  *value = *slot;
    if (root_needs_fixing(slot)) {
      fixed[k].slot  = slot;
      fixed[k].value = forwarded_content(value);
      k++;
    }
#ifdef DEBUG_VERSION
    else if (is_valid_pointer(value) && root_slot_is_scanned(slot)) {
#  ifdef DEBUG_PRINT
      fprintf(stderr,
              "|\tskip extra root: %p (%p), since it is fixed with Lama's stack or global area\n",
              (void *)slot,
              value);
#  endif
#  ifdef LAMA_ENV
      // a root in the global area must hold a heap pointer
      if (!is_valid_heap_pointer(value) && slot >= (void **)&__start_custom_data
          && slot < (void **)&__stop_custom_data) {
        fprintf(stderr,
                "|\tskip extra root: %p (%p), since it points to Lama's static area stop=%p start=%p\n",
                (void *)slot,
                value,
                (void *)&__stop_custom_data,
                (void *)&__start_custom_data);
        exit(1);
      }
#  endif
    }
#endif
  }

  for (size_t j = 0; j < k; j++) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
    fprintf(stderr, "|\textra root (%p) %p -> %p\n", (void *)fixed[j].slot, *fixed[j].slot, fixed[j].value);
#endif
    *fixed[j].slot = fixed[j].value;
  }
  free(fixed);
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "|\textra roots finished\n");
#endif
}

void update_references (void) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC update_references started\n");
#endif
  heap_iterator it = heap_begin_iterator();
  while (!heap_is_done_iterator(&it)) {
    if (is_marked(get_object_content_ptr(it.current))) {
      for (obj_field_iterator field_iter = ptr_field_begin_iterator(it.current);
           !field_is_done_iterator(&field_iter);
           obj_next_ptr_field_iterator(&field_iter)) {

        void *field_value = *(void **)field_iter.cur_field;
        if (!is_valid_heap_pointer(field_value)) { continue; }
        void *new_content = forwarded_content(field_value);
#ifdef DEBUG_VERSION
        if (!is_valid_heap_pointer(new_content)) {
#  ifdef DEBUG_PRINT
          fprintf(stderr,
                  "ur: incorrect pointer assignment: on object with id %" PRIuPTR "\n",
                  TO_DATA(get_object_content_ptr(it.current))->id);
#  endif
          exit(1);
        }
#endif
        *(void **)field_iter.cur_field = new_content;
      }
    }
    heap_next_obj_iterator(&it);
  }
  // fix pointers from stack
  scan_and_fix_region((void *)(__gc_stack_top + sizeof(uintptr_t)), (void *)__gc_stack_bottom);

  // fix pointers from extra_roots
  scan_and_fix_region_roots();

#ifdef LAMA_ENV
  assert((void *)&__stop_custom_data >= (void *)&__start_custom_data);
  scan_and_fix_region((void *)&__start_custom_data, (void *)&__stop_custom_data);
#endif
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC update_references finished\n");
#endif
}

void physically_relocate (void) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC physically_relocate started\n");
#endif
  heap_iterator from_iter = heap_begin_iterator();

  while (!heap_is_done_iterator(&from_iter)) {
    void         *obj       = get_object_content_ptr(from_iter.current);
    heap_iterator next_iter = from_iter;
    heap_next_obj_iterator(&next_iter);
    if (is_marked(obj)) {
      // slide the object down to its forward address, 'to' points to the future object header
      void *to = (void *)get_forward_address(obj);
      memmove(to, from_iter.current, obj_size_header_ptr(from_iter.current));
      unmark_object(get_object_content_ptr(to));
    }
    from_iter = next_iter;
  }
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "GC physically_relocate finished\n");
#endif
}

// The upper bound is inclusive: the content of an object without fields (such as []) starts where
// the object ends, which is heap.current for the last object.
bool is_valid_heap_pointer (const uintptr_t *p) {
  return !UNBOXED(p) && (uintptr_t)heap.begin <= (uintptr_t)p && (uintptr_t)p <= (uintptr_t)heap.current;
}

static inline bool is_valid_pointer (const uintptr_t *p) { return !UNBOXED(p); }

static inline void queue_enqueue (heap_iterator *tail_iter, void *obj) {
  void *tail         = tail_iter->current;
  void *tail_content = get_object_content_ptr(tail);
  set_forward_address(tail_content, (uintptr_t)obj);
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
  for (uintptr_t *ptr = (uintptr_t *)&__start_custom_data; ptr < (uintptr_t *)&__stop_custom_data; ++ptr) {
    mark(*(void **)ptr);
  }
}
#endif

static void gc_test_and_mark_root (uintptr_t **root) {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr,
          "\troot = %p (%p), stack addresses: [%p, %p)\n",
          root,
          *root,
          (void *)(__gc_stack_top + sizeof(uintptr_t)),
          (void *)__gc_stack_bottom);
#endif
  mark((void *)*root);
}

void __gc_init (void) {
  __gc_stack_bottom = (uintptr_t)__builtin_frame_address(1) + sizeof(uintptr_t);
  __init();
}

void __init (void) {
  void *frames[1];
  backtrace(frames, 1);
  signal(SIGSEGV, segv_handler);

  srandom(time(NULL));

  // reserve address space only; heap_commit makes its prefix accessible
  size_t page         = (size_t)sysconf(_SC_PAGESIZE);
  size_t min_reserved = (WORDS_TO_BYTES(INIT_HEAP_SIZE) + page - 1) / page * page;
  void  *reservation  = MAP_FAILED;
  size_t reserved     = HEAP_RESERVE_MAX_BYTES;
  // under an address-space limit (ulimit -v), leave at least half of it to the rest of the program
  struct rlimit as_limit;
  if (getrlimit(RLIMIT_AS, &as_limit) == 0 && as_limit.rlim_cur != RLIM_INFINITY
      && as_limit.rlim_cur / 2 < reserved) {
    reserved = (size_t)(as_limit.rlim_cur / 2) / page * page;
  }
  reserved = MAX(reserved, min_reserved);
  for (;; reserved = MAX(reserved / 2 / page * page, min_reserved)) {
    reservation = mmap(NULL, reserved, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (reservation != MAP_FAILED || reserved == min_reserved) { break; }
  }
  if (reservation == MAP_FAILED) {
    perror("ERROR: __init: mmap failed");
    exit(1);
  }
  heap.begin    = reservation;
  heap.reserved = reserved / sizeof(uintptr_t);
  heap.size     = 0;
  heap.current  = heap.begin;
  heap_commit(INIT_HEAP_SIZE);
  clear_extra_roots();
  gc_disabled = false;
}

void __shutdown (void) {
  if (munmap(heap.begin, WORDS_TO_BYTES(heap.reserved)) != 0) {
    perror("ERROR: __shutdown: munmap failed");
    exit(1);
  }
#ifdef DEBUG_VERSION
  cur_id = 0;
#endif
  heap.begin        = NULL;
  heap.end          = NULL;
  heap.size         = 0;
  heap.reserved     = 0;
  heap.current      = NULL;
  __gc_stack_top    = 0;
  __gc_stack_bottom = 0;
}

void clear_extra_roots (void) { extra_roots.current_free = 0; }

void push_extra_root (void **p) {
  if (extra_roots.current_free >= MAX_EXTRA_ROOTS_NUMBER) {
    fprintf(stderr, "ERROR: push_extra_roots: extra_roots_pool overflow; max number is %d\n", MAX_EXTRA_ROOTS_NUMBER);
    printf("ERROR: push_extra_roots: extra_roots_pool overflow; max number is %d\n", MAX_EXTRA_ROOTS_NUMBER);
    fflush(stdout);
    exit(1);
  }
  assert(p >= (void **)__gc_stack_top || p < (void **)__gc_stack_bottom);
  extra_roots.roots[extra_roots.current_free] = p;
  extra_roots.current_free++;
}

void pop_extra_root (void **p) {
  if (extra_roots.current_free == 0) {
    fprintf(stderr, "ERROR: pop_extra_root: extra_roots are empty\n");
    exit(1);
  }
  extra_roots.current_free--;
  if (extra_roots.roots[extra_roots.current_free] != p) {
    fprintf(stderr, "ERROR: pop_extra_root: stack invariant violation\n");
    exit(1);
  }
}

/* Functions for tests */

#if defined(DEBUG_VERSION)
size_t objects_snapshot (uintptr_t *object_ids_buf, size_t object_ids_buf_size) {
  size_t i = 0;
  for (heap_iterator it = heap_begin_iterator();
       !heap_is_done_iterator(&it) && i < object_ids_buf_size;
       heap_next_obj_iterator(&it), ++i) {
    void *header_ptr = it.current;
    data *d          = TO_DATA(get_object_content_ptr(header_ptr));
    object_ids_buf[i] = d->id;
  }
  return i;
}
#endif

#ifdef DEBUG_VERSION
void dump_heap () {
  for (heap_iterator it = heap_begin_iterator(); !heap_is_done_iterator(&it);
       heap_next_obj_iterator(&it)) {
    void     *header_ptr  = it.current;
    void     *content_ptr = get_object_content_ptr(header_ptr);
    data     *d           = TO_DATA(content_ptr);
    lama_type t           = get_type_header_ptr(header_ptr);
    fprintf(stderr, "%p id %" PRIuPTR " ", header_ptr, d->id);
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

void set_stack (uintptr_t stack_top, uintptr_t stack_bottom) {
  __gc_stack_top    = stack_top;
  __gc_stack_bottom = stack_bottom;
}

void set_extra_roots (size_t extra_roots_size, void ***extra_roots_ptr) {
  size_t n = MIN(extra_roots_size, (size_t)MAX_EXTRA_ROOTS_NUMBER);
  memcpy(extra_roots.roots, extra_roots_ptr, n * sizeof(extra_roots.roots[0]));
  extra_roots.current_free = (int)n;
}

#endif

/* Utility functions */

uintptr_t get_forward_address (void *obj) {
  data *d = TO_DATA(obj);
  return GET_FORWARD_ADDRESS(d->forward_address);
}

void set_forward_address (void *obj, uintptr_t addr) {
  data *d = TO_DATA(obj);
  SET_FORWARD_ADDRESS(d->forward_address, addr);
}

bool is_marked (void *obj) {
  data *d        = TO_DATA(obj);
  intptr_t mark_bit = GET_MARK_BIT(d->forward_address);
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
  uintptr_t *header = (uintptr_t *)ptr;
  switch (TAG(*header)) {
    case ARRAY_TAG: return ARRAY;
    case STRING_TAG: return STRING;
    case CLOSURE_TAG: return CLOSURE;
    case SEXP_TAG: return SEXP;
    default: {
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
      fprintf(stderr, "ERROR: get_type_header_ptr: unknown object header, cur_id=%zu\n", cur_id);
      raise(SIGINT);   // only for debug purposes
#else
#  ifdef FULL_INVARIANT_CHECKS
      // the dump walks the heap and gets here again on the same broken header
      static bool dumping = false;
      if (!dumping) {
        dumping                      = true;
        FILE *heap_before_compaction = print_objects_traversal("dump_kill", 1);
        fclose(heap_before_compaction);
      }
#  endif
      kill(getpid(), SIGSEGV);
#endif
      exit(1);
    }
  }
}

size_t obj_size_header_ptr (void *ptr) {
  uintptr_t len = LEN(*(uintptr_t *)ptr);
  switch (get_type_header_ptr(ptr)) {
    case ARRAY: return array_size(len);
    case STRING: return string_size(len);
    case CLOSURE: return closure_size(len);
    case SEXP: return sexp_size(len);
    default: abort();   // unreachable
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
  obj_field_iterator it = {.obj_ptr = obj, .cur_field = get_object_content_ptr(obj)};
  switch (type) {
    case STRING: {
      it.cur_field = get_end_of_obj(it.obj_ptr);
      break;
    }
    case CLOSURE:
    case SEXP: {
      it.cur_field = (char *)it.cur_field + MEMBER_SIZE;
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
  if (is_valid_pointer(*(uintptr_t **)it.cur_field)) { return it; }
  obj_next_ptr_field_iterator(&it);
  return it;
}

void obj_next_field_iterator (obj_field_iterator *it) {
  it->cur_field = (char *)it->cur_field + MEMBER_SIZE;
}

void obj_next_ptr_field_iterator (obj_field_iterator *it) {
  do {
    obj_next_field_iterator(it);
  } while (!field_is_done_iterator(it) && !is_valid_pointer(*(uintptr_t **)it->cur_field));
}

bool field_is_done_iterator (obj_field_iterator *it) {
  return it->cur_field >= get_end_of_obj(it->obj_ptr);
}

void *get_obj_header_ptr (void *ptr) {
  lama_type type = get_type_row_ptr(ptr);
  return (char *)ptr - get_header_size(type);
}

void *get_object_content_ptr (void *header_ptr) {
  lama_type type = get_type_header_ptr(header_ptr);
  return (char *)header_ptr + get_header_size(type);
}

void *get_end_of_obj (void *header_ptr) {
  return (char *)header_ptr + obj_size_header_ptr(header_ptr);
}

size_t get_header_size (lama_type type) {
  switch (type) {
    case STRING:
    case CLOSURE:
    case ARRAY:
    case SEXP: return DATA_HEADER_SZ;
    default: abort();   // unreachable
  }
}

// rejects lengths that do not fit into the header or make the object size overflow
static void check_obj_len (uintptr_t len, size_t member_size, size_t extra_members, char *kind) {
  if (len > (UINTPTR_MAX >> 3) || len > (SIZE_MAX - DATA_HEADER_SZ) / member_size - extra_members) {
    failure("%s of length %" PRIuPTR " is too large\n", kind, len);
  }
}

void *alloc_string (uintptr_t len) {
  check_obj_len(len, 1, 1, "string");
  data *obj          = alloc(string_size(len));
  obj->data_header   = STRING_TAG | (len << 3);
  obj->contents[len] = 0;
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "%p, [STRING] tag=%" PRIuPTR "\n", (void *)obj, TAG(obj->data_header));
#endif
#ifdef DEBUG_VERSION
  obj->id = cur_id;
#endif
  obj->forward_address = 0;
#ifdef DEBUG_PRINT
  printf("Allocated string\n");
#endif
  return obj;
}

void *alloc_array (uintptr_t len) {
  check_obj_len(len, MEMBER_SIZE, 0, "array");
  data *obj        = alloc(array_size(len));
  obj->data_header = ARRAY_TAG | (len << 3);
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "%p, [ARRAY] tag=%" PRIuPTR "\n", (void *)obj, TAG(obj->data_header));
#endif
#ifdef DEBUG_VERSION
  obj->id = cur_id;
#endif
  obj->forward_address = 0;
#ifdef DEBUG_PRINT
  printf("Allocated array\n");
#endif
  return obj;
}

void *alloc_sexp (uintptr_t members) {
  check_obj_len(members, MEMBER_SIZE, 1, "S-expression");
  sexp *obj        = alloc(sexp_size(members));
  obj->data_header = SEXP_TAG | (members << 3);
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "%p, SEXP tag=%" PRIuPTR "\n", (void *)obj, TAG(obj->data_header));
#endif
#ifdef DEBUG_VERSION
  obj->id = cur_id;
#endif
  obj->forward_address = 0;
  obj->tag             = 0;
#ifdef DEBUG_PRINT
  printf("Allocated sexp\n");
#endif
  return obj;
}

void *alloc_closure (uintptr_t captured) {
  check_obj_len(captured, MEMBER_SIZE, 0, "closure");
  data *obj        = alloc(closure_size(captured));
  obj->data_header = CLOSURE_TAG | (captured << 3);
#if defined(DEBUG_VERSION) && defined(DEBUG_PRINT)
  fprintf(stderr, "%p, [CLOSURE] tag=%" PRIuPTR "\n", (void *)obj, TAG(obj->data_header));
#endif
#ifdef DEBUG_VERSION
  obj->id = cur_id;
#endif
  obj->forward_address = 0;
#ifdef DEBUG_PRINT
  printf("Allocated closure\n");
#endif
  return obj;
}
