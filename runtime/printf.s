.section .text

.global Lprintf
.extern printf

.global Lfprintf
.extern fprintf

.global Lsprintf
.extern sprintf

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
#        pushq   %rsi
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

