#ifdef __linux__
#define PREFIXED(name) name
#elif defined(__APPLE__)
#define PREFIXED(name) _##name
#endif

        .global PREFIXED(Lprintf)
        .extern PREFIXED(Bprintf)

        .global PREFIXED(Lfprintf)
        .extern PREFIXED(Bfprintf)

        .global PREFIXED(Lsprintf)
        .extern PREFIXED(Bsprintf)

        .global PREFIXED(Lfailure)
        .extern PREFIXED(Bfailure)

        .text

# Unboxes in place the \count words starting at address \words: every word with the lowest
# bit set (a boxed integer) is shifted right arithmetically. Clobbers \words, \count and r10.
# The macro has named parameters: otherwise the Darwin assembler treats $1 and $8 in its body as
# positional macro arguments.
.macro UNBOX_ARGS words, count
1:
        testq   \count, \count
        jz      3f

        decq    \count
        movq    (\words), %r10
        testq   $1, %r10
        jz      2f
# unbox value
        sarq    %r10
        movq    %r10, (\words)
2:
        addq    $8, \words
        jmp     1b
3:
.endm

PREFIXED(Lprintf):
# save return address
        popq    %r14

        pushq   %r9
        pushq   %r8
        pushq   %rcx
        pushq   %rdx
        pushq   %rsi
        movq    %rsp, %rax
# rdi --- format string
# r11 --- number of arguments except format string
        UNBOX_ARGS %rax, %r11

        popq    %rsi
        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     PREFIXED(Bprintf)

PREFIXED(Lfprintf):
# save return address
        popq    %r14

        pushq   %r9
        pushq   %r8
        pushq   %rcx
        pushq   %rdx
        movq    %rsp, %rax
# rdi --- FILE*
# rsi --- format string
# r11 --- number of arguments except format string
        UNBOX_ARGS %rax, %r11

        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     PREFIXED(Bfprintf)

PREFIXED(Lsprintf):
# save return address
        popq    %r14

        pushq   %r9
        pushq   %r8
        pushq   %rcx
        pushq   %rdx
        pushq   %rsi
        movq    %rsp, %rax
# rdi --- format string
# r11 --- number of arguments except format string
        UNBOX_ARGS %rax, %r11

        popq    %rsi
        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     PREFIXED(Bsprintf)

PREFIXED(Lfailure):
# save return address
        popq    %r14

        pushq   %r9
        pushq   %r8
        pushq   %rcx
        pushq   %rdx
        pushq   %rsi
        movq    %rsp, %rax
# rdi --- format string
# r11 --- number of arguments except format string
        UNBOX_ARGS %rax, %r11

        popq    %rsi
        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     PREFIXED(Bfailure)
