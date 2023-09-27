### TODO list

- [x] Fix heap&stack&extra_roots dump
- [x] Remove extra and dead code
- [x] Debug print -> DEBUG_PRINT mode
- [x] Check `mmap`/`remap`/...
- [x] Check: `__gc_stack_bot`: same issue as `__gc_stack_top`?
- [x] Check: Can we get rid of `__gc_init` (as an assembly (implement in C instead))? (answer: if we make main in which every Lama file is compiled set `__gc_stack_bottom` to current `ebp` then yes, otherwise we need access to registers)
- [x] Check: runtime tags: should always the last bit be 1? (Answer: not really, however, we still need to distinguish between 5 different options (because unboxed values should have its own value to be returned from `LkindOf`))
- [x] Fix warnings in ML code
- [x] TODO: debug flag doesn't compile
- [x] Sexp: move the tag to be `contents[0]` instead of the word in sexp header; i.e. get rid of sexp as separate data structure
- [x] Run Lama compiler on Lama
- [ ] Add more stress tests (for graph-like structures) to `stdlib/regression` and unit tests
- [ ] Magic constants
- [ ] Normal documentation: a-la doxygen
- [ ] Think: normal debug mode
- [ ] Fix warnings in C code
- [ ] Modes (like FULL_INVARIANTS) -> separate files