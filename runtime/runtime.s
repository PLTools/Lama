	.file	"runtime.c"
	.text
	.section	.rodata
.LC0:
	.string	"*** FAILURE: "
	.text
	.type	vfailure, @function
vfailure:
.LFB6:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	stderr(%rip), %rax
	movq	%rax, %rcx
	movl	$13, %edx
	movl	$1, %esi
	leaq	.LC0(%rip), %rax
	movq	%rax, %rdi
	call	fwrite@PLT
	movq	stderr(%rip), %rax
	movq	-16(%rbp), %rdx
	movq	-8(%rbp), %rcx
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	vfprintf@PLT
	movl	$255, %edi
	call	exit@PLT
	.cfi_endproc
.LFE6:
	.size	vfailure, .-vfailure
	.globl	failure
	.type	failure, @function
failure:
.LFB7:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$224, %rsp
	movq	%rdi, -216(%rbp)
	movq	%rsi, -168(%rbp)
	movq	%rdx, -160(%rbp)
	movq	%rcx, -152(%rbp)
	movq	%r8, -144(%rbp)
	movq	%r9, -136(%rbp)
	testb	%al, %al
	je	.L3
	movaps	%xmm0, -128(%rbp)
	movaps	%xmm1, -112(%rbp)
	movaps	%xmm2, -96(%rbp)
	movaps	%xmm3, -80(%rbp)
	movaps	%xmm4, -64(%rbp)
	movaps	%xmm5, -48(%rbp)
	movaps	%xmm6, -32(%rbp)
	movaps	%xmm7, -16(%rbp)
.L3:
	movq	%fs:40, %rax
	movq	%rax, -184(%rbp)
	xorl	%eax, %eax
	movl	$8, -208(%rbp)
	movl	$48, -204(%rbp)
	leaq	16(%rbp), %rax
	movq	%rax, -200(%rbp)
	leaq	-176(%rbp), %rax
	movq	%rax, -192(%rbp)
	leaq	-208(%rbp), %rdx
	movq	-216(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	vfailure
	nop
	movq	-184(%rbp), %rax
	subq	%fs:40, %rax
	je	.L4
	call	__stack_chk_fail@PLT
.L4:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE7:
	.size	failure, .-failure
	.globl	Lassert
	.type	Lassert, @function
Lassert:
.LFB8:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$224, %rsp
	movq	%rdi, -216(%rbp)
	movq	%rsi, -224(%rbp)
	movq	%rdx, -160(%rbp)
	movq	%rcx, -152(%rbp)
	movq	%r8, -144(%rbp)
	movq	%r9, -136(%rbp)
	testb	%al, %al
	je	.L6
	movaps	%xmm0, -128(%rbp)
	movaps	%xmm1, -112(%rbp)
	movaps	%xmm2, -96(%rbp)
	movaps	%xmm3, -80(%rbp)
	movaps	%xmm4, -64(%rbp)
	movaps	%xmm5, -48(%rbp)
	movaps	%xmm6, -32(%rbp)
	movaps	%xmm7, -16(%rbp)
.L6:
	movq	%fs:40, %rax
	movq	%rax, -184(%rbp)
	xorl	%eax, %eax
	movq	-216(%rbp), %rax
	sarq	%rax
	testq	%rax, %rax
	jne	.L9
	movl	$16, -208(%rbp)
	movl	$48, -204(%rbp)
	leaq	16(%rbp), %rax
	movq	%rax, -200(%rbp)
	leaq	-176(%rbp), %rax
	movq	%rax, -192(%rbp)
	leaq	-208(%rbp), %rdx
	movq	-224(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	vfailure
.L9:
	nop
	movq	-184(%rbp), %rax
	subq	%fs:40, %rax
	je	.L8
	call	__stack_chk_fail@PLT
.L8:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE8:
	.size	Lassert, .-Lassert
	.globl	global_sysargs
	.bss
	.align 8
	.type	global_sysargs, @object
	.size	global_sysargs, 8
global_sysargs:
	.zero	8
	.text
	.globl	LkindOf
	.type	LkindOf, @function
LkindOf:
.LFB9:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L11
	movl	$9, %eax
	jmp	.L12
.L11:
	movq	-8(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
.L12:
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE9:
	.size	LkindOf, .-LkindOf
	.section	.rodata
.LC1:
	.string	"compareTags, 0"
.LC2:
	.string	"boxed value expected in %s\n"
.LC3:
	.string	"compareTags, 1"
	.align 8
.LC4:
	.string	"not a sexpr in compareTags: %d, %d\n"
	.text
	.globl	LcompareTags
	.type	LcompareTags, @function
LcompareTags:
.LFB10:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movq	%rsi, -32(%rbp)
	movq	-24(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L14
	leaq	.LC1(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC2(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L14:
	movq	-32(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L15
	leaq	.LC3(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC2(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L15:
	movq	-24(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -16(%rbp)
	movq	-32(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -8(%rbp)
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$5, %eax
	jne	.L16
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$5, %eax
	jne	.L16
	movq	-24(%rbp), %rax
	subq	$12, %rax
	movl	16(%rax), %edx
	movq	-32(%rbp), %rax
	subq	$12, %rax
	movl	16(%rax), %eax
	subl	%eax, %edx
	leal	(%rdx,%rdx), %eax
	orl	$1, %eax
	jmp	.L17
.L16:
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	movl	%eax, %edx
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	movl	%eax, %esi
	leaq	.LC4(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
	movl	$0, %eax
.L17:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE10:
	.size	LcompareTags, .-LcompareTags
	.section	.rodata
.LC5:
	.string	"runtime.c"
.LC6:
	.string	"__gc_stack_top != 0"
	.align 8
.LC7:
	.string	"__builtin_frame_address(0) <= (void *)__gc_stack_top"
.LC8:
	.string	"cons"
	.text
	.globl	Ls__Infix_58
	.type	Ls__Infix_58, @function
Ls__Infix_58:
.LFB11:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movq	%rsi, -32(%rbp)
	movb	$0, -9(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -9(%rbp)
	cmpb	$0, -9(%rbp)
	je	.L19
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L19:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L20
	leaq	__PRETTY_FUNCTION__.15(%rip), %rax
	movq	%rax, %rcx
	movl	$94, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L20:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L21
	leaq	__PRETTY_FUNCTION__.15(%rip), %rax
	movq	%rax, %rcx
	movl	$94, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L21:
	leaq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	leaq	-32(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	leaq	.LC8(%rip), %rax
	movq	%rax, %rdi
	call	LtagHash
	movl	%eax, %ecx
	movq	-32(%rbp), %rdx
	movq	-24(%rbp), %rax
	movq	%rax, %rsi
	movl	$7, %edi
	movl	$0, %eax
	call	Bsexp
	movq	%rax, -8(%rbp)
	leaq	-32(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	leaq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L22
	leaq	__PRETTY_FUNCTION__.15(%rip), %rax
	movq	%rax, %rcx
	movl	$102, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L22:
	cmpb	$0, -9(%rbp)
	je	.L23
	movq	$0, __gc_stack_top(%rip)
.L23:
	movq	-8(%rbp), %rax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE11:
	.size	Ls__Infix_58, .-Ls__Infix_58
	.section	.rodata
.LC9:
	.string	"captured !!:1"
.LC10:
	.string	"unboxed value expected in %s\n"
.LC11:
	.string	"captured !!:2"
	.text
	.globl	Ls__Infix_3333
	.type	Ls__Infix_3333, @function
Ls__Infix_3333:
.LFB12:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L26
	leaq	.LC9(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L26:
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L27
	leaq	.LC11(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L27:
	movq	-8(%rbp), %rax
	sarq	%rax
	testq	%rax, %rax
	jne	.L28
	movq	-16(%rbp), %rax
	sarq	%rax
	testq	%rax, %rax
	je	.L29
.L28:
	movl	$1, %eax
	jmp	.L30
.L29:
	movl	$0, %eax
.L30:
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE12:
	.size	Ls__Infix_3333, .-Ls__Infix_3333
	.section	.rodata
.LC12:
	.string	"captured &&:1"
.LC13:
	.string	"captured &&:2"
	.text
	.globl	Ls__Infix_3838
	.type	Ls__Infix_3838, @function
Ls__Infix_3838:
.LFB13:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L33
	leaq	.LC12(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L33:
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L34
	leaq	.LC13(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L34:
	movq	-8(%rbp), %rax
	sarq	%rax
	testq	%rax, %rax
	je	.L35
	movq	-16(%rbp), %rax
	sarq	%rax
	testq	%rax, %rax
	je	.L35
	movl	$1, %eax
	jmp	.L36
.L35:
	movl	$0, %eax
.L36:
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE13:
	.size	Ls__Infix_3838, .-Ls__Infix_3838
	.globl	Ls__Infix_6161
	.type	Ls__Infix_6161, @function
Ls__Infix_6161:
.LFB14:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	cmpq	-16(%rbp), %rax
	jne	.L39
	movl	$3, %eax
	jmp	.L41
.L39:
	movl	$1, %eax
.L41:
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE14:
	.size	Ls__Infix_6161, .-Ls__Infix_6161
	.section	.rodata
.LC14:
	.string	"captured !=:1"
.LC15:
	.string	"captured !=:2"
	.text
	.globl	Ls__Infix_3361
	.type	Ls__Infix_3361, @function
Ls__Infix_3361:
.LFB15:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L43
	leaq	.LC14(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L43:
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L44
	leaq	.LC15(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L44:
	movq	-8(%rbp), %rax
	sarq	%rax
	movq	%rax, %rdx
	movq	-16(%rbp), %rax
	sarq	%rax
	cmpq	%rax, %rdx
	je	.L45
	movl	$3, %eax
	jmp	.L47
.L45:
	movl	$1, %eax
.L47:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE15:
	.size	Ls__Infix_3361, .-Ls__Infix_3361
	.section	.rodata
.LC16:
	.string	"captured <=:1"
.LC17:
	.string	"captured <=:2"
	.text
	.globl	Ls__Infix_6061
	.type	Ls__Infix_6061, @function
Ls__Infix_6061:
.LFB16:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L49
	leaq	.LC16(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L49:
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L50
	leaq	.LC17(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L50:
	movq	-8(%rbp), %rax
	sarq	%rax
	movq	%rax, %rdx
	movq	-16(%rbp), %rax
	sarq	%rax
	cmpq	%rax, %rdx
	jg	.L51
	movl	$3, %eax
	jmp	.L53
.L51:
	movl	$1, %eax
.L53:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE16:
	.size	Ls__Infix_6061, .-Ls__Infix_6061
	.section	.rodata
.LC18:
	.string	"captured <:1"
.LC19:
	.string	"captured <:2"
	.text
	.globl	Ls__Infix_60
	.type	Ls__Infix_60, @function
Ls__Infix_60:
.LFB17:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L55
	leaq	.LC18(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L55:
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L56
	leaq	.LC19(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L56:
	movq	-8(%rbp), %rax
	sarq	%rax
	movq	%rax, %rdx
	movq	-16(%rbp), %rax
	sarq	%rax
	cmpq	%rax, %rdx
	jge	.L57
	movl	$3, %eax
	jmp	.L59
.L57:
	movl	$1, %eax
.L59:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE17:
	.size	Ls__Infix_60, .-Ls__Infix_60
	.section	.rodata
.LC20:
	.string	"captured >=:1"
.LC21:
	.string	"captured >=:2"
	.text
	.globl	Ls__Infix_6261
	.type	Ls__Infix_6261, @function
Ls__Infix_6261:
.LFB18:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L61
	leaq	.LC20(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L61:
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L62
	leaq	.LC21(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L62:
	movq	-8(%rbp), %rax
	sarq	%rax
	movq	%rax, %rdx
	movq	-16(%rbp), %rax
	sarq	%rax
	cmpq	%rax, %rdx
	jl	.L63
	movl	$3, %eax
	jmp	.L65
.L63:
	movl	$1, %eax
.L65:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE18:
	.size	Ls__Infix_6261, .-Ls__Infix_6261
	.section	.rodata
.LC22:
	.string	"captured >:1"
.LC23:
	.string	"captured >:2"
	.text
	.globl	Ls__Infix_62
	.type	Ls__Infix_62, @function
Ls__Infix_62:
.LFB19:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L67
	leaq	.LC22(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L67:
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L68
	leaq	.LC23(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L68:
	movq	-8(%rbp), %rax
	sarq	%rax
	movq	%rax, %rdx
	movq	-16(%rbp), %rax
	sarq	%rax
	cmpq	%rax, %rdx
	jle	.L69
	movl	$3, %eax
	jmp	.L71
.L69:
	movl	$1, %eax
.L71:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE19:
	.size	Ls__Infix_62, .-Ls__Infix_62
	.section	.rodata
.LC24:
	.string	"captured +:1"
.LC25:
	.string	"captured +:2"
	.text
	.globl	Ls__Infix_43
	.type	Ls__Infix_43, @function
Ls__Infix_43:
.LFB20:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L73
	leaq	.LC24(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L73:
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L74
	leaq	.LC25(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L74:
	movq	-8(%rbp), %rax
	sarq	%rax
	movq	%rax, %rdx
	movq	-16(%rbp), %rax
	sarq	%rax
	addq	%rdx, %rax
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE20:
	.size	Ls__Infix_43, .-Ls__Infix_43
	.section	.rodata
.LC26:
	.string	"captured -:2"
.LC27:
	.string	"captured -:1"
	.text
	.globl	Ls__Infix_45
	.type	Ls__Infix_45, @function
Ls__Infix_45:
.LFB21:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L77
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L78
	leaq	.LC26(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L78:
	movq	-8(%rbp), %rax
	sarq	%rax
	movq	%rax, %rdx
	movq	-16(%rbp), %rax
	sarq	%rax
	subq	%rax, %rdx
	movl	%edx, %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L79
.L77:
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L80
	leaq	.LC27(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC2(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L80:
	movq	-8(%rbp), %rax
	subq	-16(%rbp), %rax
	addl	%eax, %eax
	orl	$1, %eax
.L79:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE21:
	.size	Ls__Infix_45, .-Ls__Infix_45
	.section	.rodata
.LC28:
	.string	"captured *:1"
.LC29:
	.string	"captured *:2"
	.text
	.globl	Ls__Infix_42
	.type	Ls__Infix_42, @function
Ls__Infix_42:
.LFB22:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L82
	leaq	.LC28(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L82:
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L83
	leaq	.LC29(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L83:
	movq	-8(%rbp), %rax
	sarq	%rax
	movl	%eax, %edx
	movq	-16(%rbp), %rax
	sarq	%rax
	imull	%edx, %eax
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE22:
	.size	Ls__Infix_42, .-Ls__Infix_42
	.section	.rodata
.LC30:
	.string	"captured /:1"
.LC31:
	.string	"captured /:2"
	.text
	.globl	Ls__Infix_47
	.type	Ls__Infix_47, @function
Ls__Infix_47:
.LFB23:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L86
	leaq	.LC30(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L86:
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L87
	leaq	.LC31(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L87:
	movq	-8(%rbp), %rax
	sarq	%rax
	movq	-16(%rbp), %rdx
	movq	%rdx, %rcx
	sarq	%rcx
	cqto
	idivq	%rcx
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE23:
	.size	Ls__Infix_47, .-Ls__Infix_47
	.section	.rodata
.LC32:
	.string	"captured %:1"
.LC33:
	.string	"captured %:2"
	.text
	.globl	Ls__Infix_37
	.type	Ls__Infix_37, @function
Ls__Infix_37:
.LFB24:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L90
	leaq	.LC32(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L90:
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L91
	leaq	.LC33(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L91:
	movq	-8(%rbp), %rax
	sarq	%rax
	movq	-16(%rbp), %rdx
	sarq	%rdx
	movq	%rdx, %rcx
	cqto
	idivq	%rcx
	movq	%rdx, %rcx
	movq	%rcx, %rax
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE24:
	.size	Ls__Infix_37, .-Ls__Infix_37
	.section	.rodata
.LC34:
	.string	".length"
	.text
	.globl	Llength
	.type	Llength, @function
Llength:
.LFB25:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L94
	leaq	.LC34(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC2(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L94:
	movq	-8(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE25:
	.size	Llength, .-Llength
	.section	.rodata
	.align 8
.LC35:
	.string	"_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'"
	.section	.data.rel.local,"aw"
	.align 8
	.type	chars, @object
	.size	chars, 8
chars:
	.quad	.LC35
	.section	.rodata
	.align 8
.LC36:
	.string	"tagHash: character not found: %c\n"
.LC37:
	.string	"%s <-> %s\n"
	.text
	.globl	LtagHash
	.type	LtagHash, @function
LtagHash:
.LFB26:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	%rdi, -40(%rbp)
	movl	$0, -28(%rbp)
	movl	$0, -24(%rbp)
	movq	-40(%rbp), %rax
	movq	%rax, -16(%rbp)
	jmp	.L97
.L104:
	movq	chars(%rip), %rax
	movq	%rax, -8(%rbp)
	movl	$0, -20(%rbp)
	jmp	.L98
.L100:
	addq	$1, -8(%rbp)
	addl	$1, -20(%rbp)
.L98:
	movq	-8(%rbp), %rax
	movzbl	(%rax), %eax
	testb	%al, %al
	je	.L99
	movq	-8(%rbp), %rax
	movzbl	(%rax), %edx
	movq	-16(%rbp), %rax
	movzbl	(%rax), %eax
	cmpb	%al, %dl
	jne	.L100
.L99:
	movq	-8(%rbp), %rax
	movzbl	(%rax), %eax
	testb	%al, %al
	je	.L101
	movl	-28(%rbp), %eax
	sall	$6, %eax
	orl	-20(%rbp), %eax
	movl	%eax, -28(%rbp)
	jmp	.L102
.L101:
	movq	-16(%rbp), %rax
	movzbl	(%rax), %eax
	movsbl	%al, %eax
	movl	%eax, %esi
	leaq	.LC36(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L102:
	addq	$1, -16(%rbp)
.L97:
	movq	-16(%rbp), %rax
	movzbl	(%rax), %eax
	testb	%al, %al
	je	.L103
	movl	-24(%rbp), %eax
	leal	1(%rax), %edx
	movl	%edx, -24(%rbp)
	cmpl	$4, %eax
	jle	.L104
.L103:
	movl	-28(%rbp), %eax
	movl	%eax, %edi
	call	de_hash
	movq	%rax, %rcx
	movq	-40(%rbp), %rax
	movl	$5, %edx
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	strncmp@PLT
	testl	%eax, %eax
	je	.L105
	movl	-28(%rbp), %eax
	movl	%eax, %edi
	call	de_hash
	movq	%rax, %rdx
	movq	-40(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC37(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L105:
	movl	-28(%rbp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE26:
	.size	LtagHash, .-LtagHash
	.globl	de_hash
	.type	de_hash, @function
de_hash:
.LFB27:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	%edi, -20(%rbp)
	movq	$1, -8(%rbp)
	leaq	5+buf.14(%rip), %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	leaq	-1(%rax), %rdx
	movq	%rdx, -8(%rbp)
	movb	$0, (%rax)
	jmp	.L108
.L109:
	movq	chars(%rip), %rax
	movl	-20(%rbp), %edx
	movslq	%edx, %rdx
	andl	$63, %edx
	leaq	(%rax,%rdx), %rcx
	movq	-8(%rbp), %rax
	leaq	-1(%rax), %rdx
	movq	%rdx, -8(%rbp)
	movzbl	(%rcx), %edx
	movb	%dl, (%rax)
	sarl	$6, -20(%rbp)
.L108:
	cmpl	$0, -20(%rbp)
	jne	.L109
	addq	$1, -8(%rbp)
	movq	-8(%rbp), %rax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE27:
	.size	de_hash, .-de_hash
	.local	stringBuf
	.comm	stringBuf,16,16
	.type	createStringBuf, @function
createStringBuf:
.LFB28:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	$128, %edi
	call	malloc@PLT
	movq	%rax, stringBuf(%rip)
	movq	stringBuf(%rip), %rax
	movl	$128, %edx
	movl	$0, %esi
	movq	%rax, %rdi
	call	memset@PLT
	movl	$0, 8+stringBuf(%rip)
	movl	$128, 12+stringBuf(%rip)
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE28:
	.size	createStringBuf, .-createStringBuf
	.type	deleteStringBuf, @function
deleteStringBuf:
.LFB29:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	stringBuf(%rip), %rax
	movq	%rax, %rdi
	call	free@PLT
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE29:
	.size	deleteStringBuf, .-deleteStringBuf
	.type	extendStringBuf, @function
extendStringBuf:
.LFB30:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movl	12+stringBuf(%rip), %eax
	addl	%eax, %eax
	movl	%eax, -4(%rbp)
	movl	-4(%rbp), %eax
	movslq	%eax, %rdx
	movq	stringBuf(%rip), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	realloc@PLT
	movq	%rax, stringBuf(%rip)
	movl	-4(%rbp), %eax
	movl	%eax, 12+stringBuf(%rip)
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE30:
	.size	extendStringBuf, .-extendStringBuf
	.type	vprintStringBuf, @function
vprintStringBuf:
.LFB31:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$64, %rsp
	movq	%rdi, -56(%rbp)
	movq	%rsi, -64(%rbp)
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	movl	$0, -48(%rbp)
	movl	$0, -44(%rbp)
	movq	$1, -40(%rbp)
.L115:
	leaq	-32(%rbp), %rcx
	movq	-64(%rbp), %rsi
	movq	(%rsi), %rax
	movq	8(%rsi), %rdx
	movq	%rax, (%rcx)
	movq	%rdx, 8(%rcx)
	movq	16(%rsi), %rax
	movq	%rax, 16(%rcx)
	movq	stringBuf(%rip), %rdx
	movl	8+stringBuf(%rip), %eax
	cltq
	addq	%rdx, %rax
	movq	%rax, -40(%rbp)
	movl	12+stringBuf(%rip), %edx
	movl	8+stringBuf(%rip), %eax
	subl	%eax, %edx
	movl	%edx, -44(%rbp)
	movl	-44(%rbp), %eax
	movslq	%eax, %rsi
	leaq	-32(%rbp), %rcx
	movq	-56(%rbp), %rdx
	movq	-40(%rbp), %rax
	movq	%rax, %rdi
	call	vsnprintf@PLT
	movl	%eax, -48(%rbp)
	movl	-48(%rbp), %eax
	cmpl	-44(%rbp), %eax
	jl	.L116
	movl	$0, %eax
	call	extendStringBuf
	jmp	.L115
.L116:
	movl	8+stringBuf(%rip), %edx
	movl	-48(%rbp), %eax
	addl	%edx, %eax
	movl	%eax, 8+stringBuf(%rip)
	nop
	movq	-8(%rbp), %rax
	subq	%fs:40, %rax
	je	.L117
	call	__stack_chk_fail@PLT
.L117:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE31:
	.size	vprintStringBuf, .-vprintStringBuf
	.type	printStringBuf, @function
printStringBuf:
.LFB32:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$224, %rsp
	movq	%rdi, -216(%rbp)
	movq	%rsi, -168(%rbp)
	movq	%rdx, -160(%rbp)
	movq	%rcx, -152(%rbp)
	movq	%r8, -144(%rbp)
	movq	%r9, -136(%rbp)
	testb	%al, %al
	je	.L119
	movaps	%xmm0, -128(%rbp)
	movaps	%xmm1, -112(%rbp)
	movaps	%xmm2, -96(%rbp)
	movaps	%xmm3, -80(%rbp)
	movaps	%xmm4, -64(%rbp)
	movaps	%xmm5, -48(%rbp)
	movaps	%xmm6, -32(%rbp)
	movaps	%xmm7, -16(%rbp)
.L119:
	movq	%fs:40, %rax
	movq	%rax, -184(%rbp)
	xorl	%eax, %eax
	movl	$8, -208(%rbp)
	movl	$48, -204(%rbp)
	leaq	16(%rbp), %rax
	movq	%rax, -200(%rbp)
	leaq	-176(%rbp), %rax
	movq	%rax, -192(%rbp)
	leaq	-208(%rbp), %rdx
	movq	-216(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	vprintStringBuf
	nop
	movq	-184(%rbp), %rax
	subq	%fs:40, %rax
	je	.L120
	call	__stack_chk_fail@PLT
.L120:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE32:
	.size	printStringBuf, .-printStringBuf
	.section	.rodata
.LC38:
	.string	"%d"
.LC39:
	.string	"0x%x"
.LC40:
	.string	"\"%s\""
.LC41:
	.string	"<closure "
.LC42:
	.string	", "
.LC43:
	.string	">"
.LC44:
	.string	"["
.LC45:
	.string	"]"
.LC46:
	.string	"{"
.LC47:
	.string	"}"
.LC48:
	.string	"%s"
.LC49:
	.string	" ("
.LC50:
	.string	")"
	.align 8
.LC51:
	.string	"*** invalid data_header: 0x%x ***"
	.text
	.type	printValue, @function
printValue:
.LFB33:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$64, %rsp
	movq	%rdi, -56(%rbp)
	movq	$1, -32(%rbp)
	movl	$1, -48(%rbp)
	movq	-56(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L122
	movq	-56(%rbp), %rax
	sarq	%rax
	movq	%rax, %rsi
	leaq	.LC38(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	jmp	.L121
.L122:
	movq	-56(%rbp), %rax
	movq	%rax, %rdi
	call	is_valid_heap_pointer@PLT
	xorl	$1, %eax
	testb	%al, %al
	je	.L124
	movq	-56(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC39(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	jmp	.L121
.L124:
	movq	-56(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -32(%rbp)
	movq	-32(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$7, %eax
	je	.L125
	cmpl	$7, %eax
	jg	.L126
	cmpl	$5, %eax
	je	.L127
	cmpl	$5, %eax
	jg	.L126
	cmpl	$1, %eax
	je	.L128
	cmpl	$3, %eax
	je	.L129
	jmp	.L126
.L128:
	movq	-32(%rbp), %rax
	addq	$16, %rax
	movq	%rax, %rsi
	leaq	.LC40(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	jmp	.L121
.L125:
	leaq	.LC41(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	movl	$0, -48(%rbp)
	jmp	.L130
.L134:
	cmpl	$0, -48(%rbp)
	je	.L131
	movq	-32(%rbp), %rax
	leaq	16(%rax), %rdx
	movl	-48(%rbp), %eax
	cltq
	salq	$2, %rax
	addq	%rdx, %rax
	movl	(%rax), %eax
	cltq
	movq	%rax, %rdi
	call	printValue
	jmp	.L132
.L131:
	movq	-32(%rbp), %rax
	leaq	16(%rax), %rdx
	movl	-48(%rbp), %eax
	cltq
	salq	$2, %rax
	addq	%rdx, %rax
	movl	(%rax), %eax
	cltq
	movq	%rax, %rsi
	leaq	.LC39(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
.L132:
	movq	-32(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	leal	-1(%rax), %edx
	movl	-48(%rbp), %eax
	cmpl	%eax, %edx
	je	.L133
	leaq	.LC42(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
.L133:
	addl	$1, -48(%rbp)
.L130:
	movq	-32(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	-48(%rbp), %edx
	cmpl	%eax, %edx
	jb	.L134
	leaq	.LC43(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	jmp	.L121
.L129:
	leaq	.LC44(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	movl	$0, -48(%rbp)
	jmp	.L135
.L137:
	movq	-32(%rbp), %rax
	leaq	16(%rax), %rdx
	movl	-48(%rbp), %eax
	cltq
	salq	$2, %rax
	addq	%rdx, %rax
	movl	(%rax), %eax
	cltq
	movq	%rax, %rdi
	call	printValue
	movq	-32(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	leal	-1(%rax), %edx
	movl	-48(%rbp), %eax
	cmpl	%eax, %edx
	je	.L136
	leaq	.LC42(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
.L136:
	addl	$1, -48(%rbp)
.L135:
	movq	-32(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	-48(%rbp), %edx
	cmpl	%eax, %edx
	jb	.L137
	leaq	.LC45(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	jmp	.L121
.L127:
	movq	-32(%rbp), %rax
	movq	%rax, -24(%rbp)
	movq	-24(%rbp), %rax
	movl	16(%rax), %eax
	movl	%eax, %edi
	call	de_hash
	movq	%rax, -16(%rbp)
	movq	-16(%rbp), %rax
	leaq	.LC8(%rip), %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L138
	movq	-24(%rbp), %rax
	movq	%rax, -40(%rbp)
	leaq	.LC46(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	jmp	.L139
.L142:
	movq	-40(%rbp), %rax
	movl	20(%rax), %eax
	cltq
	movq	%rax, %rdi
	call	printValue
	movq	-40(%rbp), %rax
	movl	24(%rax), %eax
	movl	%eax, -44(%rbp)
	movl	-44(%rbp), %eax
	cltq
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L147
	leaq	.LC42(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	movl	-44(%rbp), %eax
	cltq
	subq	$12, %rax
	movq	%rax, -40(%rbp)
.L139:
	movq	-40(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	testl	%eax, %eax
	jne	.L142
	jmp	.L141
.L147:
	nop
.L141:
	leaq	.LC47(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	jmp	.L148
.L138:
	movq	-16(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC48(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	movq	-32(%rbp), %rax
	movq	%rax, -8(%rbp)
	movq	-32(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	testl	%eax, %eax
	je	.L148
	leaq	.LC49(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	movl	$0, -48(%rbp)
	jmp	.L144
.L146:
	movq	-8(%rbp), %rax
	leaq	20(%rax), %rdx
	movl	-48(%rbp), %eax
	cltq
	salq	$2, %rax
	addq	%rdx, %rax
	movl	(%rax), %eax
	cltq
	movq	%rax, %rdi
	call	printValue
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	leal	-1(%rax), %edx
	movl	-48(%rbp), %eax
	cmpl	%eax, %edx
	je	.L145
	leaq	.LC42(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
.L145:
	addl	$1, -48(%rbp)
.L144:
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	-48(%rbp), %edx
	cmpl	%eax, %edx
	jb	.L146
	leaq	.LC50(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	jmp	.L148
.L126:
	movq	-32(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	movl	%eax, %esi
	leaq	.LC51(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	jmp	.L121
.L148:
	nop
.L121:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE33:
	.size	printValue, .-printValue
	.section	.rodata
	.align 8
.LC52:
	.string	"*** non-list data_header: %s ***"
	.text
	.type	stringcat, @function
stringcat:
.LFB34:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	%rdi, -40(%rbp)
	movq	-40(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L161
	movq	-40(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -16(%rbp)
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L151
	cmpl	$5, %eax
	je	.L152
	jmp	.L160
.L151:
	movq	-16(%rbp), %rax
	addq	$16, %rax
	movq	%rax, %rsi
	leaq	.LC48(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	jmp	.L150
.L152:
	movq	-40(%rbp), %rax
	subq	$12, %rax
	movl	16(%rax), %eax
	movl	%eax, %edi
	call	de_hash
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	leaq	.LC8(%rip), %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L154
	movq	-16(%rbp), %rax
	movq	%rax, -24(%rbp)
	jmp	.L155
.L158:
	movq	-24(%rbp), %rax
	movl	20(%rax), %eax
	cltq
	movq	%rax, %rdi
	call	stringcat
	movq	-24(%rbp), %rax
	movl	24(%rax), %eax
	movl	%eax, -28(%rbp)
	movl	-28(%rbp), %eax
	cltq
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L162
	movl	-28(%rbp), %eax
	cltq
	subq	$12, %rax
	movq	%rax, -24(%rbp)
.L155:
	movq	-24(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	testl	%eax, %eax
	jne	.L158
	jmp	.L150
.L154:
	movq	-8(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC52(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	jmp	.L150
.L162:
	nop
	jmp	.L150
.L160:
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	movl	%eax, %esi
	leaq	.LC51(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printStringBuf
	jmp	.L161
.L150:
.L161:
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE34:
	.size	stringcat, .-stringcat
	.section	.rodata
.LC53:
	.string	"Luppercase:1"
	.text
	.globl	Luppercase
	.type	Luppercase, @function
Luppercase:
.LFB35:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L164
	leaq	.LC53(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L164:
	movq	-8(%rbp), %rax
	sarq	%rax
	movl	%eax, %edi
	call	toupper@PLT
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE35:
	.size	Luppercase, .-Luppercase
	.section	.rodata
.LC54:
	.string	"Llowercase:1"
	.text
	.globl	Llowercase
	.type	Llowercase, @function
Llowercase:
.LFB36:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L167
	leaq	.LC54(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L167:
	movq	-8(%rbp), %rax
	sarq	%rax
	movl	%eax, %edi
	call	tolower@PLT
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE36:
	.size	Llowercase, .-Llowercase
	.section	.rodata
.LC55:
	.string	"matchSubString:1"
.LC56:
	.string	"string value expected in %s\n"
.LC57:
	.string	"matchSubString:2"
.LC58:
	.string	"matchSubString:3"
	.text
	.globl	LmatchSubString
	.type	LmatchSubString, @function
LmatchSubString:
.LFB37:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$64, %rsp
	movq	%rdi, -40(%rbp)
	movq	%rsi, -48(%rbp)
	movl	%edx, -52(%rbp)
	movq	-48(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -16(%rbp)
	movq	-40(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -8(%rbp)
	movq	-40(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L170
	movq	-40(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L170
	leaq	.LC55(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L170:
	movq	-48(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L171
	movq	-48(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L171
	leaq	.LC57(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L171:
	movl	-52(%rbp), %eax
	cltq
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L172
	leaq	.LC58(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L172:
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, -20(%rbp)
	movl	-20(%rbp), %eax
	movslq	%eax, %rdx
	movl	-52(%rbp), %eax
	sarl	%eax
	cltq
	addq	%rax, %rdx
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, %eax
	cmpq	%rax, %rdx
	jle	.L173
	movl	$1, %eax
	jmp	.L174
.L173:
	movl	-20(%rbp), %eax
	movslq	%eax, %rdx
	movl	-52(%rbp), %eax
	sarl	%eax
	movslq	%eax, %rcx
	movq	-40(%rbp), %rax
	addq	%rax, %rcx
	movq	-48(%rbp), %rax
	movq	%rax, %rsi
	movq	%rcx, %rdi
	call	strncmp@PLT
	testl	%eax, %eax
	jne	.L175
	movl	$3, %eax
	jmp	.L174
.L175:
	movl	$1, %eax
.L174:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE37:
	.size	LmatchSubString, .-LmatchSubString
	.section	.rodata
.LC59:
	.string	"substring:1"
.LC60:
	.string	"substring:2"
.LC61:
	.string	"substring:3"
	.align 8
.LC62:
	.string	"substring: index out of bounds (position=%d, length=%d,             subject length=%d)"
	.text
	.globl	Lsubstring
	.type	Lsubstring, @function
Lsubstring:
.LFB38:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	%rdi, -40(%rbp)
	movl	%esi, -44(%rbp)
	movl	%edx, -48(%rbp)
	movq	-40(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -16(%rbp)
	movl	-44(%rbp), %eax
	sarl	%eax
	movl	%eax, -24(%rbp)
	movl	-48(%rbp), %eax
	sarl	%eax
	movl	%eax, -20(%rbp)
	movq	-40(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L178
	movq	-40(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L178
	leaq	.LC59(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L178:
	movl	-44(%rbp), %eax
	cltq
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L179
	leaq	.LC60(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L179:
	movl	-48(%rbp), %eax
	cltq
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L180
	leaq	.LC61(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L180:
	movl	-24(%rbp), %edx
	movl	-20(%rbp), %eax
	addl	%edx, %eax
	movl	%eax, %edx
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	cmpl	%edx, %eax
	jb	.L181
	movb	$0, -25(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -25(%rbp)
	cmpb	$0, -25(%rbp)
	je	.L182
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L182:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L183
	leaq	__PRETTY_FUNCTION__.13(%rip), %rax
	movq	%rax, %rcx
	movl	$453, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L183:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L184
	leaq	__PRETTY_FUNCTION__.13(%rip), %rax
	movq	%rax, %rcx
	movl	$453, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L184:
	leaq	-40(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	movl	-20(%rbp), %eax
	movl	%eax, %edi
	call	alloc_string@PLT
	movq	%rax, -8(%rbp)
	leaq	-40(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	movl	-20(%rbp), %eax
	cltq
	movq	-40(%rbp), %rcx
	movl	-24(%rbp), %edx
	movslq	%edx, %rdx
	leaq	(%rcx,%rdx), %rsi
	movq	-8(%rbp), %rdx
	leaq	16(%rdx), %rcx
	movq	%rax, %rdx
	movq	%rcx, %rdi
	call	strncpy@PLT
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L185
	leaq	__PRETTY_FUNCTION__.13(%rip), %rax
	movq	%rax, %rcx
	movl	$461, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L185:
	cmpb	$0, -25(%rbp)
	je	.L186
	movq	$0, __gc_stack_top(%rip)
.L186:
	movq	-8(%rbp), %rax
	addq	$16, %rax
	jmp	.L177
.L181:
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, %ecx
	movl	-20(%rbp), %edx
	movl	-24(%rbp), %eax
	movl	%eax, %esi
	leaq	.LC62(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L177:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE38:
	.size	Lsubstring, .-Lsubstring
	.section	.rodata
.LC63:
	.string	"%"
	.text
	.globl	Lregexp
	.type	Lregexp, @function
Lregexp:
.LFB39:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movl	$64, %edi
	call	malloc@PLT
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	$64, %edx
	movl	$0, %esi
	movq	%rax, %rdi
	call	memset@PLT
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	strlen@PLT
	movq	%rax, %rcx
	movq	-8(%rbp), %rdx
	movq	-24(%rbp), %rax
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	re_compile_pattern@PLT
	movl	%eax, -12(%rbp)
	cmpl	$0, -12(%rbp)
	je	.L189
	movl	-12(%rbp), %eax
	movl	%eax, %edi
	call	strerror@PLT
	movq	%rax, %rsi
	leaq	.LC63(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L189:
	movq	-8(%rbp), %rax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE39:
	.size	Lregexp, .-Lregexp
	.section	.rodata
.LC64:
	.string	"regexpMatch:1"
.LC65:
	.string	"regexpMatch:2"
.LC66:
	.string	"regexpMatch:3"
	.text
	.globl	LregexpMatch
	.type	LregexpMatch, @function
LregexpMatch:
.LFB40:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	%rdi, -24(%rbp)
	movq	%rsi, -32(%rbp)
	movl	%edx, -36(%rbp)
	movq	-24(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L192
	leaq	.LC64(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC2(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L192:
	movq	-32(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L193
	movq	-32(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L193
	leaq	.LC65(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L193:
	movl	-36(%rbp), %eax
	cltq
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L194
	leaq	.LC66(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L194:
	movl	-36(%rbp), %eax
	sarl	%eax
	movl	%eax, %edx
	movq	-32(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, %edi
	movq	-32(%rbp), %rsi
	movq	-24(%rbp), %rax
	movl	$0, %r8d
	movl	%edx, %ecx
	movl	%edi, %edx
	movq	%rax, %rdi
	call	re_match@PLT
	movl	%eax, -4(%rbp)
	cmpl	$0, -4(%rbp)
	je	.L195
	movl	-4(%rbp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L196
.L195:
	movl	-4(%rbp), %eax
	addl	%eax, %eax
	orl	$1, %eax
.L196:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE40:
	.size	LregexpMatch, .-LregexpMatch
	.section	.rodata
	.align 8
.LC67:
	.string	"invalid data_header %d in clone *****\n"
	.text
	.globl	Lclone
	.type	Lclone, @function
Lclone:
.LFB41:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$64, %rsp
	movq	%rdi, -56(%rbp)
	movq	-56(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L198
	movq	-56(%rbp), %rax
	jmp	.L199
.L198:
	movb	$0, -33(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -33(%rbp)
	cmpb	$0, -33(%rbp)
	je	.L200
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L200:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L201
	leaq	__PRETTY_FUNCTION__.12(%rip), %rax
	movq	%rax, %rcx
	movl	$512, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L201:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L202
	leaq	__PRETTY_FUNCTION__.12(%rip), %rax
	movq	%rax, %rcx
	movl	$512, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L202:
	movq	-56(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -16(%rbp)
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	movl	%eax, -32(%rbp)
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, -28(%rbp)
	leaq	-56(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	cmpl	$7, -32(%rbp)
	je	.L203
	cmpl	$7, -32(%rbp)
	jg	.L204
	cmpl	$5, -32(%rbp)
	je	.L205
	cmpl	$5, -32(%rbp)
	jg	.L204
	cmpl	$1, -32(%rbp)
	je	.L206
	cmpl	$3, -32(%rbp)
	je	.L207
	jmp	.L204
.L206:
	movq	-56(%rbp), %rax
	subq	$12, %rax
	addq	$16, %rax
	movq	%rax, %rdi
	call	Bstring
	movq	%rax, -24(%rbp)
	jmp	.L208
.L207:
	movl	-28(%rbp), %eax
	movl	%eax, %edi
	call	alloc_array@PLT
	movq	%rax, -8(%rbp)
	movl	-28(%rbp), %eax
	cltq
	movq	%rax, %rdi
	call	array_size@PLT
	movq	%rax, %rdx
	movq	-56(%rbp), %rax
	leaq	-12(%rax), %rcx
	movq	-8(%rbp), %rax
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	memcpy@PLT
	movq	-8(%rbp), %rax
	addq	$16, %rax
	movq	%rax, -24(%rbp)
	jmp	.L208
.L203:
	movl	-28(%rbp), %eax
	movl	%eax, %edi
	call	alloc_closure@PLT
	movq	%rax, -8(%rbp)
	movl	-28(%rbp), %eax
	cltq
	movq	%rax, %rdi
	call	closure_size@PLT
	movq	%rax, %rdx
	movq	-56(%rbp), %rax
	leaq	-12(%rax), %rcx
	movq	-8(%rbp), %rax
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	memcpy@PLT
	movq	-8(%rbp), %rax
	addq	$16, %rax
	movq	%rax, -24(%rbp)
	jmp	.L208
.L205:
	movl	-28(%rbp), %eax
	movl	%eax, %edi
	call	alloc_sexp@PLT
	movq	%rax, -8(%rbp)
	movl	-28(%rbp), %eax
	cltq
	movq	%rax, %rdi
	call	sexp_size@PLT
	movq	%rax, %rdx
	movq	-56(%rbp), %rax
	leaq	-12(%rax), %rcx
	movq	-8(%rbp), %rax
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	memcpy@PLT
	movq	-8(%rbp), %rax
	addq	$16, %rax
	movq	%rax, -24(%rbp)
	jmp	.L208
.L204:
	movl	-32(%rbp), %eax
	movl	%eax, %esi
	leaq	.LC67(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L208:
	leaq	-56(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L209
	leaq	__PRETTY_FUNCTION__.12(%rip), %rax
	movq	%rax, %rcx
	movl	$542, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L209:
	cmpb	$0, -33(%rbp)
	je	.L210
	movq	$0, __gc_stack_top(%rip)
.L210:
	movq	-24(%rbp), %rax
.L199:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE41:
	.size	Lclone, .-Lclone
	.section	.rodata
	.align 8
.LC68:
	.string	"invalid data_header %d in hash *****\n"
	.text
	.globl	inner_hash
	.type	inner_hash, @function
inner_hash:
.LFB42:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$64, %rsp
	movl	%edi, -52(%rbp)
	movl	%esi, -56(%rbp)
	movq	%rdx, -64(%rbp)
	cmpl	$3, -52(%rbp)
	jle	.L212
	movl	-56(%rbp), %eax
	jmp	.L213
.L212:
	movq	-64(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L214
	movq	-64(%rbp), %rax
	sarq	%rax
	movl	%eax, %edx
	movl	-56(%rbp), %eax
	addl	%edx, %eax
	roll	$16, %eax
	jmp	.L213
.L214:
	movq	-64(%rbp), %rax
	movq	%rax, %rdi
	call	is_valid_heap_pointer@PLT
	testb	%al, %al
	je	.L215
	movq	-64(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	movl	%eax, -28(%rbp)
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, -36(%rbp)
	movl	-28(%rbp), %edx
	movl	-56(%rbp), %eax
	addl	%edx, %eax
	roll	$16, %eax
	movl	%eax, -56(%rbp)
	movl	-36(%rbp), %edx
	movl	-56(%rbp), %eax
	addl	%edx, %eax
	roll	$16, %eax
	movl	%eax, -56(%rbp)
	cmpl	$7, -28(%rbp)
	je	.L216
	cmpl	$7, -28(%rbp)
	jg	.L217
	cmpl	$5, -28(%rbp)
	je	.L218
	cmpl	$5, -28(%rbp)
	jg	.L217
	cmpl	$1, -28(%rbp)
	je	.L219
	cmpl	$3, -28(%rbp)
	je	.L220
	jmp	.L217
.L219:
	movq	-8(%rbp), %rax
	addq	$16, %rax
	movq	%rax, -16(%rbp)
	jmp	.L221
.L222:
	movq	-16(%rbp), %rax
	leaq	1(%rax), %rdx
	movq	%rdx, -16(%rbp)
	movzbl	(%rax), %eax
	movsbl	%al, %eax
	movl	%eax, -20(%rbp)
	movl	-20(%rbp), %edx
	movl	-56(%rbp), %eax
	addl	%edx, %eax
	roll	$16, %eax
	movl	%eax, -56(%rbp)
.L221:
	movq	-16(%rbp), %rax
	movzbl	(%rax), %eax
	testb	%al, %al
	jne	.L222
	movl	-56(%rbp), %eax
	jmp	.L213
.L216:
	movq	-8(%rbp), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movl	%eax, %edx
	movl	-56(%rbp), %eax
	addl	%edx, %eax
	roll	$16, %eax
	movl	%eax, -56(%rbp)
	movl	$1, -32(%rbp)
	jmp	.L223
.L220:
	movl	$0, -32(%rbp)
	jmp	.L223
.L218:
	movq	-64(%rbp), %rax
	subq	$12, %rax
	movl	16(%rax), %eax
	movl	%eax, -24(%rbp)
	movl	-24(%rbp), %edx
	movl	-56(%rbp), %eax
	addl	%edx, %eax
	roll	$16, %eax
	movl	%eax, -56(%rbp)
	movl	$1, -32(%rbp)
	addl	$1, -36(%rbp)
	jmp	.L223
.L217:
	movl	-28(%rbp), %eax
	movl	%eax, %esi
	leaq	.LC68(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L223:
	jmp	.L224
.L225:
	movq	-8(%rbp), %rax
	leaq	16(%rax), %rdx
	movl	-32(%rbp), %eax
	cltq
	salq	$3, %rax
	addq	%rdx, %rax
	movq	(%rax), %rdx
	movl	-52(%rbp), %eax
	leal	1(%rax), %ecx
	movl	-56(%rbp), %eax
	movl	%eax, %esi
	movl	%ecx, %edi
	call	inner_hash
	movl	%eax, -56(%rbp)
	addl	$1, -32(%rbp)
.L224:
	movl	-32(%rbp), %eax
	cmpl	-36(%rbp), %eax
	jl	.L225
	movl	-56(%rbp), %eax
	jmp	.L213
.L215:
	movq	-64(%rbp), %rax
	movl	%eax, %edx
	movl	-56(%rbp), %eax
	addl	%edx, %eax
	roll	$16, %eax
.L213:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE42:
	.size	inner_hash, .-inner_hash
	.globl	LstringInt
	.type	LstringInt, @function
LstringInt:
.LFB43:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	leaq	-12(%rbp), %rdx
	movq	-24(%rbp), %rax
	leaq	.LC38(%rip), %rcx
	movq	%rcx, %rsi
	movq	%rax, %rdi
	movl	$0, %eax
	call	__isoc23_sscanf@PLT
	movl	-12(%rbp), %eax
	cltq
	addq	%rax, %rax
	orq	$1, %rax
	movq	-8(%rbp), %rdx
	subq	%fs:40, %rdx
	je	.L228
	call	__stack_chk_fail@PLT
.L228:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE43:
	.size	LstringInt, .-LstringInt
	.globl	Lhash
	.type	Lhash, @function
Lhash:
.LFB44:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	movq	%rax, %rdx
	movl	$0, %esi
	movl	$0, %edi
	call	inner_hash
	addl	%eax, %eax
	andl	$8388606, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE44:
	.size	Lhash, .-Lhash
	.globl	LflatCompare
	.type	LflatCompare, @function
LflatCompare:
.LFB45:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L232
	movq	-16(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L233
	movq	-8(%rbp), %rax
	sarq	%rax
	movq	%rax, %rdx
	movq	-16(%rbp), %rax
	sarq	%rax
	subq	%rax, %rdx
	movl	%edx, %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L234
.L233:
	movl	$-1, %eax
	jmp	.L234
.L232:
	movq	-8(%rbp), %rax
	subq	-16(%rbp), %rax
	addl	%eax, %eax
	orl	$1, %eax
.L234:
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE45:
	.size	LflatCompare, .-LflatCompare
	.section	.rodata
	.align 8
.LC69:
	.string	"invalid data_header %d in compare *****\n"
	.text
	.globl	Lcompare
	.type	Lcompare, @function
Lcompare:
.LFB46:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$80, %rsp
	movq	%rdi, -72(%rbp)
	movq	%rsi, -80(%rbp)
	movq	-72(%rbp), %rax
	cmpq	-80(%rbp), %rax
	jne	.L236
	movl	$1, %eax
	jmp	.L237
.L236:
	movq	-72(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L238
	movq	-80(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L239
	movq	-72(%rbp), %rax
	sarq	%rax
	movq	%rax, %rdx
	movq	-80(%rbp), %rax
	sarq	%rax
	subq	%rax, %rdx
	movl	%edx, %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L237
.L239:
	movl	$-1, %eax
	jmp	.L237
.L238:
	movq	-80(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L240
	movl	$3, %eax
	jmp	.L237
.L240:
	movq	-72(%rbp), %rax
	movq	%rax, %rdi
	call	is_valid_heap_pointer@PLT
	testb	%al, %al
	je	.L241
	movq	-80(%rbp), %rax
	movq	%rax, %rdi
	call	is_valid_heap_pointer@PLT
	testb	%al, %al
	je	.L242
	movq	-72(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -16(%rbp)
	movq	-80(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -8(%rbp)
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	movl	%eax, -44(%rbp)
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	movl	%eax, -40(%rbp)
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, -36(%rbp)
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, -32(%rbp)
	movl	$0, -48(%rbp)
	movl	-44(%rbp), %eax
	cmpl	-40(%rbp), %eax
	je	.L243
	movl	-44(%rbp), %eax
	subl	-40(%rbp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L237
.L243:
	cmpl	$7, -44(%rbp)
	je	.L244
	cmpl	$7, -44(%rbp)
	jg	.L245
	cmpl	$5, -44(%rbp)
	je	.L246
	cmpl	$5, -44(%rbp)
	jg	.L245
	cmpl	$1, -44(%rbp)
	je	.L247
	cmpl	$3, -44(%rbp)
	je	.L248
	jmp	.L245
.L247:
	movq	-8(%rbp), %rax
	leaq	16(%rax), %rdx
	movq	-16(%rbp), %rax
	addq	$16, %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	strcmp@PLT
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L237
.L244:
	movq	-16(%rbp), %rax
	addq	$16, %rax
	movq	(%rax), %rdx
	movq	-8(%rbp), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	cmpq	%rax, %rdx
	je	.L249
	movq	-16(%rbp), %rax
	addq	$16, %rax
	movq	(%rax), %rdx
	movq	-8(%rbp), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	subq	%rax, %rdx
	movl	%edx, %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L237
.L249:
	movl	-36(%rbp), %eax
	cmpl	-32(%rbp), %eax
	je	.L250
	movl	-36(%rbp), %eax
	subl	-32(%rbp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L237
.L250:
	movl	$1, -52(%rbp)
	jmp	.L251
.L248:
	movl	-36(%rbp), %eax
	cmpl	-32(%rbp), %eax
	je	.L252
	movl	-36(%rbp), %eax
	subl	-32(%rbp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L237
.L252:
	movl	$0, -52(%rbp)
	jmp	.L251
.L246:
	movq	-72(%rbp), %rax
	subq	$12, %rax
	movl	16(%rax), %eax
	movl	%eax, -28(%rbp)
	movq	-80(%rbp), %rax
	subq	$12, %rax
	movl	16(%rax), %eax
	movl	%eax, -24(%rbp)
	movl	-28(%rbp), %eax
	cmpl	-24(%rbp), %eax
	je	.L253
	movl	-28(%rbp), %eax
	subl	-24(%rbp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L237
.L253:
	movl	-36(%rbp), %eax
	cmpl	-32(%rbp), %eax
	je	.L254
	movl	-36(%rbp), %eax
	subl	-32(%rbp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L237
.L254:
	movl	$0, -52(%rbp)
	movl	$1, -48(%rbp)
	jmp	.L251
.L245:
	movl	-44(%rbp), %eax
	movl	%eax, %esi
	leaq	.LC69(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L251:
	jmp	.L255
.L257:
	movq	-8(%rbp), %rax
	leaq	16(%rax), %rcx
	movl	-52(%rbp), %edx
	movl	-48(%rbp), %eax
	addl	%edx, %eax
	cltq
	salq	$3, %rax
	addq	%rcx, %rax
	movq	(%rax), %rdx
	movq	-16(%rbp), %rax
	leaq	16(%rax), %rsi
	movl	-52(%rbp), %ecx
	movl	-48(%rbp), %eax
	addl	%ecx, %eax
	cltq
	salq	$3, %rax
	addq	%rsi, %rax
	movq	(%rax), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	Lcompare
	movl	%eax, -20(%rbp)
	cmpl	$1, -20(%rbp)
	je	.L256
	movl	-20(%rbp), %eax
	jmp	.L237
.L256:
	addl	$1, -52(%rbp)
.L255:
	movl	-52(%rbp), %eax
	cmpl	-36(%rbp), %eax
	jl	.L257
	movl	$1, %eax
	jmp	.L237
.L242:
	movl	$-1, %eax
	jmp	.L237
.L241:
	movq	-80(%rbp), %rax
	movq	%rax, %rdi
	call	is_valid_heap_pointer@PLT
	testb	%al, %al
	je	.L258
	movl	$3, %eax
	jmp	.L237
.L258:
	movq	-72(%rbp), %rax
	subq	-80(%rbp), %rax
	addl	%eax, %eax
	orl	$1, %eax
.L237:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE46:
	.size	Lcompare, .-Lcompare
	.section	.rodata
.LC70:
	.string	".elem:1"
.LC71:
	.string	".elem:2"
	.text
	.globl	Belem
	.type	Belem, @function
Belem:
.LFB47:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movl	%esi, -28(%rbp)
	movq	$1, -8(%rbp)
	movq	-24(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L260
	movq	-24(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L260
	leaq	.LC70(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC2(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L260:
	movl	-28(%rbp), %eax
	cltq
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L261
	leaq	.LC71(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L261:
	movq	-24(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -8(%rbp)
	sarl	-28(%rbp)
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L262
	cmpl	$5, %eax
	je	.L263
	jmp	.L266
.L262:
	movq	-8(%rbp), %rdx
	movl	-28(%rbp), %eax
	cltq
	movzbl	16(%rdx,%rax), %eax
	movsbq	%al, %rax
	addq	%rax, %rax
	orq	$1, %rax
	jmp	.L265
.L263:
	movq	-8(%rbp), %rax
	leaq	16(%rax), %rdx
	movl	-28(%rbp), %eax
	cltq
	addq	$1, %rax
	salq	$2, %rax
	addq	%rdx, %rax
	movl	(%rax), %eax
	cltq
	jmp	.L265
.L266:
	movq	-8(%rbp), %rax
	leaq	16(%rax), %rdx
	movl	-28(%rbp), %eax
	cltq
	salq	$2, %rax
	addq	%rdx, %rax
	movl	(%rax), %eax
	cltq
.L265:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE47:
	.size	Belem, .-Belem
	.section	.rodata
.LC72:
	.string	"makeArray:1"
	.text
	.globl	LmakeArray
	.type	LmakeArray, @function
LmakeArray:
.LFB48:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movl	%edi, -36(%rbp)
	movl	-36(%rbp), %eax
	cltq
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L268
	leaq	.LC72(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L268:
	movb	$0, -21(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -21(%rbp)
	cmpb	$0, -21(%rbp)
	je	.L269
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L269:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L270
	leaq	__PRETTY_FUNCTION__.11(%rip), %rax
	movq	%rax, %rcx
	movl	$697, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L270:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L271
	leaq	__PRETTY_FUNCTION__.11(%rip), %rax
	movq	%rax, %rcx
	movl	$697, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L271:
	movl	-36(%rbp), %eax
	sarl	%eax
	movl	%eax, -20(%rbp)
	movl	-20(%rbp), %eax
	movl	%eax, %edi
	call	alloc_array@PLT
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	addq	$16, %rax
	movq	%rax, -16(%rbp)
	jmp	.L272
.L273:
	movq	-16(%rbp), %rax
	leaq	4(%rax), %rdx
	movq	%rdx, -16(%rbp)
	movl	$1, (%rax)
.L272:
	movl	-20(%rbp), %eax
	leal	-1(%rax), %edx
	movl	%edx, -20(%rbp)
	testl	%eax, %eax
	jne	.L273
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L274
	leaq	__PRETTY_FUNCTION__.11(%rip), %rax
	movq	%rax, %rcx
	movl	$705, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L274:
	cmpb	$0, -21(%rbp)
	je	.L275
	movq	$0, __gc_stack_top(%rip)
.L275:
	movq	-8(%rbp), %rax
	addq	$16, %rax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE48:
	.size	LmakeArray, .-LmakeArray
	.section	.rodata
.LC73:
	.string	"makeString"
	.text
	.globl	LmakeString
	.type	LmakeString, @function
LmakeString:
.LFB49:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movl	%edi, -20(%rbp)
	movl	-20(%rbp), %eax
	sarl	%eax
	movl	%eax, -12(%rbp)
	movl	-20(%rbp), %eax
	cltq
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L278
	leaq	.LC73(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L278:
	movb	$0, -13(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -13(%rbp)
	cmpb	$0, -13(%rbp)
	je	.L279
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L279:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L280
	leaq	__PRETTY_FUNCTION__.10(%rip), %rax
	movq	%rax, %rcx
	movl	$716, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L280:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L281
	leaq	__PRETTY_FUNCTION__.10(%rip), %rax
	movq	%rax, %rcx
	movl	$716, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L281:
	movl	-12(%rbp), %eax
	movl	%eax, %edi
	call	alloc_string@PLT
	movq	%rax, -8(%rbp)
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L282
	leaq	__PRETTY_FUNCTION__.10(%rip), %rax
	movq	%rax, %rcx
	movl	$720, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L282:
	cmpb	$0, -13(%rbp)
	je	.L283
	movq	$0, __gc_stack_top(%rip)
.L283:
	movq	-8(%rbp), %rax
	addq	$16, %rax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE49:
	.size	LmakeString, .-LmakeString
	.globl	Bstring
	.type	Bstring, @function
Bstring:
.LFB50:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	strlen@PLT
	movl	%eax, -12(%rbp)
	movq	$0, -8(%rbp)
	movb	$0, -13(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -13(%rbp)
	cmpb	$0, -13(%rbp)
	je	.L286
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L286:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L287
	leaq	__PRETTY_FUNCTION__.9(%rip), %rax
	movq	%rax, %rcx
	movl	$729, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L287:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L288
	leaq	__PRETTY_FUNCTION__.9(%rip), %rax
	movq	%rax, %rcx
	movl	$729, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L288:
	leaq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	movl	-12(%rbp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	movl	%eax, %edi
	call	LmakeString
	movq	%rax, -8(%rbp)
	leaq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	movl	-12(%rbp), %eax
	addl	$1, %eax
	movslq	%eax, %rdx
	movq	-24(%rbp), %rax
	movq	-8(%rbp), %rcx
	subq	$12, %rcx
	addq	$16, %rcx
	movq	%rax, %rsi
	movq	%rcx, %rdi
	call	strncpy@PLT
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L289
	leaq	__PRETTY_FUNCTION__.9(%rip), %rax
	movq	%rax, %rcx
	movl	$736, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L289:
	cmpb	$0, -13(%rbp)
	je	.L290
	movq	$0, __gc_stack_top(%rip)
.L290:
	movq	-8(%rbp), %rax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE50:
	.size	Bstring, .-Bstring
	.globl	Lstringcat
	.type	Lstringcat, @function
Lstringcat:
.LFB51:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movb	$0, -9(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -9(%rbp)
	cmpb	$0, -9(%rbp)
	je	.L293
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L293:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L294
	leaq	__PRETTY_FUNCTION__.8(%rip), %rax
	movq	%rax, %rcx
	movl	$746, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L294:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L295
	leaq	__PRETTY_FUNCTION__.8(%rip), %rax
	movq	%rax, %rcx
	movl	$746, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L295:
	movl	$0, %eax
	call	createStringBuf
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	stringcat
	leaq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	movq	stringBuf(%rip), %rax
	movq	%rax, %rdi
	call	Bstring
	movq	%rax, -8(%rbp)
	leaq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	movl	$0, %eax
	call	deleteStringBuf
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L296
	leaq	__PRETTY_FUNCTION__.8(%rip), %rax
	movq	%rax, %rcx
	movl	$757, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L296:
	cmpb	$0, -9(%rbp)
	je	.L297
	movq	$0, __gc_stack_top(%rip)
.L297:
	movq	-8(%rbp), %rax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE51:
	.size	Lstringcat, .-Lstringcat
	.globl	Lstring
	.type	Lstring, @function
Lstring:
.LFB52:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movq	$1, -8(%rbp)
	movb	$0, -9(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -9(%rbp)
	cmpb	$0, -9(%rbp)
	je	.L300
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L300:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L301
	leaq	__PRETTY_FUNCTION__.7(%rip), %rax
	movq	%rax, %rcx
	movl	$765, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L301:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L302
	leaq	__PRETTY_FUNCTION__.7(%rip), %rax
	movq	%rax, %rcx
	movl	$765, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L302:
	movl	$0, %eax
	call	createStringBuf
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	printValue
	leaq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	movq	stringBuf(%rip), %rax
	movq	%rax, %rdi
	call	Bstring
	movq	%rax, -8(%rbp)
	leaq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	movl	$0, %eax
	call	deleteStringBuf
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L303
	leaq	__PRETTY_FUNCTION__.7(%rip), %rax
	movq	%rax, %rcx
	movl	$776, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L303:
	cmpb	$0, -9(%rbp)
	je	.L304
	movq	$0, __gc_stack_top(%rip)
.L304:
	movq	-8(%rbp), %rax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE52:
	.size	Lstring, .-Lstring
	.globl	Bclosure
	.type	Bclosure, @function
Bclosure:
.LFB53:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$256, %rsp
	movl	%edi, -244(%rbp)
	movq	%rsi, -256(%rbp)
	movq	%rdx, -160(%rbp)
	movq	%rcx, -152(%rbp)
	movq	%r8, -144(%rbp)
	movq	%r9, -136(%rbp)
	testb	%al, %al
	je	.L307
	movaps	%xmm0, -128(%rbp)
	movaps	%xmm1, -112(%rbp)
	movaps	%xmm2, -96(%rbp)
	movaps	%xmm3, -80(%rbp)
	movaps	%xmm4, -64(%rbp)
	movaps	%xmm5, -48(%rbp)
	movaps	%xmm6, -32(%rbp)
	movaps	%xmm7, -16(%rbp)
.L307:
	movq	%fs:40, %rax
	movq	%rax, -184(%rbp)
	xorl	%eax, %eax
	movl	-244(%rbp), %eax
	sarl	%eax
	movl	%eax, -232(%rbp)
	movb	$0, -237(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -237(%rbp)
	cmpb	$0, -237(%rbp)
	je	.L308
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L308:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L309
	leaq	__PRETTY_FUNCTION__.6(%rip), %rax
	movq	%rax, %rcx
	movl	$789, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L309:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L310
	leaq	__PRETTY_FUNCTION__.6(%rip), %rax
	movq	%rax, %rcx
	movl	$789, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L310:
	movq	%rbp, %rax
	addq	$48, %rax
	movq	%rax, -216(%rbp)
	movl	$0, -236(%rbp)
	jmp	.L311
.L312:
	movq	-216(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	addl	$1, -236(%rbp)
	addq	$8, -216(%rbp)
.L311:
	movl	-236(%rbp), %eax
	cmpl	-232(%rbp), %eax
	jl	.L312
	movl	-232(%rbp), %eax
	addl	$1, %eax
	movl	%eax, %edi
	call	alloc_closure@PLT
	movq	%rax, -224(%rbp)
	leaq	-224(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	movq	-224(%rbp), %rax
	leaq	16(%rax), %rdx
	movq	-256(%rbp), %rax
	movq	%rax, (%rdx)
	movl	$16, -208(%rbp)
	movl	$48, -204(%rbp)
	leaq	16(%rbp), %rax
	movq	%rax, -200(%rbp)
	leaq	-176(%rbp), %rax
	movq	%rax, -192(%rbp)
	movl	$0, -236(%rbp)
	jmp	.L313
.L316:
	movl	-208(%rbp), %eax
	cmpl	$47, %eax
	ja	.L314
	movq	-192(%rbp), %rax
	movl	-208(%rbp), %edx
	movl	%edx, %edx
	addq	%rdx, %rax
	movl	-208(%rbp), %edx
	addl	$8, %edx
	movl	%edx, -208(%rbp)
	jmp	.L315
.L314:
	movq	-200(%rbp), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, -200(%rbp)
.L315:
	movl	(%rax), %eax
	movl	%eax, -228(%rbp)
	movq	-224(%rbp), %rax
	leaq	16(%rax), %rdx
	movl	-236(%rbp), %eax
	cltq
	addq	$1, %rax
	salq	$2, %rax
	addq	%rax, %rdx
	movl	-228(%rbp), %eax
	movl	%eax, (%rdx)
	addl	$1, -236(%rbp)
.L313:
	movl	-236(%rbp), %eax
	cmpl	-232(%rbp), %eax
	jl	.L316
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L317
	leaq	__PRETTY_FUNCTION__.6(%rip), %rax
	movq	%rax, %rcx
	movl	$807, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L317:
	cmpb	$0, -237(%rbp)
	je	.L318
	movq	$0, __gc_stack_top(%rip)
.L318:
	leaq	-224(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	subq	$8, -216(%rbp)
	movl	$0, -236(%rbp)
	jmp	.L319
.L320:
	movq	-216(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	addl	$1, -236(%rbp)
	subq	$8, -216(%rbp)
.L319:
	movl	-236(%rbp), %eax
	cmpl	-232(%rbp), %eax
	jl	.L320
	movq	-224(%rbp), %rax
	addq	$16, %rax
	movq	-184(%rbp), %rdx
	subq	%fs:40, %rdx
	je	.L322
	call	__stack_chk_fail@PLT
.L322:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE53:
	.size	Bclosure, .-Bclosure
	.globl	Barray
	.type	Barray, @function
Barray:
.LFB54:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$256, %rsp
	movl	%edi, -244(%rbp)
	movq	%rsi, -168(%rbp)
	movq	%rdx, -160(%rbp)
	movq	%rcx, -152(%rbp)
	movq	%r8, -144(%rbp)
	movq	%r9, -136(%rbp)
	testb	%al, %al
	je	.L324
	movaps	%xmm0, -128(%rbp)
	movaps	%xmm1, -112(%rbp)
	movaps	%xmm2, -96(%rbp)
	movaps	%xmm3, -80(%rbp)
	movaps	%xmm4, -64(%rbp)
	movaps	%xmm5, -48(%rbp)
	movaps	%xmm6, -32(%rbp)
	movaps	%xmm7, -16(%rbp)
.L324:
	movq	%fs:40, %rax
	movq	%rax, -184(%rbp)
	xorl	%eax, %eax
	movl	-244(%rbp), %eax
	sarl	%eax
	movl	%eax, -224(%rbp)
	movb	$0, -229(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -229(%rbp)
	cmpb	$0, -229(%rbp)
	je	.L325
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L325:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L326
	leaq	__PRETTY_FUNCTION__.5(%rip), %rax
	movq	%rax, %rcx
	movl	$821, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L326:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L327
	leaq	__PRETTY_FUNCTION__.5(%rip), %rax
	movq	%rax, %rcx
	movl	$821, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L327:
	movl	-224(%rbp), %eax
	movl	%eax, %edi
	call	alloc_array@PLT
	movq	%rax, -216(%rbp)
	movl	$8, -208(%rbp)
	movl	$48, -204(%rbp)
	leaq	16(%rbp), %rax
	movq	%rax, -200(%rbp)
	leaq	-176(%rbp), %rax
	movq	%rax, -192(%rbp)
	movl	$0, -228(%rbp)
	jmp	.L328
.L331:
	movl	-208(%rbp), %eax
	cmpl	$47, %eax
	ja	.L329
	movq	-192(%rbp), %rax
	movl	-208(%rbp), %edx
	movl	%edx, %edx
	addq	%rdx, %rax
	movl	-208(%rbp), %edx
	addl	$8, %edx
	movl	%edx, -208(%rbp)
	jmp	.L330
.L329:
	movq	-200(%rbp), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, -200(%rbp)
.L330:
	movl	(%rax), %eax
	movl	%eax, -220(%rbp)
	movq	-216(%rbp), %rax
	leaq	16(%rax), %rdx
	movl	-228(%rbp), %eax
	cltq
	salq	$2, %rax
	addq	%rax, %rdx
	movl	-220(%rbp), %eax
	movl	%eax, (%rdx)
	addl	$1, -228(%rbp)
.L328:
	movl	-228(%rbp), %eax
	cmpl	-224(%rbp), %eax
	jl	.L331
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L332
	leaq	__PRETTY_FUNCTION__.5(%rip), %rax
	movq	%rax, %rcx
	movl	$834, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L332:
	cmpb	$0, -229(%rbp)
	je	.L333
	movq	$0, __gc_stack_top(%rip)
.L333:
	movq	-216(%rbp), %rax
	addq	$16, %rax
	movq	-184(%rbp), %rdx
	subq	%fs:40, %rdx
	je	.L335
	call	__stack_chk_fail@PLT
.L335:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE54:
	.size	Barray, .-Barray
	.globl	Bsexp
	.type	Bsexp, @function
Bsexp:
.LFB55:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$272, %rsp
	movl	%edi, -260(%rbp)
	movq	%rsi, -168(%rbp)
	movq	%rdx, -160(%rbp)
	movq	%rcx, -152(%rbp)
	movq	%r8, -144(%rbp)
	movq	%r9, -136(%rbp)
	testb	%al, %al
	je	.L337
	movaps	%xmm0, -128(%rbp)
	movaps	%xmm1, -112(%rbp)
	movaps	%xmm2, -96(%rbp)
	movaps	%xmm3, -80(%rbp)
	movaps	%xmm4, -64(%rbp)
	movaps	%xmm5, -48(%rbp)
	movaps	%xmm6, -32(%rbp)
	movaps	%xmm7, -16(%rbp)
.L337:
	movq	%fs:40, %rax
	movq	%rax, -184(%rbp)
	xorl	%eax, %eax
	movl	-260(%rbp), %eax
	sarl	%eax
	movl	%eax, -236(%rbp)
	movb	$0, -241(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -241(%rbp)
	cmpb	$0, -241(%rbp)
	je	.L338
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L338:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L339
	leaq	__PRETTY_FUNCTION__.4(%rip), %rax
	movq	%rax, %rcx
	movl	$850, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L339:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L340
	leaq	__PRETTY_FUNCTION__.4(%rip), %rax
	movq	%rax, %rcx
	movl	$850, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L340:
	movl	-236(%rbp), %eax
	subl	$1, %eax
	movl	%eax, -232(%rbp)
	movl	-232(%rbp), %eax
	movl	%eax, %edi
	call	alloc_sexp@PLT
	movq	%rax, -224(%rbp)
	movq	-224(%rbp), %rax
	movl	$0, 16(%rax)
	movl	$8, -208(%rbp)
	movl	$48, -204(%rbp)
	leaq	16(%rbp), %rax
	movq	%rax, -200(%rbp)
	leaq	-176(%rbp), %rax
	movq	%rax, -192(%rbp)
	movl	$1, -240(%rbp)
	jmp	.L341
.L344:
	movl	-208(%rbp), %eax
	cmpl	$47, %eax
	ja	.L342
	movq	-192(%rbp), %rax
	movl	-208(%rbp), %edx
	movl	%edx, %edx
	addq	%rdx, %rax
	movl	-208(%rbp), %edx
	addl	$8, %edx
	movl	%edx, -208(%rbp)
	jmp	.L343
.L342:
	movq	-200(%rbp), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, -200(%rbp)
.L343:
	movl	(%rax), %eax
	movl	%eax, -228(%rbp)
	movl	-228(%rbp), %eax
	cltq
	movq	%rax, -216(%rbp)
	movq	-224(%rbp), %rax
	leaq	16(%rax), %rdx
	movl	-240(%rbp), %eax
	cltq
	salq	$2, %rax
	addq	%rax, %rdx
	movl	-228(%rbp), %eax
	movl	%eax, (%rdx)
	addl	$1, -240(%rbp)
.L341:
	movl	-240(%rbp), %eax
	cmpl	-236(%rbp), %eax
	jl	.L344
	movl	-208(%rbp), %eax
	cmpl	$47, %eax
	ja	.L345
	movq	-192(%rbp), %rax
	movl	-208(%rbp), %edx
	movl	%edx, %edx
	addq	%rdx, %rax
	movl	-208(%rbp), %edx
	addl	$8, %edx
	movl	%edx, -208(%rbp)
	jmp	.L346
.L345:
	movq	-200(%rbp), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, -200(%rbp)
.L346:
	movl	(%rax), %eax
	sarl	%eax
	movl	%eax, %edx
	movq	-224(%rbp), %rax
	movl	%edx, 16(%rax)
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L347
	leaq	__PRETTY_FUNCTION__.4(%rip), %rax
	movq	%rax, %rcx
	movl	$868, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L347:
	cmpb	$0, -241(%rbp)
	je	.L348
	movq	$0, __gc_stack_top(%rip)
.L348:
	movq	-224(%rbp), %rax
	addq	$16, %rax
	movq	-184(%rbp), %rdx
	subq	%fs:40, %rdx
	je	.L350
	call	__stack_chk_fail@PLT
.L350:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE55:
	.size	Bsexp, .-Bsexp
	.globl	Btag
	.type	Btag, @function
Btag:
.LFB56:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -24(%rbp)
	movl	%esi, -28(%rbp)
	movl	%edx, -32(%rbp)
	movq	-24(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L352
	movl	$1, %eax
	jmp	.L353
.L352:
	movq	-24(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$5, %eax
	jne	.L354
	movq	-24(%rbp), %rax
	subq	$12, %rax
	movl	16(%rax), %edx
	movl	-28(%rbp), %eax
	sarl	%eax
	cmpl	%eax, %edx
	jne	.L354
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	-32(%rbp), %eax
	sarl	%eax
	cltq
	cmpq	%rax, %rdx
	jne	.L354
	movl	$1, %eax
	jmp	.L355
.L354:
	movl	$0, %eax
.L355:
	cltq
	addq	%rax, %rax
	orq	$1, %rax
.L353:
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE56:
	.size	Btag, .-Btag
	.globl	get_tag
	.type	get_tag, @function
get_tag:
.LFB57:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE57:
	.size	get_tag, .-get_tag
	.globl	get_len
	.type	get_len, @function
get_len:
.LFB58:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE58:
	.size	get_len, .-get_len
	.globl	Barray_patt
	.type	Barray_patt, @function
Barray_patt:
.LFB59:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movl	%esi, -28(%rbp)
	movq	-24(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L361
	movl	$1, %eax
	jmp	.L362
.L361:
	movq	-24(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	movq	%rax, %rdi
	call	get_tag
	cmpl	$3, %eax
	jne	.L363
	movq	-8(%rbp), %rax
	movq	%rax, %rdi
	call	get_len
	movl	-28(%rbp), %edx
	sarl	%edx
	cmpl	%edx, %eax
	jne	.L363
	movl	$1, %eax
	jmp	.L364
.L363:
	movl	$0, %eax
.L364:
	addl	%eax, %eax
	orl	$1, %eax
.L362:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE59:
	.size	Barray_patt, .-Barray_patt
	.section	.rodata
.LC74:
	.string	".string_patt:2"
	.text
	.globl	Bstring_patt
	.type	Bstring_patt, @function
Bstring_patt:
.LFB60:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movq	%rsi, -32(%rbp)
	movq	$1, -16(%rbp)
	movq	$1, -8(%rbp)
	movq	-32(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L366
	movq	-32(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L366
	leaq	.LC74(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L366:
	movq	-24(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L367
	movl	$1, %eax
	jmp	.L368
.L367:
	movq	-24(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -16(%rbp)
	movq	-32(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -8(%rbp)
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L369
	movl	$1, %eax
	jmp	.L368
.L369:
	movq	-8(%rbp), %rax
	leaq	16(%rax), %rdx
	movq	-16(%rbp), %rax
	addq	$16, %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L370
	movl	$3, %eax
	jmp	.L368
.L370:
	movl	$1, %eax
.L368:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE60:
	.size	Bstring_patt, .-Bstring_patt
	.globl	Bclosure_tag_patt
	.type	Bclosure_tag_patt, @function
Bclosure_tag_patt:
.LFB61:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L373
	movl	$1, %eax
	jmp	.L374
.L373:
	movq	-8(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$7, %eax
	jne	.L375
	movl	$3, %eax
	jmp	.L374
.L375:
	movl	$1, %eax
.L374:
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE61:
	.size	Bclosure_tag_patt, .-Bclosure_tag_patt
	.globl	Bboxed_patt
	.type	Bboxed_patt, @function
Bboxed_patt:
.LFB62:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L378
	movl	$3, %eax
	jmp	.L380
.L378:
	movl	$1, %eax
.L380:
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE62:
	.size	Bboxed_patt, .-Bboxed_patt
	.globl	Bunboxed_patt
	.type	Bunboxed_patt, @function
Bunboxed_patt:
.LFB63:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	addl	%eax, %eax
	andl	$2, %eax
	orl	$1, %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE63:
	.size	Bunboxed_patt, .-Bunboxed_patt
	.globl	Barray_tag_patt
	.type	Barray_tag_patt, @function
Barray_tag_patt:
.LFB64:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L384
	movl	$1, %eax
	jmp	.L385
.L384:
	movq	-8(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$3, %eax
	jne	.L386
	movl	$3, %eax
	jmp	.L385
.L386:
	movl	$1, %eax
.L385:
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE64:
	.size	Barray_tag_patt, .-Barray_tag_patt
	.globl	Bstring_tag_patt
	.type	Bstring_tag_patt, @function
Bstring_tag_patt:
.LFB65:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L389
	movl	$1, %eax
	jmp	.L390
.L389:
	movq	-8(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	jne	.L391
	movl	$3, %eax
	jmp	.L390
.L391:
	movl	$1, %eax
.L390:
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE65:
	.size	Bstring_tag_patt, .-Bstring_tag_patt
	.globl	Bsexp_tag_patt
	.type	Bsexp_tag_patt, @function
Bsexp_tag_patt:
.LFB66:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L394
	movl	$1, %eax
	jmp	.L395
.L394:
	movq	-8(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$5, %eax
	jne	.L396
	movl	$3, %eax
	jmp	.L395
.L396:
	movl	$1, %eax
.L395:
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE66:
	.size	Bsexp_tag_patt, .-Bsexp_tag_patt
	.section	.rodata
.LC75:
	.string	".sta:3"
	.text
	.globl	Bsta
	.type	Bsta, @function
Bsta:
.LFB67:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	%rdi, -24(%rbp)
	movl	%esi, -28(%rbp)
	movq	%rdx, -40(%rbp)
	movl	-28(%rbp), %eax
	cltq
	andl	$1, %eax
	testq	%rax, %rax
	je	.L399
	movq	-40(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L400
	leaq	.LC75(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC2(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L400:
	movq	-40(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L401
	cmpl	$5, %eax
	je	.L402
	jmp	.L407
.L401:
	movq	-24(%rbp), %rax
	sarq	%rax
	movq	%rax, %rcx
	movl	-28(%rbp), %eax
	sarl	%eax
	movslq	%eax, %rdx
	movq	-40(%rbp), %rax
	addq	%rdx, %rax
	movl	%ecx, %edx
	movb	%dl, (%rax)
	jmp	.L405
.L402:
	movq	-24(%rbp), %rcx
	movl	-28(%rbp), %eax
	sarl	%eax
	cltq
	addq	$1, %rax
	leaq	0(,%rax,4), %rdx
	movq	-40(%rbp), %rax
	addq	%rdx, %rax
	movl	%ecx, %edx
	movl	%edx, (%rax)
	jmp	.L405
.L407:
	movq	-24(%rbp), %rcx
	movl	-28(%rbp), %eax
	sarl	%eax
	cltq
	leaq	0(,%rax,4), %rdx
	movq	-40(%rbp), %rax
	addq	%rdx, %rax
	movl	%ecx, %edx
	movl	%edx, (%rax)
	jmp	.L405
.L399:
	movq	-40(%rbp), %rax
	movq	-24(%rbp), %rdx
	movq	%rdx, (%rax)
.L405:
	movq	-24(%rbp), %rax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE67:
	.size	Bsta, .-Bsta
	.type	fix_unboxed, @function
fix_unboxed:
.LFB68:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -40(%rbp)
	movq	%rsi, -48(%rbp)
	movq	-48(%rbp), %rax
	movq	%rax, -16(%rbp)
	movl	$0, -20(%rbp)
	jmp	.L409
.L412:
	movq	-40(%rbp), %rax
	movzbl	(%rax), %eax
	cmpb	$37, %al
	jne	.L410
	movl	-20(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	movq	-16(%rbp), %rax
	addq	%rdx, %rax
	movq	(%rax), %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L411
	movq	-8(%rbp), %rax
	sarq	%rax
	movq	%rax, %rcx
	movl	-20(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	movq	-16(%rbp), %rax
	addq	%rdx, %rax
	movq	%rcx, %rdx
	movq	%rdx, (%rax)
.L411:
	addl	$1, -20(%rbp)
.L410:
	addq	$1, -40(%rbp)
.L409:
	movq	-40(%rbp), %rax
	movzbl	(%rax), %eax
	testb	%al, %al
	jne	.L412
	nop
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE68:
	.size	fix_unboxed, .-fix_unboxed
	.globl	Lfailure
	.type	Lfailure, @function
Lfailure:
.LFB69:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$224, %rsp
	movq	%rdi, -216(%rbp)
	movq	%rsi, -168(%rbp)
	movq	%rdx, -160(%rbp)
	movq	%rcx, -152(%rbp)
	movq	%r8, -144(%rbp)
	movq	%r9, -136(%rbp)
	testb	%al, %al
	je	.L414
	movaps	%xmm0, -128(%rbp)
	movaps	%xmm1, -112(%rbp)
	movaps	%xmm2, -96(%rbp)
	movaps	%xmm3, -80(%rbp)
	movaps	%xmm4, -64(%rbp)
	movaps	%xmm5, -48(%rbp)
	movaps	%xmm6, -32(%rbp)
	movaps	%xmm7, -16(%rbp)
.L414:
	movq	%fs:40, %rax
	movq	%rax, -184(%rbp)
	xorl	%eax, %eax
	movl	$8, -208(%rbp)
	movl	$48, -204(%rbp)
	leaq	16(%rbp), %rax
	movq	%rax, -200(%rbp)
	leaq	-176(%rbp), %rax
	movq	%rax, -192(%rbp)
	leaq	-208(%rbp), %rdx
	movq	-216(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	fix_unboxed
	leaq	-208(%rbp), %rdx
	movq	-216(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	vfailure
	nop
	movq	-184(%rbp), %rax
	subq	%fs:40, %rax
	je	.L415
	call	__stack_chk_fail@PLT
.L415:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE69:
	.size	Lfailure, .-Lfailure
	.section	.rodata
	.align 8
.LC76:
	.string	"match failure at %s:%d:%d, value '%s'\n"
	.text
	.globl	Bmatch_failure
	.type	Bmatch_failure, @function
Bmatch_failure:
.LFB70:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movl	%edx, -20(%rbp)
	movl	%ecx, -24(%rbp)
	movl	$0, %eax
	call	createStringBuf
	movq	-8(%rbp), %rax
	movq	%rax, %rdi
	call	printValue
	movq	stringBuf(%rip), %rsi
	movl	-24(%rbp), %eax
	sarl	%eax
	movslq	%eax, %rcx
	movl	-20(%rbp), %eax
	sarl	%eax
	movslq	%eax, %rdx
	movq	-16(%rbp), %rax
	movq	%rsi, %r8
	movq	%rax, %rsi
	leaq	.LC76(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE70:
	.size	Bmatch_failure, .-Bmatch_failure
	.section	.rodata
.LC77:
	.string	"++:1"
.LC78:
	.string	"++:2"
	.text
	.globl	Li__Infix_4343
	.type	Li__Infix_4343, @function
Li__Infix_4343:
.LFB71:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	%rdi, -40(%rbp)
	movq	%rsi, -48(%rbp)
	movq	$1, -24(%rbp)
	movq	$1, -16(%rbp)
	movq	$1, -8(%rbp)
	movq	-40(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L418
	movq	-40(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L418
	leaq	.LC77(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L418:
	movq	-48(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L419
	movq	-48(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L419
	leaq	.LC78(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L419:
	movq	-40(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -24(%rbp)
	movq	-48(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -16(%rbp)
	movb	$0, -25(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -25(%rbp)
	cmpb	$0, -25(%rbp)
	je	.L420
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L420:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L421
	leaq	__PRETTY_FUNCTION__.3(%rip), %rax
	movq	%rax, %rcx
	movl	$1011, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L421:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L422
	leaq	__PRETTY_FUNCTION__.3(%rip), %rax
	movq	%rax, %rcx
	movl	$1011, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L422:
	leaq	-40(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	leaq	-48(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	movq	-24(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	addl	%edx, %eax
	movl	%eax, %edi
	call	alloc_string@PLT
	movq	%rax, -8(%rbp)
	leaq	-48(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	leaq	-40(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	movq	-40(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -24(%rbp)
	movq	-48(%rbp), %rax
	subq	$12, %rax
	movq	%rax, -16(%rbp)
	movq	-24(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movq	-24(%rbp), %rax
	leaq	16(%rax), %rcx
	movq	-8(%rbp), %rax
	addq	$16, %rax
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	strncpy@PLT
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, %esi
	movq	-16(%rbp), %rax
	leaq	16(%rax), %rcx
	movq	-8(%rbp), %rax
	leaq	16(%rax), %rdx
	movq	-24(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, %eax
	addq	%rdx, %rax
	movq	%rsi, %rdx
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	strncpy@PLT
	movq	-24(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movq	-16(%rbp), %rax
	movl	(%rax), %eax
	shrl	$3, %eax
	addl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	%edx, %edx
	movb	$0, 16(%rax,%rdx)
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L423
	leaq	__PRETTY_FUNCTION__.3(%rip), %rax
	movq	%rax, %rcx
	movl	$1026, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L423:
	cmpb	$0, -25(%rbp)
	je	.L424
	movq	$0, __gc_stack_top(%rip)
.L424:
	movq	-8(%rbp), %rax
	addq	$16, %rax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE71:
	.size	Li__Infix_4343, .-Li__Infix_4343
	.section	.rodata
.LC79:
	.string	"sprintf:1"
	.text
	.globl	Lsprintf
	.type	Lsprintf, @function
Lsprintf:
.LFB72:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$240, %rsp
	movq	%rdi, -232(%rbp)
	movq	%rsi, -168(%rbp)
	movq	%rdx, -160(%rbp)
	movq	%rcx, -152(%rbp)
	movq	%r8, -144(%rbp)
	movq	%r9, -136(%rbp)
	testb	%al, %al
	je	.L427
	movaps	%xmm0, -128(%rbp)
	movaps	%xmm1, -112(%rbp)
	movaps	%xmm2, -96(%rbp)
	movaps	%xmm3, -80(%rbp)
	movaps	%xmm4, -64(%rbp)
	movaps	%xmm5, -48(%rbp)
	movaps	%xmm6, -32(%rbp)
	movaps	%xmm7, -16(%rbp)
.L427:
	movq	%fs:40, %rax
	movq	%rax, -184(%rbp)
	xorl	%eax, %eax
	movq	-232(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L428
	movq	-232(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L428
	leaq	.LC79(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L428:
	movl	$8, -208(%rbp)
	movl	$48, -204(%rbp)
	leaq	16(%rbp), %rax
	movq	%rax, -200(%rbp)
	leaq	-176(%rbp), %rax
	movq	%rax, -192(%rbp)
	movq	-232(%rbp), %rax
	leaq	-208(%rbp), %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	fix_unboxed
	movl	$0, %eax
	call	createStringBuf
	movq	-232(%rbp), %rax
	leaq	-208(%rbp), %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	vprintStringBuf
	movb	$0, -217(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -217(%rbp)
	cmpb	$0, -217(%rbp)
	je	.L429
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L429:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L430
	leaq	__PRETTY_FUNCTION__.2(%rip), %rax
	movq	%rax, %rcx
	movl	$1044, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L430:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L431
	leaq	__PRETTY_FUNCTION__.2(%rip), %rax
	movq	%rax, %rcx
	movl	$1044, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L431:
	leaq	-232(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	movq	stringBuf(%rip), %rax
	movq	%rax, %rdi
	call	Bstring
	movq	%rax, -216(%rbp)
	leaq	-232(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L432
	leaq	__PRETTY_FUNCTION__.2(%rip), %rax
	movq	%rax, %rcx
	movl	$1050, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L432:
	cmpb	$0, -217(%rbp)
	je	.L433
	movq	$0, __gc_stack_top(%rip)
.L433:
	movl	$0, %eax
	call	deleteStringBuf
	movq	-216(%rbp), %rax
	movq	-184(%rbp), %rdx
	subq	%fs:40, %rdx
	je	.L435
	call	__stack_chk_fail@PLT
.L435:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE72:
	.size	Lsprintf, .-Lsprintf
	.globl	LgetEnv
	.type	LgetEnv, @function
LgetEnv:
.LFB73:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	%rdi, -40(%rbp)
	movq	-40(%rbp), %rax
	movq	%rax, %rdi
	call	getenv@PLT
	movq	%rax, -16(%rbp)
	cmpq	$0, -16(%rbp)
	jne	.L437
	movl	$1, %eax
	jmp	.L438
.L437:
	movb	$0, -17(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -17(%rbp)
	cmpb	$0, -17(%rbp)
	je	.L439
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L439:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L440
	leaq	__PRETTY_FUNCTION__.1(%rip), %rax
	movq	%rax, %rcx
	movl	$1063, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L440:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L441
	leaq	__PRETTY_FUNCTION__.1(%rip), %rax
	movq	%rax, %rcx
	movl	$1063, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L441:
	movq	-16(%rbp), %rax
	movq	%rax, %rdi
	call	Bstring
	movq	%rax, -8(%rbp)
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L442
	leaq	__PRETTY_FUNCTION__.1(%rip), %rax
	movq	%rax, %rcx
	movl	$1067, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L442:
	cmpb	$0, -17(%rbp)
	je	.L443
	movq	$0, __gc_stack_top(%rip)
.L443:
	movq	-8(%rbp), %rax
.L438:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE73:
	.size	LgetEnv, .-LgetEnv
	.globl	Lsystem
	.type	Lsystem, @function
Lsystem:
.LFB74:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	movq	%rax, %rdi
	call	system@PLT
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE74:
	.size	Lsystem, .-Lsystem
	.section	.rodata
.LC80:
	.string	"fprintf:1"
.LC81:
	.string	"fprintf:2"
.LC82:
	.string	"fprintf (...): %s\n"
	.text
	.globl	Lfprintf
	.type	Lfprintf, @function
Lfprintf:
.LFB75:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$224, %rsp
	movq	%rdi, -216(%rbp)
	movq	%rsi, -224(%rbp)
	movq	%rdx, -160(%rbp)
	movq	%rcx, -152(%rbp)
	movq	%r8, -144(%rbp)
	movq	%r9, -136(%rbp)
	testb	%al, %al
	je	.L447
	movaps	%xmm0, -128(%rbp)
	movaps	%xmm1, -112(%rbp)
	movaps	%xmm2, -96(%rbp)
	movaps	%xmm3, -80(%rbp)
	movaps	%xmm4, -64(%rbp)
	movaps	%xmm5, -48(%rbp)
	movaps	%xmm6, -32(%rbp)
	movaps	%xmm7, -16(%rbp)
.L447:
	movq	%fs:40, %rax
	movq	%rax, -184(%rbp)
	xorl	%eax, %eax
	movq	-216(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L448
	leaq	.LC80(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC2(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L448:
	movq	-224(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L449
	movq	-224(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L449
	leaq	.LC81(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L449:
	movl	$16, -208(%rbp)
	movl	$48, -204(%rbp)
	leaq	16(%rbp), %rax
	movq	%rax, -200(%rbp)
	leaq	-176(%rbp), %rax
	movq	%rax, -192(%rbp)
	leaq	-208(%rbp), %rdx
	movq	-224(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	fix_unboxed
	leaq	-208(%rbp), %rdx
	movq	-224(%rbp), %rcx
	movq	-216(%rbp), %rax
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	vfprintf@PLT
	testl	%eax, %eax
	jns	.L452
	call	__errno_location@PLT
	movl	(%rax), %eax
	movl	%eax, %edi
	call	strerror@PLT
	movq	%rax, %rsi
	leaq	.LC82(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L452:
	nop
	movq	-184(%rbp), %rax
	subq	%fs:40, %rax
	je	.L451
	call	__stack_chk_fail@PLT
.L451:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE75:
	.size	Lfprintf, .-Lfprintf
	.section	.rodata
.LC83:
	.string	"printf:1"
	.text
	.globl	Lprintf
	.type	Lprintf, @function
Lprintf:
.LFB76:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$224, %rsp
	movq	%rdi, -216(%rbp)
	movq	%rsi, -168(%rbp)
	movq	%rdx, -160(%rbp)
	movq	%rcx, -152(%rbp)
	movq	%r8, -144(%rbp)
	movq	%r9, -136(%rbp)
	testb	%al, %al
	je	.L454
	movaps	%xmm0, -128(%rbp)
	movaps	%xmm1, -112(%rbp)
	movaps	%xmm2, -96(%rbp)
	movaps	%xmm3, -80(%rbp)
	movaps	%xmm4, -64(%rbp)
	movaps	%xmm5, -48(%rbp)
	movaps	%xmm6, -32(%rbp)
	movaps	%xmm7, -16(%rbp)
.L454:
	movq	%fs:40, %rax
	movq	%rax, -184(%rbp)
	xorl	%eax, %eax
	movq	-216(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L455
	movq	-216(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L455
	leaq	.LC83(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L455:
	movl	$8, -208(%rbp)
	movl	$48, -204(%rbp)
	leaq	16(%rbp), %rax
	movq	%rax, -200(%rbp)
	leaq	-176(%rbp), %rax
	movq	%rax, -192(%rbp)
	leaq	-208(%rbp), %rdx
	movq	-216(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	fix_unboxed
	leaq	-208(%rbp), %rdx
	movq	-216(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	vprintf@PLT
	testl	%eax, %eax
	jns	.L456
	call	__errno_location@PLT
	movl	(%rax), %eax
	movl	%eax, %edi
	call	strerror@PLT
	movq	%rax, %rsi
	leaq	.LC82(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L456:
	movq	stdout(%rip), %rax
	movq	%rax, %rdi
	call	fflush@PLT
	nop
	movq	-184(%rbp), %rax
	subq	%fs:40, %rax
	je	.L457
	call	__stack_chk_fail@PLT
.L457:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE76:
	.size	Lprintf, .-Lprintf
	.section	.rodata
.LC84:
	.string	"fopen:1"
.LC85:
	.string	"fopen:2"
	.align 8
.LC86:
	.string	"fopen (\"%s\", \"%s\"): %s, %s, %s\n"
	.text
	.globl	Lfopen
	.type	Lfopen, @function
Lfopen:
.LFB77:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movq	%rsi, -32(%rbp)
	movq	-24(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L459
	movq	-24(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L459
	leaq	.LC84(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L459:
	movq	-32(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L460
	movq	-32(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L460
	leaq	.LC85(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L460:
	movq	-32(%rbp), %rdx
	movq	-24(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	fopen@PLT
	movq	%rax, -8(%rbp)
	cmpq	$0, -8(%rbp)
	je	.L461
	movq	-8(%rbp), %rax
	jmp	.L458
.L461:
	call	__errno_location@PLT
	movl	(%rax), %eax
	movl	%eax, %edi
	call	strerror@PLT
	movq	%rax, %rcx
	movq	-32(%rbp), %rdx
	movq	-24(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC86(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L458:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE77:
	.size	Lfopen, .-Lfopen
	.section	.rodata
.LC87:
	.string	"fclose"
	.text
	.globl	Lfclose
	.type	Lfclose, @function
Lfclose:
.LFB78:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L464
	leaq	.LC87(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC2(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L464:
	movq	-8(%rbp), %rax
	movq	%rax, %rdi
	call	fclose@PLT
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE78:
	.size	Lfclose, .-Lfclose
	.section	.rodata
.LC88:
	.string	"%m[^\n]"
.LC89:
	.string	"readLine (): %s\n"
	.text
	.globl	LreadLine
	.type	LreadLine, @function
LreadLine:
.LFB79:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	leaq	-24(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC88(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	__isoc23_scanf@PLT
	cmpl	$1, %eax
	jne	.L466
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	Bstring
	movq	%rax, -16(%rbp)
	call	getchar@PLT
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	free@PLT
	movq	-16(%rbp), %rax
	jmp	.L469
.L466:
	call	__errno_location@PLT
	movl	(%rax), %eax
	testl	%eax, %eax
	je	.L468
	call	__errno_location@PLT
	movl	(%rax), %eax
	movl	%eax, %edi
	call	strerror@PLT
	movq	%rax, %rsi
	leaq	.LC89(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L468:
	movl	$1, %eax
.L469:
	movq	-8(%rbp), %rdx
	subq	%fs:40, %rdx
	je	.L470
	call	__stack_chk_fail@PLT
.L470:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE79:
	.size	LreadLine, .-LreadLine
	.section	.rodata
.LC90:
	.string	"fread"
.LC91:
	.string	"r"
.LC92:
	.string	"fread (\"%s\"): %s\n"
	.text
	.globl	Lfread
	.type	Lfread, @function
Lfread:
.LFB80:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	%rdi, -40(%rbp)
	movq	-40(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L472
	movq	-40(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L472
	leaq	.LC90(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L472:
	movq	-40(%rbp), %rax
	leaq	.LC91(%rip), %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	fopen@PLT
	movq	%rax, -24(%rbp)
	cmpq	$0, -24(%rbp)
	je	.L473
	movq	-24(%rbp), %rax
	movl	$2, %edx
	movl	$0, %esi
	movq	%rax, %rdi
	call	fseek@PLT
	testl	%eax, %eax
	js	.L473
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	ftell@PLT
	movq	%rax, -16(%rbp)
	movq	-16(%rbp), %rax
	addl	%eax, %eax
	orl	$1, %eax
	movl	%eax, %edi
	call	LmakeString
	movq	%rax, -8(%rbp)
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	rewind@PLT
	movq	-16(%rbp), %rdx
	movq	-24(%rbp), %rcx
	movq	-8(%rbp), %rax
	movl	$1, %esi
	movq	%rax, %rdi
	call	fread@PLT
	movq	%rax, %rdx
	movq	-16(%rbp), %rax
	cmpq	%rax, %rdx
	jne	.L473
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	fclose@PLT
	movq	-8(%rbp), %rax
	jmp	.L471
.L473:
	call	__errno_location@PLT
	movl	(%rax), %eax
	movl	%eax, %edi
	call	strerror@PLT
	movq	%rax, %rdx
	movq	-40(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC92(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L471:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE80:
	.size	Lfread, .-Lfread
	.section	.rodata
.LC93:
	.string	"fwrite:1"
.LC94:
	.string	"fwrite:2"
.LC95:
	.string	"w"
.LC96:
	.string	"fwrite (\"%s\"): %s\n"
	.text
	.globl	Lfwrite
	.type	Lfwrite, @function
Lfwrite:
.LFB81:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movq	%rsi, -32(%rbp)
	movq	-24(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L476
	movq	-24(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L476
	leaq	.LC93(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L476:
	movq	-32(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L477
	movq	-32(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L477
	leaq	.LC94(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L477:
	movq	-24(%rbp), %rax
	leaq	.LC95(%rip), %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	fopen@PLT
	movq	%rax, -8(%rbp)
	cmpq	$0, -8(%rbp)
	je	.L478
	movq	-32(%rbp), %rdx
	movq	-8(%rbp), %rax
	leaq	.LC48(%rip), %rcx
	movq	%rcx, %rsi
	movq	%rax, %rdi
	movl	$0, %eax
	call	fprintf@PLT
	testl	%eax, %eax
	js	.L478
	movq	-8(%rbp), %rax
	movq	%rax, %rdi
	call	fclose@PLT
	jmp	.L479
.L478:
	call	__errno_location@PLT
	movl	(%rax), %eax
	movl	%eax, %edi
	call	strerror@PLT
	movq	%rax, %rdx
	movq	-24(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC96(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
	nop
.L479:
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE81:
	.size	Lfwrite, .-Lfwrite
	.section	.rodata
.LC97:
	.string	"fexists"
	.text
	.globl	Lfexists
	.type	Lfexists, @function
Lfexists:
.LFB82:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movq	-24(%rbp), %rax
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L481
	movq	-24(%rbp), %rax
	subq	$12, %rax
	movl	(%rax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L481
	leaq	.LC97(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC56(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L481:
	movq	-24(%rbp), %rax
	leaq	.LC91(%rip), %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	fopen@PLT
	movq	%rax, -8(%rbp)
	cmpq	$0, -8(%rbp)
	je	.L482
	movl	$3, %eax
	jmp	.L483
.L482:
	movl	$1, %eax
.L483:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE82:
	.size	Lfexists, .-Lfexists
	.globl	Lfst
	.type	Lfst, @function
Lfst:
.LFB83:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	$1, %esi
	movq	%rax, %rdi
	call	Belem
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE83:
	.size	Lfst, .-Lfst
	.globl	Lsnd
	.type	Lsnd, @function
Lsnd:
.LFB84:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	$3, %esi
	movq	%rax, %rdi
	call	Belem
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE84:
	.size	Lsnd, .-Lsnd
	.globl	Lhd
	.type	Lhd, @function
Lhd:
.LFB85:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	$1, %esi
	movq	%rax, %rdi
	call	Belem
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE85:
	.size	Lhd, .-Lhd
	.globl	Ltl
	.type	Ltl, @function
Ltl:
.LFB86:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	$3, %esi
	movq	%rax, %rdi
	call	Belem
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE86:
	.size	Ltl, .-Ltl
	.section	.rodata
.LC98:
	.string	"> "
.LC99:
	.string	"%li"
	.text
	.globl	Lread
	.type	Lread, @function
Lread:
.LFB87:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	movq	$1, -16(%rbp)
	leaq	.LC98(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printf@PLT
	movq	stdout(%rip), %rax
	movq	%rax, %rdi
	call	fflush@PLT
	leaq	-16(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC99(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	__isoc23_scanf@PLT
	movq	-16(%rbp), %rax
	addq	%rax, %rax
	orq	$1, %rax
	movq	-8(%rbp), %rdx
	subq	%fs:40, %rdx
	je	.L494
	call	__stack_chk_fail@PLT
.L494:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE87:
	.size	Lread, .-Lread
	.section	.rodata
	.align 8
.LC100:
	.string	"ERROR: POINTER ARITHMETICS is forbidden; EXIT\n"
	.text
	.globl	Lbinoperror
	.type	Lbinoperror, @function
Lbinoperror:
.LFB88:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	stderr(%rip), %rax
	movq	%rax, %rcx
	movl	$46, %edx
	movl	$1, %esi
	leaq	.LC100(%rip), %rax
	movq	%rax, %rdi
	call	fwrite@PLT
	movl	$1, %edi
	call	exit@PLT
	.cfi_endproc
.LFE88:
	.size	Lbinoperror, .-Lbinoperror
	.section	.rodata
	.align 8
.LC101:
	.string	"ERROR: Comparing BOXED and UNBOXED value ; EXIT\n"
	.text
	.globl	Lbinoperror2
	.type	Lbinoperror2, @function
Lbinoperror2:
.LFB89:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	stderr(%rip), %rax
	movq	%rax, %rcx
	movl	$48, %edx
	movl	$1, %esi
	leaq	.LC101(%rip), %rax
	movq	%rax, %rdi
	call	fwrite@PLT
	movl	$1, %edi
	call	exit@PLT
	.cfi_endproc
.LFE89:
	.size	Lbinoperror2, .-Lbinoperror2
	.section	.rodata
.LC102:
	.string	"%ld\n"
	.text
	.globl	Lwrite
	.type	Lwrite, @function
Lwrite:
.LFB90:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	sarq	%rax
	movq	%rax, %rsi
	leaq	.LC102(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	printf@PLT
	movq	stdout(%rip), %rax
	movq	%rax, %rdi
	call	fflush@PLT
	movl	$0, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE90:
	.size	Lwrite, .-Lwrite
	.section	.rodata
.LC103:
	.string	"Lrandom, 0"
.LC104:
	.string	"invalid range in random: %d\n"
	.text
	.globl	Lrandom
	.type	Lrandom, @function
Lrandom:
.LFB91:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movl	%edi, -4(%rbp)
	movl	-4(%rbp), %eax
	cltq
	andl	$1, %eax
	testq	%rax, %rax
	jne	.L500
	leaq	.LC103(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC10(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L500:
	movl	-4(%rbp), %eax
	sarl	%eax
	testl	%eax, %eax
	jg	.L501
	movl	-4(%rbp), %eax
	sarl	%eax
	cltq
	movq	%rax, %rsi
	leaq	.LC104(%rip), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	failure
.L501:
	call	random@PLT
	movl	-4(%rbp), %edx
	sarl	%edx
	movslq	%edx, %rcx
	cqto
	idivq	%rcx
	movq	%rdx, %rcx
	movq	%rcx, %rax
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE91:
	.size	Lrandom, .-Lrandom
	.globl	Ltime
	.type	Ltime, @function
Ltime:
.LFB92:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	leaq	-32(%rbp), %rax
	movq	%rax, %rsi
	movl	$4, %edi
	call	clock_gettime@PLT
	movq	-32(%rbp), %rax
	imulq	$1000000, %rax, %rsi
	movq	-24(%rbp), %rcx
	movabsq	$2361183241434822607, %rdx
	movq	%rcx, %rax
	imulq	%rdx
	sarq	$7, %rdx
	movq	%rcx, %rax
	sarq	$63, %rax
	subq	%rax, %rdx
	leaq	(%rsi,%rdx), %rax
	addl	%eax, %eax
	orl	$1, %eax
	movq	-8(%rbp), %rdx
	subq	%fs:40, %rdx
	je	.L505
	call	__stack_chk_fail@PLT
.L505:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE92:
	.size	Ltime, .-Ltime
	.globl	set_args
	.type	set_args, @function
set_args:
.LFB93:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movl	%edi, -36(%rbp)
	movq	%rsi, -48(%rbp)
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	movl	-36(%rbp), %eax
	movl	%eax, -20(%rbp)
	movq	$0, -16(%rbp)
	movb	$0, -25(%rbp)
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	sete	%al
	movb	%al, -25(%rbp)
	cmpb	$0, -25(%rbp)
	je	.L507
	movq	%rbp, %rax
	movq	%rax, __gc_stack_top(%rip)
.L507:
	movq	__gc_stack_top(%rip), %rax
	testq	%rax, %rax
	jne	.L508
	leaq	__PRETTY_FUNCTION__.0(%rip), %rax
	movq	%rax, %rcx
	movl	$1244, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC6(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L508:
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L509
	leaq	__PRETTY_FUNCTION__.0(%rip), %rax
	movq	%rax, %rcx
	movl	$1244, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L509:
	movl	-20(%rbp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	movl	%eax, %edi
	call	LmakeArray
	movq	%rax, -16(%rbp)
	leaq	-16(%rbp), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	movl	$0, -24(%rbp)
	jmp	.L510
.L511:
	movl	-24(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	movq	-48(%rbp), %rax
	addq	%rdx, %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	Bstring
	movq	%rax, %rcx
	movq	-16(%rbp), %rax
	movl	-24(%rbp), %edx
	movslq	%edx, %rdx
	salq	$2, %rdx
	addq	%rdx, %rax
	movl	%ecx, %edx
	movl	%edx, (%rax)
	addl	$1, -24(%rbp)
.L510:
	movl	-24(%rbp), %eax
	cmpl	-20(%rbp), %eax
	jl	.L511
	leaq	-16(%rbp), %rax
	movq	%rax, %rdi
	call	pop_extra_root@PLT
	movq	%rbp, %rax
	movq	__gc_stack_top(%rip), %rdx
	cmpq	%rax, %rdx
	jnb	.L512
	leaq	__PRETTY_FUNCTION__.0(%rip), %rax
	movq	%rax, %rcx
	movl	$1252, %edx
	leaq	.LC5(%rip), %rax
	movq	%rax, %rsi
	leaq	.LC7(%rip), %rax
	movq	%rax, %rdi
	call	__assert_fail@PLT
.L512:
	cmpb	$0, -25(%rbp)
	je	.L513
	movq	$0, __gc_stack_top(%rip)
.L513:
	movq	-16(%rbp), %rax
	movq	%rax, global_sysargs(%rip)
	leaq	global_sysargs(%rip), %rax
	movq	%rax, %rdi
	call	push_extra_root@PLT
	nop
	movq	-8(%rbp), %rax
	subq	%fs:40, %rax
	je	.L514
	call	__stack_chk_fail@PLT
.L514:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE93:
	.size	set_args, .-set_args
	.section	.rodata
	.align 8
	.type	__PRETTY_FUNCTION__.15, @object
	.size	__PRETTY_FUNCTION__.15, 13
__PRETTY_FUNCTION__.15:
	.string	"Ls__Infix_58"
	.local	buf.14
	.comm	buf.14,6,1
	.align 8
	.type	__PRETTY_FUNCTION__.13, @object
	.size	__PRETTY_FUNCTION__.13, 11
__PRETTY_FUNCTION__.13:
	.string	"Lsubstring"
	.type	__PRETTY_FUNCTION__.12, @object
	.size	__PRETTY_FUNCTION__.12, 7
__PRETTY_FUNCTION__.12:
	.string	"Lclone"
	.align 8
	.type	__PRETTY_FUNCTION__.11, @object
	.size	__PRETTY_FUNCTION__.11, 11
__PRETTY_FUNCTION__.11:
	.string	"LmakeArray"
	.align 8
	.type	__PRETTY_FUNCTION__.10, @object
	.size	__PRETTY_FUNCTION__.10, 12
__PRETTY_FUNCTION__.10:
	.string	"LmakeString"
	.align 8
	.type	__PRETTY_FUNCTION__.9, @object
	.size	__PRETTY_FUNCTION__.9, 8
__PRETTY_FUNCTION__.9:
	.string	"Bstring"
	.align 8
	.type	__PRETTY_FUNCTION__.8, @object
	.size	__PRETTY_FUNCTION__.8, 11
__PRETTY_FUNCTION__.8:
	.string	"Lstringcat"
	.align 8
	.type	__PRETTY_FUNCTION__.7, @object
	.size	__PRETTY_FUNCTION__.7, 8
__PRETTY_FUNCTION__.7:
	.string	"Lstring"
	.align 8
	.type	__PRETTY_FUNCTION__.6, @object
	.size	__PRETTY_FUNCTION__.6, 9
__PRETTY_FUNCTION__.6:
	.string	"Bclosure"
	.type	__PRETTY_FUNCTION__.5, @object
	.size	__PRETTY_FUNCTION__.5, 7
__PRETTY_FUNCTION__.5:
	.string	"Barray"
	.type	__PRETTY_FUNCTION__.4, @object
	.size	__PRETTY_FUNCTION__.4, 6
__PRETTY_FUNCTION__.4:
	.string	"Bsexp"
	.align 8
	.type	__PRETTY_FUNCTION__.3, @object
	.size	__PRETTY_FUNCTION__.3, 15
__PRETTY_FUNCTION__.3:
	.string	"Li__Infix_4343"
	.align 8
	.type	__PRETTY_FUNCTION__.2, @object
	.size	__PRETTY_FUNCTION__.2, 9
__PRETTY_FUNCTION__.2:
	.string	"Lsprintf"
	.align 8
	.type	__PRETTY_FUNCTION__.1, @object
	.size	__PRETTY_FUNCTION__.1, 8
__PRETTY_FUNCTION__.1:
	.string	"LgetEnv"
	.align 8
	.type	__PRETTY_FUNCTION__.0, @object
	.size	__PRETTY_FUNCTION__.0, 9
__PRETTY_FUNCTION__.0:
	.string	"set_args"
	.ident	"GCC: (GNU) 13.2.1 20230801"
	.section	.note.GNU-stack,"",@progbits
