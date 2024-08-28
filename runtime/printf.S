#ifdef __linux__
#define PREFIXED(name) name
#elif defined(__APPLE__)
#define PREFIXED(name) _##name
#endif
        .data

        .global PREFIXED(Lprintf)
        .extern PREFIXED(Bprintf)

        .global PREFIXED(Lfprintf)
        .extern PREFIXED(Bfprintf)

        .global PREFIXED(Lsprintf)
        .extern PREFIXED(Bsprintf)

        .global PREFIXED(Lfailure)
        .extern PREFIXED(failure)

        .extern cnt_percentage_sign

        .text

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
PREFIXED(Lprintf_loop):
        movq    $0, %r12
        cmpq    %r11, %r12
        jz    PREFIXED(Lprintf_continue)

        decq    %r11
        movq    (%rax), %r10
        testq   $1, %r10
        jz    PREFIXED(Lprintf_loop_end)
# unbox value
        sarq    %r10
        movq    %r10, (%rax)
PREFIXED(Lprintf_loop_end):
        addq    $8, %rax
        jmp     PREFIXED(Lprintf_loop)
PREFIXED(Lprintf_continue):
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
PREFIXED(Lfprintf_loop):
        movq    $0, %r12
        cmpq    %r11, %r12
        jz    PREFIXED(Lfprintf_continue)

        decq    %r11
        movq    (%rax), %r10
        testq   $1, %r10
        jz    PREFIXED(Lfprintf_loop_end)
# unbox value
        sarq    %r10
        movq    %r10, (%rax)
PREFIXED(Lfprintf_loop_end):
        addq    $8, %rax
        jmp     PREFIXED(Lfprintf_loop)
PREFIXED(Lfprintf_continue):
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
PREFIXED(Lsprintf_loop):
        movq    $0, %r12
        cmpq    %r11, %r12
        jz    PREFIXED(Lsprintf_continue)

        decq    %r11
        movq    (%rax), %r10
        testq   $1, %r10
        jz    PREFIXED(Lsprintf_loop_end)
# unbox value
        sarq    %r10
        movq    %r10, (%rax)
PREFIXED(Lsprintf_loop_end):
        addq    $8, %rax
        jmp     PREFIXED(Lsprintf_loop)
PREFIXED(Lsprintf_continue):
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
PREFIXED(Lfailure_loop):
        movq    $0, %r12
        cmpq    %r11, %r12
        jz    PREFIXED(Lfailure_continue)

        decq    %r11
        movq    (%rax), %r10
        testq   $1, %r10
        jz    PREFIXED(Lfailure_loop_end)
# unbox value
        sarq    %r10
        movq    %r10, (%rax)
PREFIXED(Lfailure_loop_end):
        addq    $8, %rax
        jmp     PREFIXED(Lfailure_loop)
PREFIXED(Lfailure_continue):
        popq    %rsi
        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     PREFIXED(failure)
