.section .text

.global Lprintf
.extern printf

.global Lfprintf
.extern fprintf

.global Lsprintf
.extern sprintf

.extern cnt_percentage_sign

Lprintf:
        pushq   %rbp
        movq    %rsp, %rbp
        movq    %rdi, -40(%rbp)
        movq    %rsi, -48(%rbp)
        movq    -48(%rbp), %rax
        movq    %rax, -16(%rbp)
        movl    $0, -4(%rbp)
        jmp     .L2
.L5:
        movq    -40(%rbp), %rax
        movzbl  (%rax), %eax
        cmpb    $37, %al
        jne     .L3
        movl    -4(%rbp), %eax
        cltq
        leaq    0(,%rax,8), %rdx
        movq    -16(%rbp), %rax
        addq    %rdx, %rax
        movq    (%rax), %rax
        movq    %rax, -24(%rbp)
        movq    -24(%rbp), %rax
        andl    $1, %eax
        testq   %rax, %rax
        je      .L4
        movl    -4(%rbp), %eax
        cltq
        leaq    0(,%rax,8), %rdx
        movq    -16(%rbp), %rax
        addq    %rdx, %rax
        movq    -24(%rbp), %rdx
        sarq    %rdx
        movq    %rdx, (%rax)
.L4:
        addl    $1, -4(%rbp)
.L3:
        addq    $1, -40(%rbp)
.L2:
        movq    -40(%rbp), %rax
        movzbl  (%rax), %eax
        testb   %al, %al
        jne     .L5
        movq    -40(%rbp), %rax
        movq    %rax, %rdi
        cmpl    $0, -4(%rbp)
        jle     .L6
        movq    -16(%rbp), %rax
        movq    (%rax), %rax
        movq    %rax, %rsi
.L6:
        cmpl    $1, -4(%rbp)
        jle     .L7
        movq    -16(%rbp), %rax
        movq    8(%rax), %rax
        movq    %rax, %rdx
.L7:
        cmpl    $2, -4(%rbp)
        jle     .L8
        movq    -16(%rbp), %rax
        movq    16(%rax), %rax
        movq    %rax, %rcx
.L8:
        cmpl    $3, -4(%rbp)
        jle     .L9
        movq    -16(%rbp), %rax
        movq    24(%rax), %rax
        movq    %rax, %r8
.L9:
        cmpl    $4, -4(%rbp)
        jle     .L11
        movq    -16(%rbp), %rax
        movq    32(%rax), %rax
        movq    %rax, %r9
.L11:
        nop
        popq    %rbp
        jmp     printf
