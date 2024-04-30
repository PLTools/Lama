        .data

        .global _Lprintf
        .extern _Bprintf

        .global _Lfprintf
        .extern _Bfprintf

        .global _Lsprintf
        .extern _Bsprintf

        .global _Lfailure
        .extern _failure

        .extern cnt_percentage_sign

        .text

_Lprintf:
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
_Lprintf_loop:
        movq    $0, %r12
        cmpq    %r11, %r12
        jz    _Lprintf_continue

        decq    %r11
        movq    (%rax), %r10
        testq   $1, %r10
        jz    _Lprintf_loop_end
# unbox value
        sarq    %r10
        movq    %r10, (%rax)
_Lprintf_loop_end:
        addq    $8, %rax
        jmp     _Lprintf_loop
_Lprintf_continue:
        popq    %rsi
        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     Bprintf

_Lfprintf:
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
_Lfprintf_loop:
        movq    $0, %r12
        cmpq    %r11, %r12
        jz    _Lfprintf_continue

        decq    %r11
        movq    (%rax), %r10
        testq   $1, %r10
        jz    _Lfprintf_loop_end
# unbox value
        sarq    %r10
        movq    %r10, (%rax)
_Lfprintf_loop_end:
        addq    $8, %rax
        jmp     _Lfprintf_loop
_Lfprintf_continue:
        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     Bfprintf

_Lsprintf:
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
_Lsprintf_loop:
        movq    $0, %r12
        cmpq    %r11, %r12
        jz    _Lsprintf_continue

        decq    %r11
        movq    (%rax), %r10
        testq   $1, %r10
        jz    _Lsprintf_loop_end
# unbox value
        sarq    %r10
        movq    %r10, (%rax)
_Lsprintf_loop_end:
        addq    $8, %rax
        jmp     _Lsprintf_loop
_Lsprintf_continue:
        popq    %rsi
        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     Bsprintf

_Lfailure:
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
_Lfailure_loop:
        movq    $0, %r12
        cmpq    %r11, %r12
        jz    _Lfailure_continue

        decq    %r11
        movq    (%rax), %r10
        testq   $1, %r10
        jz    _Lfailure_loop_end
# unbox value
        sarq    %r10
        movq    %r10, (%rax)
_Lfailure_loop_end:
        addq    $8, %rax
        jmp     _Lfailure_loop
_Lfailure_continue:
        popq    %rsi
        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     failure
