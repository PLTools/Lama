.section .text

.global Lprintf
.extern printf

.global Lfprintf
.extern fprintf

.global Lsprintf
.extern Bsprintf

.global Lfailure
.extern failure

.extern cnt_percentage_sign

Lprintf:
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
loop:
        movq    $0, %r12
        cmpq    %r11, %r12
        jz    continue

        decq    %r11
        movq    (%rax), %r10
        testq   $1, %r10
        jz    jmpCont
# unbox value
        sarq    %r10
        movq    %r10, (%rax)
jmpCont:
        addq    $8, %rax
        jmp     loop
continue:
        popq    %rsi
        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     printf

Lfprintf:
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
Lfprintf_loop:
        movq    $0, %r12
        cmpq    %r11, %r12
        jz    Lfprintf_continue

        decq    %r11
        movq    (%rax), %r10
        testq   $1, %r10
        jz    Lfprintf_loop_end
# unbox value
        sarq    %r10
        movq    %r10, (%rax)
Lfprintf_loop_end:
        addq    $8, %rax
        jmp     Lfprintf_loop
Lfprintf_continue:
        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     fprintf

Lsprintf:
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
Lsprintf_loop:
        movq    $0, %r12
        cmpq    %r11, %r12
        jz    Lsprintf_continue

        decq    %r11
        movq    (%rax), %r10
        testq   $1, %r10
        jz    Lsprintf_loop_end
# unbox value
        sarq    %r10
        movq    %r10, (%rax)
Lsprintf_loop_end:
        addq    $8, %rax
        jmp     Lsprintf_loop
Lsprintf_continue:
        popq    %rsi
        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     Bsprintf

Lfailure:
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
Lfailure_loop:
        movq    $0, %r12
        cmpq    %r11, %r12
        jz    Lfailure_continue

        decq    %r11
        movq    (%rax), %r10
        testq   $1, %r10
        jz    Lfailure_loop_end
# unbox value
        sarq    %r10
        movq    %r10, (%rax)
Lfailure_loop_end:
        addq    $8, %rax
        jmp     Lfailure_loop
Lfailure_continue:
        popq    %rsi
        popq    %rdx
        popq    %rcx
        popq    %r8
        popq    %r9
# restore return address
        pushq   %r14
        jmp     failure
