	.file	"runtime.c"
	.text
	.local	from_space
	.comm	from_space,16,4
	.local	to_space
	.comm	to_space,16,4
	.comm	current,4,4
	.local	extra_roots
	.comm	extra_roots,20,4
	.globl	clear_extra_roots
	.type	clear_extra_roots, @function
clear_extra_roots:
.LFB5:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	$0, extra_roots@GOTOFF(%eax)
	nop
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE5:
	.size	clear_extra_roots, .-clear_extra_roots
	.section	.rodata
	.align 4
.LC0:
	.string	"ERROR: push_extra_roots: extra_roots_pool overflow"
	.text
	.globl	push_extra_root
	.type	push_extra_root, @function
push_extra_root:
.LFB6:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	extra_roots@GOTOFF(%ebx), %eax
	cmpl	$3, %eax
	jle	.L3
	subl	$12, %esp
	leal	.LC0@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L3:
	movl	extra_roots@GOTOFF(%ebx), %eax
	movl	8(%ebp), %edx
	movl	%edx, 4+extra_roots@GOTOFF(%ebx,%eax,4)
	movl	extra_roots@GOTOFF(%ebx), %eax
	addl	$1, %eax
	movl	%eax, extra_roots@GOTOFF(%ebx)
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE6:
	.size	push_extra_root, .-push_extra_root
	.section	.rodata
	.align 4
.LC1:
	.string	"ERROR: pop_extra_root: extra_roots are empty"
	.align 4
.LC2:
	.string	"ERROR: pop_extra_root: stack invariant violation"
	.text
	.globl	pop_extra_root
	.type	pop_extra_root, @function
pop_extra_root:
.LFB7:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	extra_roots@GOTOFF(%ebx), %eax
	testl	%eax, %eax
	jne	.L5
	subl	$12, %esp
	leal	.LC1@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L5:
	movl	extra_roots@GOTOFF(%ebx), %eax
	subl	$1, %eax
	movl	%eax, extra_roots@GOTOFF(%ebx)
	movl	extra_roots@GOTOFF(%ebx), %eax
	movl	4+extra_roots@GOTOFF(%ebx,%eax,4), %eax
	cmpl	%eax, 8(%ebp)
	je	.L7
	subl	$12, %esp
	leal	.LC2@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L7:
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE7:
	.size	pop_extra_root, .-pop_extra_root
	.section	.rodata
.LC3:
	.string	"*** FAILURE: "
	.text
	.type	vfailure, @function
vfailure:
.LFB8:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	stderr@GOT(%ebx), %eax
	movl	(%eax), %eax
	pushl	%eax
	pushl	$13
	pushl	$1
	leal	.LC3@GOTOFF(%ebx), %eax
	pushl	%eax
	call	fwrite@PLT
	addl	$16, %esp
	movl	stderr@GOT(%ebx), %eax
	movl	(%eax), %eax
	subl	$4, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
	pushl	%eax
	call	vfprintf@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$255
	call	exit@PLT
	.cfi_endproc
.LFE8:
	.size	vfailure, .-vfailure
	.type	failure, @function
failure:
.LFB9:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$40, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	leal	12(%ebp), %eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	subl	$8, %esp
	pushl	%eax
	pushl	-28(%ebp)
	call	vfailure
	addl	$16, %esp
	nop
	movl	-12(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L10
	call	__stack_chk_fail_local
.L10:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE9:
	.size	failure, .-failure
	.comm	global_sysargs,4,4
	.globl	Ls__Infix_58
	.type	Ls__Infix_58, @function
Ls__Infix_58:
.LFB10:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	call	__pre_gc@PLT
	pushl	$848787
	pushl	12(%ebp)
	pushl	8(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	call	__post_gc@PLT
	movl	-12(%ebp), %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE10:
	.size	Ls__Infix_58, .-Ls__Infix_58
	.section	.rodata
.LC4:
	.string	"captured !!:1"
.LC5:
	.string	"unboxed value expected in %s\n"
.LC6:
	.string	"captured !!:2"
	.text
	.globl	Ls__Infix_3333
	.type	Ls__Infix_3333, @function
Ls__Infix_3333:
.LFB11:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L14
	subl	$8, %esp
	leal	.LC4@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L14:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L15
	subl	$8, %esp
	leal	.LC6@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L15:
	movl	8(%ebp), %eax
	sarl	%eax
	testl	%eax, %eax
	jne	.L16
	movl	12(%ebp), %eax
	sarl	%eax
	testl	%eax, %eax
	je	.L17
.L16:
	movl	$1, %eax
	jmp	.L18
.L17:
	movl	$0, %eax
.L18:
	addl	%eax, %eax
	orl	$1, %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE11:
	.size	Ls__Infix_3333, .-Ls__Infix_3333
	.section	.rodata
.LC7:
	.string	"captured &&:1"
.LC8:
	.string	"captured &&:2"
	.text
	.globl	Ls__Infix_3838
	.type	Ls__Infix_3838, @function
Ls__Infix_3838:
.LFB12:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L21
	subl	$8, %esp
	leal	.LC7@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L21:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L22
	subl	$8, %esp
	leal	.LC8@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L22:
	movl	8(%ebp), %eax
	sarl	%eax
	testl	%eax, %eax
	je	.L23
	movl	12(%ebp), %eax
	sarl	%eax
	testl	%eax, %eax
	je	.L23
	movl	$1, %eax
	jmp	.L24
.L23:
	movl	$0, %eax
.L24:
	addl	%eax, %eax
	orl	$1, %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE12:
	.size	Ls__Infix_3838, .-Ls__Infix_3838
	.section	.rodata
.LC9:
	.string	"captured ==:1"
.LC10:
	.string	"captured ==:2"
	.text
	.globl	Ls__Infix_6161
	.type	Ls__Infix_6161, @function
Ls__Infix_6161:
.LFB13:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L27
	subl	$8, %esp
	leal	.LC9@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L27:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L28
	subl	$8, %esp
	leal	.LC10@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L28:
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	cmpl	%eax, %edx
	jne	.L29
	movl	$3, %eax
	jmp	.L31
.L29:
	movl	$1, %eax
.L31:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE13:
	.size	Ls__Infix_6161, .-Ls__Infix_6161
	.section	.rodata
.LC11:
	.string	"captured !=:1"
.LC12:
	.string	"captured !=:2"
	.text
	.globl	Ls__Infix_3361
	.type	Ls__Infix_3361, @function
Ls__Infix_3361:
.LFB14:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L33
	subl	$8, %esp
	leal	.LC11@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L33:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L34
	subl	$8, %esp
	leal	.LC12@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L34:
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	cmpl	%eax, %edx
	je	.L35
	movl	$3, %eax
	jmp	.L37
.L35:
	movl	$1, %eax
.L37:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE14:
	.size	Ls__Infix_3361, .-Ls__Infix_3361
	.section	.rodata
.LC13:
	.string	"captured <=:1"
.LC14:
	.string	"captured <=:2"
	.text
	.globl	Ls__Infix_6061
	.type	Ls__Infix_6061, @function
Ls__Infix_6061:
.LFB15:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L39
	subl	$8, %esp
	leal	.LC13@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L39:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L40
	subl	$8, %esp
	leal	.LC14@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L40:
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	cmpl	%eax, %edx
	jg	.L41
	movl	$3, %eax
	jmp	.L43
.L41:
	movl	$1, %eax
.L43:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE15:
	.size	Ls__Infix_6061, .-Ls__Infix_6061
	.section	.rodata
.LC15:
	.string	"captured <:1"
.LC16:
	.string	"captured <:2"
	.text
	.globl	Ls__Infix_60
	.type	Ls__Infix_60, @function
Ls__Infix_60:
.LFB16:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L45
	subl	$8, %esp
	leal	.LC15@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L45:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L46
	subl	$8, %esp
	leal	.LC16@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L46:
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	cmpl	%eax, %edx
	jge	.L47
	movl	$3, %eax
	jmp	.L49
.L47:
	movl	$1, %eax
.L49:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE16:
	.size	Ls__Infix_60, .-Ls__Infix_60
	.section	.rodata
.LC17:
	.string	"captured >=:1"
.LC18:
	.string	"captured >=:2"
	.text
	.globl	Ls__Infix_6261
	.type	Ls__Infix_6261, @function
Ls__Infix_6261:
.LFB17:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L51
	subl	$8, %esp
	leal	.LC17@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L51:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L52
	subl	$8, %esp
	leal	.LC18@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L52:
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	cmpl	%eax, %edx
	jl	.L53
	movl	$3, %eax
	jmp	.L55
.L53:
	movl	$1, %eax
.L55:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE17:
	.size	Ls__Infix_6261, .-Ls__Infix_6261
	.section	.rodata
.LC19:
	.string	"captured >:1"
.LC20:
	.string	"captured >:2"
	.text
	.globl	Ls__Infix_62
	.type	Ls__Infix_62, @function
Ls__Infix_62:
.LFB18:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L57
	subl	$8, %esp
	leal	.LC19@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L57:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L58
	subl	$8, %esp
	leal	.LC20@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L58:
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	cmpl	%eax, %edx
	jle	.L59
	movl	$3, %eax
	jmp	.L61
.L59:
	movl	$1, %eax
.L61:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE18:
	.size	Ls__Infix_62, .-Ls__Infix_62
	.section	.rodata
.LC21:
	.string	"captured +:1"
.LC22:
	.string	"captured +:2"
	.text
	.globl	Ls__Infix_43
	.type	Ls__Infix_43, @function
Ls__Infix_43:
.LFB19:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L63
	subl	$8, %esp
	leal	.LC21@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L63:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L64
	subl	$8, %esp
	leal	.LC22@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L64:
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	addl	%edx, %eax
	addl	%eax, %eax
	orl	$1, %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE19:
	.size	Ls__Infix_43, .-Ls__Infix_43
	.section	.rodata
.LC23:
	.string	"captured -:1"
.LC24:
	.string	"captured -:2"
	.text
	.globl	Ls__Infix_45
	.type	Ls__Infix_45, @function
Ls__Infix_45:
.LFB20:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L67
	subl	$8, %esp
	leal	.LC23@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L67:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L68
	subl	$8, %esp
	leal	.LC24@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L68:
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	subl	%eax, %edx
	movl	%edx, %eax
	addl	%eax, %eax
	orl	$1, %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE20:
	.size	Ls__Infix_45, .-Ls__Infix_45
	.section	.rodata
.LC25:
	.string	"captured *:1"
.LC26:
	.string	"captured *:2"
	.text
	.globl	Ls__Infix_42
	.type	Ls__Infix_42, @function
Ls__Infix_42:
.LFB21:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L71
	subl	$8, %esp
	leal	.LC25@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L71:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L72
	subl	$8, %esp
	leal	.LC26@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L72:
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	imull	%edx, %eax
	addl	%eax, %eax
	orl	$1, %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE21:
	.size	Ls__Infix_42, .-Ls__Infix_42
	.section	.rodata
.LC27:
	.string	"captured /:1"
.LC28:
	.string	"captured /:2"
	.text
	.globl	Ls__Infix_47
	.type	Ls__Infix_47, @function
Ls__Infix_47:
.LFB22:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L75
	subl	$8, %esp
	leal	.LC27@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L75:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L76
	subl	$8, %esp
	leal	.LC28@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L76:
	movl	8(%ebp), %eax
	sarl	%eax
	movl	12(%ebp), %edx
	movl	%edx, %ecx
	sarl	%ecx
	cltd
	idivl	%ecx
	addl	%eax, %eax
	orl	$1, %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE22:
	.size	Ls__Infix_47, .-Ls__Infix_47
	.section	.rodata
.LC29:
	.string	"captured %:1"
.LC30:
	.string	"captured %:2"
	.text
	.globl	Ls__Infix_37
	.type	Ls__Infix_37, @function
Ls__Infix_37:
.LFB23:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L79
	subl	$8, %esp
	leal	.LC29@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L79:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L80
	subl	$8, %esp
	leal	.LC30@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L80:
	movl	8(%ebp), %eax
	sarl	%eax
	movl	12(%ebp), %edx
	movl	%edx, %ecx
	sarl	%ecx
	cltd
	idivl	%ecx
	movl	%edx, %eax
	addl	%eax, %eax
	orl	$1, %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE23:
	.size	Ls__Infix_37, .-Ls__Infix_37
	.section	.rodata
.LC31:
	.string	".length"
.LC32:
	.string	"boxed value expected in %s\n"
	.text
	.globl	Blength
	.type	Blength, @function
Blength:
.LFB24:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	$1, -12(%ebp)
	movl	8(%ebp), %edx
	andl	$1, %edx
	testl	%edx, %edx
	je	.L83
	subl	$8, %esp
	leal	.LC31@GOTOFF(%eax), %edx
	pushl	%edx
	leal	.LC32@GOTOFF(%eax), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L83:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -12(%ebp)
	movl	-12(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE24:
	.size	Blength, .-Blength
	.section	.rodata
	.align 4
.LC33:
	.string	"_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	.text
	.globl	de_hash
	.type	de_hash, @function
de_hash:
.LFB25:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$16, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	$1, -8(%ebp)
	leal	.LC33@GOTOFF(%eax), %edx
	movl	%edx, chars.2795@GOTOFF(%eax)
	leal	5+buf.2796@GOTOFF(%eax), %edx
	movl	%edx, -8(%ebp)
	movl	-8(%ebp), %edx
	leal	-1(%edx), %ecx
	movl	%ecx, -8(%ebp)
	movb	$0, (%edx)
	jmp	.L86
.L87:
	movl	chars.2795@GOTOFF(%eax), %edx
	movl	8(%ebp), %ecx
	andl	$63, %ecx
	leal	(%edx,%ecx), %ebx
	movl	-8(%ebp), %edx
	leal	-1(%edx), %ecx
	movl	%ecx, -8(%ebp)
	movzbl	(%ebx), %ecx
	movb	%cl, (%edx)
	sarl	$6, 8(%ebp)
.L86:
	cmpl	$0, 8(%ebp)
	jne	.L87
	addl	$1, -8(%ebp)
	movl	-8(%ebp), %eax
	addl	$16, %esp
	popl	%ebx
	.cfi_restore 3
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE25:
	.size	de_hash, .-de_hash
	.local	stringBuf
	.comm	stringBuf,12,4
	.type	createStringBuf, @function
createStringBuf:
.LFB26:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	subl	$12, %esp
	pushl	$128
	call	malloc@PLT
	addl	$16, %esp
	movl	%eax, stringBuf@GOTOFF(%ebx)
	movl	$0, 4+stringBuf@GOTOFF(%ebx)
	movl	$128, 8+stringBuf@GOTOFF(%ebx)
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE26:
	.size	createStringBuf, .-createStringBuf
	.type	deleteStringBuf, @function
deleteStringBuf:
.LFB27:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	stringBuf@GOTOFF(%eax), %edx
	subl	$12, %esp
	pushl	%edx
	movl	%eax, %ebx
	call	free@PLT
	addl	$16, %esp
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE27:
	.size	deleteStringBuf, .-deleteStringBuf
	.type	extendStringBuf, @function
extendStringBuf:
.LFB28:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8+stringBuf@GOTOFF(%ebx), %eax
	addl	%eax, %eax
	movl	%eax, -12(%ebp)
	movl	-12(%ebp), %edx
	movl	stringBuf@GOTOFF(%ebx), %eax
	subl	$8, %esp
	pushl	%edx
	pushl	%eax
	call	realloc@PLT
	addl	$16, %esp
	movl	%eax, stringBuf@GOTOFF(%ebx)
	movl	-12(%ebp), %eax
	movl	%eax, 8+stringBuf@GOTOFF(%ebx)
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE28:
	.size	extendStringBuf, .-extendStringBuf
	.type	vprintStringBuf, @function
vprintStringBuf:
.LFB29:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	$0, -20(%ebp)
	movl	$0, -16(%ebp)
	movl	$1, -12(%ebp)
.L93:
	movl	stringBuf@GOTOFF(%ebx), %eax
	movl	4+stringBuf@GOTOFF(%ebx), %edx
	addl	%edx, %eax
	movl	%eax, -12(%ebp)
	movl	8+stringBuf@GOTOFF(%ebx), %edx
	movl	4+stringBuf@GOTOFF(%ebx), %eax
	subl	%eax, %edx
	movl	%edx, %eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	pushl	12(%ebp)
	pushl	8(%ebp)
	pushl	%eax
	pushl	-12(%ebp)
	call	vsnprintf@PLT
	addl	$16, %esp
	movl	%eax, -20(%ebp)
	movl	-20(%ebp), %eax
	cmpl	-16(%ebp), %eax
	jl	.L94
	call	extendStringBuf
	jmp	.L93
.L94:
	movl	4+stringBuf@GOTOFF(%ebx), %edx
	movl	-20(%ebp), %eax
	addl	%edx, %eax
	movl	%eax, 4+stringBuf@GOTOFF(%ebx)
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE29:
	.size	vprintStringBuf, .-vprintStringBuf
	.type	printStringBuf, @function
printStringBuf:
.LFB30:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$40, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	leal	12(%ebp), %eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	subl	$8, %esp
	pushl	%eax
	pushl	-28(%ebp)
	call	vprintStringBuf
	addl	$16, %esp
	nop
	movl	-12(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L96
	call	__stack_chk_fail_local
.L96:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE30:
	.size	printStringBuf, .-printStringBuf
	.section	.rodata
.LC34:
	.string	"%d"
.LC35:
	.string	"\"%s\""
.LC36:
	.string	"<closure "
.LC37:
	.string	"%x"
.LC38:
	.string	", "
.LC39:
	.string	">"
.LC40:
	.string	"["
.LC41:
	.string	"]"
.LC42:
	.string	"cons"
.LC43:
	.string	"{"
.LC44:
	.string	"}"
.LC45:
	.string	"%s"
.LC46:
	.string	" ("
.LC47:
	.string	")"
.LC48:
	.string	"*** invalid tag: %x ***"
	.text
	.type	printValue, @function
printValue:
.LFB31:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	$1, -16(%ebp)
	movl	$1, -24(%ebp)
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L98
	movl	8(%ebp), %eax
	sarl	%eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC34@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L125
.L98:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$3, %eax
	je	.L101
	cmpl	$3, %eax
	jg	.L102
	cmpl	$1, %eax
	je	.L103
	jmp	.L100
.L102:
	cmpl	$5, %eax
	je	.L104
	cmpl	$7, %eax
	je	.L105
	jmp	.L100
.L103:
	movl	-16(%ebp), %eax
	addl	$4, %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC35@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L99
.L105:
	subl	$12, %esp
	leal	.LC36@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	movl	$0, -24(%ebp)
	jmp	.L106
.L110:
	cmpl	$0, -24(%ebp)
	je	.L107
	movl	-16(%ebp), %eax
	leal	4(%eax), %edx
	movl	-24(%ebp), %eax
	sall	$2, %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	printValue
	addl	$16, %esp
	jmp	.L108
.L107:
	movl	-16(%ebp), %eax
	leal	4(%eax), %edx
	movl	-24(%ebp), %eax
	sall	$2, %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC37@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
.L108:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	leal	-1(%eax), %edx
	movl	-24(%ebp), %eax
	cmpl	%eax, %edx
	je	.L109
	subl	$12, %esp
	leal	.LC38@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
.L109:
	addl	$1, -24(%ebp)
.L106:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	cmpl	%eax, %edx
	ja	.L110
	subl	$12, %esp
	leal	.LC39@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L99
.L101:
	subl	$12, %esp
	leal	.LC40@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	movl	$0, -24(%ebp)
	jmp	.L111
.L113:
	movl	-16(%ebp), %eax
	leal	4(%eax), %edx
	movl	-24(%ebp), %eax
	sall	$2, %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	printValue
	addl	$16, %esp
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	leal	-1(%eax), %edx
	movl	-24(%ebp), %eax
	cmpl	%eax, %edx
	je	.L112
	subl	$12, %esp
	leal	.LC38@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
.L112:
	addl	$1, -24(%ebp)
.L111:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	cmpl	%eax, %edx
	ja	.L113
	subl	$12, %esp
	leal	.LC41@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L99
.L104:
	movl	8(%ebp), %eax
	subl	$8, %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	de_hash
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	subl	$8, %esp
	leal	.LC42@GOTOFF(%ebx), %eax
	pushl	%eax
	pushl	-12(%ebp)
	call	strcmp@PLT
	addl	$16, %esp
	testl	%eax, %eax
	jne	.L114
	movl	-16(%ebp), %eax
	movl	%eax, -20(%ebp)
	subl	$12, %esp
	leal	.LC43@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L115
.L118:
	movl	-20(%ebp), %eax
	addl	$4, %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	printValue
	addl	$16, %esp
	movl	-20(%ebp), %eax
	addl	$4, %eax
	addl	$4, %eax
	movl	(%eax), %eax
	movl	%eax, -20(%ebp)
	movl	-20(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L123
	subl	$12, %esp
	leal	.LC38@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	subl	$4, -20(%ebp)
.L115:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	testl	%eax, %eax
	jne	.L118
	jmp	.L117
.L123:
	nop
.L117:
	subl	$12, %esp
	leal	.LC44@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L124
.L114:
	subl	$8, %esp
	pushl	-12(%ebp)
	leal	.LC45@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	testl	%eax, %eax
	je	.L124
	subl	$12, %esp
	leal	.LC46@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	movl	$0, -24(%ebp)
	jmp	.L120
.L122:
	movl	-16(%ebp), %eax
	leal	4(%eax), %edx
	movl	-24(%ebp), %eax
	sall	$2, %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	printValue
	addl	$16, %esp
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	leal	-1(%eax), %edx
	movl	-24(%ebp), %eax
	cmpl	%eax, %edx
	je	.L121
	subl	$12, %esp
	leal	.LC38@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
.L121:
	addl	$1, -24(%ebp)
.L120:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	cmpl	%eax, %edx
	ja	.L122
	subl	$12, %esp
	leal	.LC47@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L124
.L100:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC48@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L125
.L124:
	nop
.L99:
.L125:
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE31:
	.size	printValue, .-printValue
	.section	.rodata
.LC49:
	.string	"*** non-list tag: %s ***"
	.text
	.type	stringcat, @function
stringcat:
.LFB32:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L138
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L129
	cmpl	$5, %eax
	je	.L130
	jmp	.L137
.L129:
	movl	-16(%ebp), %eax
	addl	$4, %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC45@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L127
.L130:
	movl	8(%ebp), %eax
	subl	$8, %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	de_hash
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	subl	$8, %esp
	leal	.LC42@GOTOFF(%ebx), %eax
	pushl	%eax
	pushl	-12(%ebp)
	call	strcmp@PLT
	addl	$16, %esp
	testl	%eax, %eax
	jne	.L131
	movl	-16(%ebp), %eax
	movl	%eax, -20(%ebp)
	jmp	.L132
.L135:
	movl	-20(%ebp), %eax
	addl	$4, %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	stringcat
	addl	$16, %esp
	movl	-20(%ebp), %eax
	addl	$4, %eax
	addl	$4, %eax
	movl	(%eax), %eax
	movl	%eax, -20(%ebp)
	movl	-20(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L139
	subl	$4, -20(%ebp)
.L132:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	testl	%eax, %eax
	jne	.L135
	jmp	.L127
.L131:
	subl	$8, %esp
	pushl	-12(%ebp)
	leal	.LC49@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L127
.L139:
	nop
	jmp	.L127
.L137:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC48@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L138
.L127:
.L138:
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE32:
	.size	stringcat, .-stringcat
	.section	.rodata
.LC50:
	.string	"matchSubString:1"
.LC51:
	.string	"sting value expected in %s\n"
.LC52:
	.string	"matchSubString:2"
.LC53:
	.string	"matchSubString:3"
	.text
	.globl	LmatchSubString
	.type	LmatchSubString, @function
LmatchSubString:
.LFB33:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	12(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -16(%ebp)
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L141
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L141
	subl	$8, %esp
	leal	.LC50@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L141:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L142
	movl	12(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L142
	subl	$8, %esp
	leal	.LC52@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L142:
	movl	16(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L143
	subl	$8, %esp
	leal	.LC53@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L143:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, -12(%ebp)
	movl	-12(%ebp), %eax
	movl	16(%ebp), %edx
	sarl	%edx
	movl	%edx, %ecx
	movl	8(%ebp), %edx
	addl	%ecx, %edx
	subl	$4, %esp
	pushl	%eax
	pushl	12(%ebp)
	pushl	%edx
	call	strncmp@PLT
	addl	$16, %esp
	testl	%eax, %eax
	jne	.L144
	movl	$3, %eax
	jmp	.L146
.L144:
	movl	$1, %eax
.L146:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE33:
	.size	LmatchSubString, .-LmatchSubString
	.section	.rodata
.LC54:
	.string	"substring:1"
.LC55:
	.string	"substring:2"
.LC56:
	.string	"substring:3"
	.align 4
.LC57:
	.string	"substring: index out of bounds (position=%d, length=%d,             subject length=%d)"
	.text
	.globl	Lsubstring
	.type	Lsubstring, @function
Lsubstring:
.LFB34:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -24(%ebp)
	movl	12(%ebp), %eax
	sarl	%eax
	movl	%eax, -20(%ebp)
	movl	16(%ebp), %eax
	sarl	%eax
	movl	%eax, -16(%ebp)
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L148
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L148
	subl	$8, %esp
	leal	.LC54@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L148:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L149
	subl	$8, %esp
	leal	.LC55@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L149:
	movl	16(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L150
	subl	$8, %esp
	leal	.LC56@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L150:
	movl	-20(%ebp), %edx
	movl	-16(%ebp), %eax
	addl	%edx, %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	cmpl	%eax, %edx
	ja	.L151
	call	__pre_gc@PLT
	movl	-16(%ebp), %eax
	addl	$5, %eax
	subl	$12, %esp
	pushl	%eax
	call	alloc
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	movl	-16(%ebp), %eax
	sall	$3, %eax
	orl	$1, %eax
	movl	%eax, %edx
	movl	-12(%ebp), %eax
	movl	%edx, (%eax)
	movl	-16(%ebp), %eax
	movl	-20(%ebp), %ecx
	movl	8(%ebp), %edx
	addl	%edx, %ecx
	movl	-12(%ebp), %edx
	addl	$4, %edx
	subl	$4, %esp
	pushl	%eax
	pushl	%ecx
	pushl	%edx
	call	strncpy@PLT
	addl	$16, %esp
	call	__post_gc@PLT
	movl	-12(%ebp), %eax
	addl	$4, %eax
	jmp	.L147
.L151:
	movl	-24(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	pushl	%eax
	pushl	-16(%ebp)
	pushl	-20(%ebp)
	leal	.LC57@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L147:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE34:
	.size	Lsubstring, .-Lsubstring
	.section	.rodata
.LC58:
	.string	"%"
	.text
	.globl	Lregexp
	.type	Lregexp, @function
Lregexp:
.LFB35:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	subl	$12, %esp
	pushl	$32
	call	malloc@PLT
	addl	$16, %esp
	movl	%eax, -16(%ebp)
	subl	$12, %esp
	pushl	8(%ebp)
	call	strlen@PLT
	addl	$16, %esp
	subl	$4, %esp
	pushl	-16(%ebp)
	pushl	%eax
	pushl	8(%ebp)
	call	re_compile_pattern@PLT
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	cmpl	$0, -12(%ebp)
	je	.L154
	subl	$12, %esp
	pushl	-12(%ebp)
	call	strerror@PLT
	addl	$16, %esp
	subl	$8, %esp
	pushl	%eax
	leal	.LC58@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L154:
	movl	-16(%ebp), %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE35:
	.size	Lregexp, .-Lregexp
	.section	.rodata
.LC59:
	.string	"regexpMatch:1"
.LC60:
	.string	"regexpMatch:2"
.LC61:
	.string	"regexpMatch:3"
	.text
	.globl	LregexpMatch
	.type	LregexpMatch, @function
LregexpMatch:
.LFB36:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L157
	subl	$8, %esp
	leal	.LC59@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC32@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L157:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L158
	movl	12(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L158
	subl	$8, %esp
	leal	.LC60@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L158:
	movl	16(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L159
	subl	$8, %esp
	leal	.LC61@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L159:
	movl	16(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	subl	$12, %esp
	pushl	$0
	pushl	%edx
	pushl	%eax
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	re_match@PLT
	addl	$32, %esp
	addl	%eax, %eax
	orl	$1, %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE36:
	.size	LregexpMatch, .-LregexpMatch
	.section	.rodata
	.align 4
.LC62:
	.string	"invalid tag %d in clone *****\n"
	.text
	.globl	Lclone
	.type	Lclone, @function
Lclone:
.LFB37:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	call	__pre_gc@PLT
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L162
	movl	8(%ebp), %eax
	jmp	.L163
.L162:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -20(%ebp)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	movl	%eax, -16(%ebp)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, -12(%ebp)
	subl	$12, %esp
	leal	8(%ebp), %eax
	pushl	%eax
	call	push_extra_root
	addl	$16, %esp
	movl	-16(%ebp), %eax
	cmpl	$3, %eax
	je	.L165
	cmpl	$3, %eax
	jg	.L166
	cmpl	$1, %eax
	je	.L167
	jmp	.L164
.L166:
	cmpl	$5, %eax
	je	.L168
	cmpl	$7, %eax
	je	.L165
	jmp	.L164
.L167:
	movl	8(%ebp), %eax
	subl	$4, %eax
	addl	$4, %eax
	subl	$12, %esp
	pushl	%eax
	call	Bstring
	addl	$16, %esp
	movl	%eax, -24(%ebp)
.L165:
	movl	-12(%ebp), %eax
	addl	$1, %eax
	sall	$2, %eax
	subl	$12, %esp
	pushl	%eax
	call	alloc
	addl	$16, %esp
	movl	%eax, -24(%ebp)
	movl	-12(%ebp), %eax
	addl	$1, %eax
	leal	0(,%eax,4), %edx
	movl	8(%ebp), %eax
	subl	$4, %eax
	subl	$4, %esp
	pushl	%edx
	pushl	%eax
	pushl	-24(%ebp)
	call	memcpy@PLT
	addl	$16, %esp
	addl	$4, -24(%ebp)
	jmp	.L169
.L168:
	movl	-12(%ebp), %eax
	addl	$2, %eax
	sall	$2, %eax
	subl	$12, %esp
	pushl	%eax
	call	alloc
	addl	$16, %esp
	movl	%eax, -24(%ebp)
	movl	-12(%ebp), %eax
	addl	$2, %eax
	leal	0(,%eax,4), %edx
	movl	8(%ebp), %eax
	subl	$8, %eax
	subl	$4, %esp
	pushl	%edx
	pushl	%eax
	pushl	-24(%ebp)
	call	memcpy@PLT
	addl	$16, %esp
	addl	$4, -24(%ebp)
	addl	$4, -24(%ebp)
	jmp	.L169
.L164:
	subl	$8, %esp
	pushl	-16(%ebp)
	leal	.LC62@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L169:
	subl	$12, %esp
	leal	8(%ebp), %eax
	pushl	%eax
	call	pop_extra_root
	addl	$16, %esp
	call	__post_gc@PLT
	movl	-24(%ebp), %eax
.L163:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE37:
	.size	Lclone, .-Lclone
	.section	.rodata
.LC63:
	.string	"invalid tag %d in hash *****\n"
	.text
	.globl	inner_hash
	.type	inner_hash, @function
inner_hash:
.LFB38:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$40, %esp
	call	__x86.get_pc_thunk.dx
	addl	$_GLOBAL_OFFSET_TABLE_, %edx
	cmpl	$3, 8(%ebp)
	jle	.L171
	movl	12(%ebp), %eax
	jmp	.L172
.L171:
	movl	16(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L173
	movl	16(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	addl	%edx, %eax
	roll	$16, %eax
	jmp	.L172
.L173:
	movl	16(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -24(%ebp)
	movl	-24(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	movl	%eax, -20(%ebp)
	movl	-24(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, -16(%ebp)
	movl	-20(%ebp), %ecx
	movl	12(%ebp), %eax
	addl	%ecx, %eax
	roll	$16, %eax
	movl	%eax, 12(%ebp)
	movl	-16(%ebp), %ecx
	movl	12(%ebp), %eax
	addl	%ecx, %eax
	roll	$16, %eax
	movl	%eax, 12(%ebp)
	movl	-20(%ebp), %eax
	cmpl	$3, %eax
	je	.L175
	cmpl	$3, %eax
	jg	.L176
	cmpl	$1, %eax
	je	.L177
	jmp	.L174
.L176:
	cmpl	$5, %eax
	je	.L178
	cmpl	$7, %eax
	je	.L179
	jmp	.L174
.L177:
	movl	-24(%ebp), %eax
	addl	$4, %eax
	movl	%eax, -28(%ebp)
	jmp	.L180
.L181:
	movl	-28(%ebp), %eax
	leal	1(%eax), %edx
	movl	%edx, -28(%ebp)
	movzbl	(%eax), %eax
	movsbl	%al, %edx
	movl	12(%ebp), %eax
	addl	%edx, %eax
	sall	$16, %eax
	movl	%eax, %ecx
	movl	-28(%ebp), %eax
	leal	1(%eax), %edx
	movl	%edx, -28(%ebp)
	movzbl	(%eax), %eax
	movsbl	%al, %edx
	movl	12(%ebp), %eax
	addl	%edx, %eax
	shrl	$16, %eax
	orl	%ecx, %eax
	movl	%eax, 12(%ebp)
.L180:
	movl	-28(%ebp), %eax
	movzbl	(%eax), %eax
	testb	%al, %al
	jne	.L181
	movl	12(%ebp), %eax
	jmp	.L172
.L179:
	movl	-24(%ebp), %eax
	addl	$4, %eax
	movl	(%eax), %eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	addl	%edx, %eax
	roll	$16, %eax
	movl	%eax, 12(%ebp)
	movl	$1, -32(%ebp)
	jmp	.L182
.L175:
	movl	$0, -32(%ebp)
	jmp	.L182
.L178:
	movl	16(%ebp), %eax
	subl	$8, %eax
	movl	(%eax), %eax
	movl	%eax, -12(%ebp)
	movl	-12(%ebp), %edx
	movl	12(%ebp), %eax
	addl	%edx, %eax
	roll	$16, %eax
	movl	%eax, 12(%ebp)
	movl	$0, -32(%ebp)
	jmp	.L182
.L174:
	subl	$8, %esp
	pushl	-20(%ebp)
	leal	.LC63@GOTOFF(%edx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L182:
	jmp	.L183
.L184:
	movl	-24(%ebp), %eax
	leal	4(%eax), %edx
	movl	-32(%ebp), %eax
	sall	$2, %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	movl	8(%ebp), %edx
	addl	$1, %edx
	subl	$4, %esp
	pushl	%eax
	pushl	12(%ebp)
	pushl	%edx
	call	inner_hash
	addl	$16, %esp
	movl	%eax, 12(%ebp)
	addl	$1, -32(%ebp)
.L183:
	movl	-32(%ebp), %eax
	cmpl	-16(%ebp), %eax
	jl	.L184
	movl	12(%ebp), %eax
.L172:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE38:
	.size	inner_hash, .-inner_hash
	.globl	Lhash
	.type	Lhash, @function
Lhash:
.LFB39:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	subl	$4, %esp
	pushl	8(%ebp)
	pushl	$0
	pushl	$0
	call	inner_hash
	addl	$16, %esp
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE39:
	.size	Lhash, .-Lhash
	.section	.rodata
	.align 4
.LC64:
	.string	"invalid tag %d in compare *****\n"
	.text
	.globl	Lcompare
	.type	Lcompare, @function
Lcompare:
.LFB40:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$52, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.dx
	addl	$_GLOBAL_OFFSET_TABLE_, %edx
	movl	8(%ebp), %eax
	cmpl	12(%ebp), %eax
	jne	.L188
	movl	$1, %eax
	jmp	.L189
.L188:
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L190
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L191
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	subl	%eax, %edx
	movl	%edx, %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L189
.L191:
	movl	$-1, %eax
	jmp	.L189
.L190:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L192
	movl	$3, %eax
	jmp	.L189
.L192:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -44(%ebp)
	movl	12(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -40(%ebp)
	movl	-44(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	movl	%eax, -36(%ebp)
	movl	-40(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	movl	%eax, -32(%ebp)
	movl	-44(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, -28(%ebp)
	movl	-40(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, -24(%ebp)
	movl	-36(%ebp), %eax
	cmpl	-32(%ebp), %eax
	je	.L193
	movl	-36(%ebp), %eax
	subl	-32(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L189
.L193:
	movl	-36(%ebp), %eax
	cmpl	$3, %eax
	je	.L195
	cmpl	$3, %eax
	jg	.L196
	cmpl	$1, %eax
	je	.L197
	jmp	.L194
.L196:
	cmpl	$5, %eax
	je	.L198
	cmpl	$7, %eax
	je	.L199
	jmp	.L194
.L197:
	movl	-40(%ebp), %eax
	leal	4(%eax), %ecx
	movl	-44(%ebp), %eax
	addl	$4, %eax
	subl	$8, %esp
	pushl	%ecx
	pushl	%eax
	movl	%edx, %ebx
	call	strcmp@PLT
	addl	$16, %esp
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L189
.L199:
	movl	-44(%ebp), %eax
	addl	$4, %eax
	movl	(%eax), %edx
	movl	-40(%ebp), %eax
	addl	$4, %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	je	.L200
	movl	-44(%ebp), %eax
	addl	$4, %eax
	movl	(%eax), %eax
	movl	%eax, %edx
	movl	-40(%ebp), %eax
	addl	$4, %eax
	movl	(%eax), %eax
	subl	%eax, %edx
	movl	%edx, %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L189
.L200:
	movl	-28(%ebp), %eax
	cmpl	-24(%ebp), %eax
	je	.L201
	movl	-28(%ebp), %eax
	subl	-24(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L189
.L201:
	movl	$1, -48(%ebp)
	jmp	.L202
.L195:
	movl	-28(%ebp), %eax
	cmpl	-24(%ebp), %eax
	je	.L203
	movl	-28(%ebp), %eax
	subl	-24(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L189
.L203:
	movl	$0, -48(%ebp)
	jmp	.L202
.L198:
	movl	8(%ebp), %eax
	subl	$8, %eax
	movl	(%eax), %eax
	movl	%eax, -20(%ebp)
	movl	12(%ebp), %eax
	subl	$8, %eax
	movl	(%eax), %eax
	movl	%eax, -16(%ebp)
	movl	-20(%ebp), %eax
	cmpl	-16(%ebp), %eax
	je	.L204
	movl	-20(%ebp), %eax
	subl	-16(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L189
.L204:
	movl	-28(%ebp), %eax
	cmpl	-24(%ebp), %eax
	je	.L205
	movl	-28(%ebp), %eax
	subl	-24(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L189
.L205:
	movl	$0, -48(%ebp)
	jmp	.L202
.L194:
	subl	$8, %esp
	pushl	-36(%ebp)
	leal	.LC64@GOTOFF(%edx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L202:
	jmp	.L206
.L208:
	movl	-40(%ebp), %eax
	leal	4(%eax), %edx
	movl	-48(%ebp), %eax
	sall	$2, %eax
	addl	%edx, %eax
	movl	(%eax), %edx
	movl	-44(%ebp), %eax
	leal	4(%eax), %ecx
	movl	-48(%ebp), %eax
	sall	$2, %eax
	addl	%ecx, %eax
	movl	(%eax), %eax
	subl	$8, %esp
	pushl	%edx
	pushl	%eax
	call	Lcompare
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	cmpl	$1, -12(%ebp)
	je	.L207
	movl	-12(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L189
.L207:
	addl	$1, -48(%ebp)
.L206:
	movl	-48(%ebp), %eax
	cmpl	-28(%ebp), %eax
	jl	.L208
	movl	$1, %eax
.L189:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE40:
	.size	Lcompare, .-Lcompare
	.section	.rodata
.LC65:
	.string	".elem:1"
.LC66:
	.string	".elem:2"
	.text
	.globl	Belem
	.type	Belem, @function
Belem:
.LFB41:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	$1, -12(%ebp)
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L210
	subl	$8, %esp
	leal	.LC65@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC32@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L210:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L211
	subl	$8, %esp
	leal	.LC66@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L211:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -12(%ebp)
	sarl	12(%ebp)
	movl	-12(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	jne	.L212
	movl	-12(%ebp), %edx
	movl	12(%ebp), %eax
	addl	%edx, %eax
	addl	$4, %eax
	movzbl	(%eax), %eax
	movsbl	%al, %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L213
.L212:
	movl	-12(%ebp), %eax
	leal	4(%eax), %edx
	movl	12(%ebp), %eax
	sall	$2, %eax
	addl	%edx, %eax
	movl	(%eax), %eax
.L213:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE41:
	.size	Belem, .-Belem
	.section	.rodata
.LC67:
	.string	"makeArray:1"
	.text
	.globl	LmakeArray
	.type	LmakeArray, @function
LmakeArray:
.LFB42:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L215
	subl	$8, %esp
	leal	.LC67@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L215:
	call	__pre_gc@PLT
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	addl	$1, %eax
	sall	$2, %eax
	subl	$12, %esp
	pushl	%eax
	call	alloc
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	movl	-16(%ebp), %eax
	sall	$3, %eax
	orl	$3, %eax
	movl	%eax, %edx
	movl	-12(%ebp), %eax
	movl	%edx, (%eax)
	call	__post_gc@PLT
	movl	-12(%ebp), %eax
	addl	$4, %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE42:
	.size	LmakeArray, .-LmakeArray
	.section	.rodata
.LC68:
	.string	"makeString"
	.text
	.globl	LmakeString
	.type	LmakeString, @function
LmakeString:
.LFB43:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, -16(%ebp)
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L218
	subl	$8, %esp
	leal	.LC68@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L218:
	call	__pre_gc@PLT
	movl	-16(%ebp), %eax
	addl	$5, %eax
	subl	$12, %esp
	pushl	%eax
	call	alloc
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	movl	-16(%ebp), %eax
	sall	$3, %eax
	orl	$1, %eax
	movl	%eax, %edx
	movl	-12(%ebp), %eax
	movl	%edx, (%eax)
	call	__post_gc@PLT
	movl	-12(%ebp), %eax
	addl	$4, %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE43:
	.size	LmakeString, .-LmakeString
	.globl	Bstring
	.type	Bstring, @function
Bstring:
.LFB44:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	subl	$12, %esp
	pushl	%eax
	call	strlen@PLT
	addl	$16, %esp
	movl	%eax, -16(%ebp)
	movl	$0, -12(%ebp)
	call	__pre_gc@PLT
	subl	$12, %esp
	leal	8(%ebp), %eax
	pushl	%eax
	call	push_extra_root
	addl	$16, %esp
	movl	-16(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	subl	$12, %esp
	pushl	%eax
	call	LmakeString
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	subl	$12, %esp
	leal	8(%ebp), %eax
	pushl	%eax
	call	pop_extra_root
	addl	$16, %esp
	movl	-16(%ebp), %eax
	addl	$1, %eax
	movl	%eax, %edx
	movl	8(%ebp), %eax
	subl	$4, %esp
	pushl	%edx
	pushl	%eax
	pushl	-12(%ebp)
	call	strncpy@PLT
	addl	$16, %esp
	call	__post_gc@PLT
	movl	-12(%ebp), %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE44:
	.size	Bstring, .-Bstring
	.section	.rodata
.LC69:
	.string	"stringcat"
	.text
	.globl	Lstringcat
	.type	Lstringcat, @function
Lstringcat:
.LFB45:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L223
	subl	$8, %esp
	leal	.LC69@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC32@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L223:
	call	__pre_gc@PLT
	call	createStringBuf
	subl	$12, %esp
	pushl	8(%ebp)
	call	stringcat
	addl	$16, %esp
	movl	stringBuf@GOTOFF(%ebx), %eax
	subl	$12, %esp
	pushl	%eax
	call	Bstring
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	call	deleteStringBuf
	call	__post_gc@PLT
	movl	-12(%ebp), %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE45:
	.size	Lstringcat, .-Lstringcat
	.globl	Bstringval
	.type	Bstringval, @function
Bstringval:
.LFB46:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	$1, -12(%ebp)
	call	__pre_gc@PLT
	call	createStringBuf
	subl	$12, %esp
	pushl	8(%ebp)
	call	printValue
	addl	$16, %esp
	movl	stringBuf@GOTOFF(%ebx), %eax
	subl	$12, %esp
	pushl	%eax
	call	Bstring
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	call	deleteStringBuf
	call	__post_gc@PLT
	movl	-12(%ebp), %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE46:
	.size	Bstringval, .-Bstringval
	.globl	Bclosure
	.type	Bclosure, @function
Bclosure:
.LFB47:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$52, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	12(%ebp), %eax
	movl	%eax, -44(%ebp)
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	movl	$1, -28(%ebp)
	movl	$1, -24(%ebp)
	movl	$1, -20(%ebp)
	movl	$1, -16(%ebp)
	call	__pre_gc@PLT
	movl	8(%ebp), %eax
	addl	$2, %eax
	sall	$2, %eax
	subl	$12, %esp
	pushl	%eax
	call	alloc
	addl	$16, %esp
	movl	%eax, -16(%ebp)
	movl	8(%ebp), %eax
	addl	$1, %eax
	sall	$3, %eax
	orl	$7, %eax
	movl	%eax, %edx
	movl	-16(%ebp), %eax
	movl	%edx, (%eax)
	movl	-16(%ebp), %eax
	leal	4(%eax), %edx
	movl	-44(%ebp), %eax
	movl	%eax, (%edx)
	leal	16(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	$0, -24(%ebp)
	jmp	.L228
.L229:
	movl	-28(%ebp), %eax
	leal	4(%eax), %edx
	movl	%edx, -28(%ebp)
	movl	(%eax), %eax
	movl	%eax, -20(%ebp)
	movl	-16(%ebp), %eax
	leal	4(%eax), %edx
	movl	-24(%ebp), %eax
	addl	$1, %eax
	sall	$2, %eax
	addl	%eax, %edx
	movl	-20(%ebp), %eax
	movl	%eax, (%edx)
	addl	$1, -24(%ebp)
.L228:
	movl	-24(%ebp), %eax
	cmpl	8(%ebp), %eax
	jl	.L229
	call	__post_gc@PLT
	movl	-16(%ebp), %eax
	addl	$4, %eax
	movl	-12(%ebp), %ecx
	xorl	%gs:20, %ecx
	je	.L231
	call	__stack_chk_fail_local
.L231:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE47:
	.size	Bclosure, .-Bclosure
	.globl	Barray
	.type	Barray, @function
Barray:
.LFB48:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$36, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	movl	$1, -28(%ebp)
	movl	$1, -24(%ebp)
	movl	$1, -20(%ebp)
	movl	$1, -16(%ebp)
	call	__pre_gc@PLT
	movl	8(%ebp), %eax
	addl	$1, %eax
	sall	$2, %eax
	subl	$12, %esp
	pushl	%eax
	call	alloc
	addl	$16, %esp
	movl	%eax, -16(%ebp)
	movl	8(%ebp), %eax
	sall	$3, %eax
	orl	$3, %eax
	movl	%eax, %edx
	movl	-16(%ebp), %eax
	movl	%edx, (%eax)
	leal	12(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	$0, -24(%ebp)
	jmp	.L233
.L234:
	movl	-28(%ebp), %eax
	leal	4(%eax), %edx
	movl	%edx, -28(%ebp)
	movl	(%eax), %eax
	movl	%eax, -20(%ebp)
	movl	-16(%ebp), %eax
	leal	4(%eax), %edx
	movl	-24(%ebp), %eax
	sall	$2, %eax
	addl	%eax, %edx
	movl	-20(%ebp), %eax
	movl	%eax, (%edx)
	addl	$1, -24(%ebp)
.L233:
	movl	-24(%ebp), %eax
	cmpl	8(%ebp), %eax
	jl	.L234
	call	__post_gc@PLT
	movl	-16(%ebp), %eax
	addl	$4, %eax
	movl	-12(%ebp), %ecx
	xorl	%gs:20, %ecx
	je	.L236
	call	__stack_chk_fail_local
.L236:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE48:
	.size	Barray, .-Barray
	.globl	Bsexp
	.type	Bsexp, @function
Bsexp:
.LFB49:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$36, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	movl	$1, -36(%ebp)
	movl	$1, -32(%ebp)
	movl	$1, -28(%ebp)
	movl	$0, -24(%ebp)
	movl	$1, -20(%ebp)
	movl	$1, -16(%ebp)
	call	__pre_gc@PLT
	movl	8(%ebp), %eax
	addl	$1, %eax
	sall	$2, %eax
	subl	$12, %esp
	pushl	%eax
	call	alloc
	addl	$16, %esp
	movl	%eax, -20(%ebp)
	movl	-20(%ebp), %eax
	addl	$4, %eax
	movl	%eax, -16(%ebp)
	movl	-20(%ebp), %eax
	movl	$0, (%eax)
	movl	8(%ebp), %eax
	subl	$1, %eax
	sall	$3, %eax
	orl	$5, %eax
	movl	%eax, %edx
	movl	-16(%ebp), %eax
	movl	%edx, (%eax)
	leal	12(%ebp), %eax
	movl	%eax, -36(%ebp)
	movl	$0, -32(%ebp)
	jmp	.L238
.L239:
	movl	-36(%ebp), %eax
	leal	4(%eax), %edx
	movl	%edx, -36(%ebp)
	movl	(%eax), %eax
	movl	%eax, -28(%ebp)
	movl	-28(%ebp), %eax
	movl	%eax, -24(%ebp)
	movl	-16(%ebp), %eax
	leal	4(%eax), %edx
	movl	-32(%ebp), %eax
	sall	$2, %eax
	addl	%eax, %edx
	movl	-28(%ebp), %eax
	movl	%eax, (%edx)
	addl	$1, -32(%ebp)
.L238:
	movl	8(%ebp), %eax
	subl	$1, %eax
	cmpl	%eax, -32(%ebp)
	jl	.L239
	movl	-36(%ebp), %eax
	leal	4(%eax), %edx
	movl	%edx, -36(%ebp)
	movl	(%eax), %edx
	movl	-20(%ebp), %eax
	movl	%edx, (%eax)
	call	__post_gc@PLT
	movl	-16(%ebp), %eax
	addl	$4, %eax
	movl	-12(%ebp), %ecx
	xorl	%gs:20, %ecx
	je	.L241
	call	__stack_chk_fail_local
.L241:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE49:
	.size	Bsexp, .-Bsexp
	.globl	Btag
	.type	Btag, @function
Btag:
.LFB50:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$16, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	$1, -4(%ebp)
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L243
	movl	$1, %eax
	jmp	.L244
.L243:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -4(%ebp)
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$5, %eax
	jne	.L245
	movl	8(%ebp), %eax
	subl	$8, %eax
	movl	(%eax), %eax
	cmpl	%eax, 12(%ebp)
	jne	.L245
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	16(%ebp), %eax
	cmpl	%eax, %edx
	jne	.L245
	movl	$1, %eax
	jmp	.L246
.L245:
	movl	$0, %eax
.L246:
	addl	%eax, %eax
	orl	$1, %eax
.L244:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE50:
	.size	Btag, .-Btag
	.globl	Barray_patt
	.type	Barray_patt, @function
Barray_patt:
.LFB51:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$16, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	$1, -4(%ebp)
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L248
	movl	$1, %eax
	jmp	.L249
.L248:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -4(%ebp)
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$3, %eax
	jne	.L250
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	cmpl	%eax, %edx
	jne	.L250
	movl	$1, %eax
	jmp	.L251
.L250:
	movl	$0, %eax
.L251:
	addl	%eax, %eax
	orl	$1, %eax
.L249:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE51:
	.size	Barray_patt, .-Barray_patt
	.section	.rodata
.LC70:
	.string	".string_patt:2"
	.text
	.globl	Bstring_patt
	.type	Bstring_patt, @function
Bstring_patt:
.LFB52:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	$1, -16(%ebp)
	movl	$1, -12(%ebp)
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L253
	movl	12(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L253
	subl	$8, %esp
	leal	.LC70@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L253:
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L254
	movl	$1, %eax
	jmp	.L255
.L254:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -16(%ebp)
	movl	12(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -12(%ebp)
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L256
	movl	$1, %eax
	jmp	.L255
.L256:
	movl	-12(%ebp), %eax
	leal	4(%eax), %edx
	movl	-16(%ebp), %eax
	addl	$4, %eax
	subl	$8, %esp
	pushl	%edx
	pushl	%eax
	call	strcmp@PLT
	addl	$16, %esp
	testl	%eax, %eax
	jne	.L257
	movl	$3, %eax
	jmp	.L255
.L257:
	movl	$1, %eax
.L255:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE52:
	.size	Bstring_patt, .-Bstring_patt
	.globl	Bclosure_tag_patt
	.type	Bclosure_tag_patt, @function
Bclosure_tag_patt:
.LFB53:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L260
	movl	$1, %eax
	jmp	.L261
.L260:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$7, %eax
	jne	.L262
	movl	$3, %eax
	jmp	.L261
.L262:
	movl	$1, %eax
.L261:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE53:
	.size	Bclosure_tag_patt, .-Bclosure_tag_patt
	.globl	Bboxed_patt
	.type	Bboxed_patt, @function
Bboxed_patt:
.LFB54:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L265
	movl	$3, %eax
	jmp	.L267
.L265:
	movl	$1, %eax
.L267:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE54:
	.size	Bboxed_patt, .-Bboxed_patt
	.globl	Bunboxed_patt
	.type	Bunboxed_patt, @function
Bunboxed_patt:
.LFB55:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %eax
	addl	%eax, %eax
	andl	$2, %eax
	orl	$1, %eax
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE55:
	.size	Bunboxed_patt, .-Bunboxed_patt
	.globl	Barray_tag_patt
	.type	Barray_tag_patt, @function
Barray_tag_patt:
.LFB56:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L271
	movl	$1, %eax
	jmp	.L272
.L271:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$3, %eax
	jne	.L273
	movl	$3, %eax
	jmp	.L272
.L273:
	movl	$1, %eax
.L272:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE56:
	.size	Barray_tag_patt, .-Barray_tag_patt
	.globl	Bstring_tag_patt
	.type	Bstring_tag_patt, @function
Bstring_tag_patt:
.LFB57:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L276
	movl	$1, %eax
	jmp	.L277
.L276:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	jne	.L278
	movl	$3, %eax
	jmp	.L277
.L278:
	movl	$1, %eax
.L277:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE57:
	.size	Bstring_tag_patt, .-Bstring_tag_patt
	.globl	Bsexp_tag_patt
	.type	Bsexp_tag_patt, @function
Bsexp_tag_patt:
.LFB58:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L281
	movl	$1, %eax
	jmp	.L282
.L281:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$5, %eax
	jne	.L283
	movl	$3, %eax
	jmp	.L282
.L283:
	movl	$1, %eax
.L282:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE58:
	.size	Bsexp_tag_patt, .-Bsexp_tag_patt
	.section	.rodata
.LC71:
	.string	".sta:3"
.LC72:
	.string	".sta:2"
	.text
	.globl	Bsta
	.type	Bsta, @function
Bsta:
.LFB59:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	16(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L286
	subl	$8, %esp
	leal	.LC71@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC32@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L286:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L287
	subl	$8, %esp
	leal	.LC72@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L287:
	movl	16(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	jne	.L288
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	movl	%eax, %ecx
	movl	16(%ebp), %eax
	addl	%ecx, %eax
	movb	%dl, (%eax)
	jmp	.L289
.L288:
	movl	12(%ebp), %eax
	sarl	%eax
	leal	0(,%eax,4), %edx
	movl	16(%ebp), %eax
	addl	%eax, %edx
	movl	8(%ebp), %eax
	movl	%eax, (%edx)
.L289:
	movl	8(%ebp), %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE59:
	.size	Bsta, .-Bsta
	.type	fix_unboxed, @function
fix_unboxed:
.LFB60:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$16, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	12(%ebp), %eax
	movl	%eax, -8(%ebp)
	movl	$0, -12(%ebp)
	jmp	.L292
.L295:
	movl	8(%ebp), %eax
	movzbl	(%eax), %eax
	cmpb	$37, %al
	jne	.L293
	movl	-12(%ebp), %eax
	leal	0(,%eax,4), %edx
	movl	-8(%ebp), %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	movl	%eax, -4(%ebp)
	movl	-4(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L294
	movl	-4(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	-12(%ebp), %eax
	leal	0(,%eax,4), %ecx
	movl	-8(%ebp), %eax
	addl	%ecx, %eax
	movl	%edx, (%eax)
.L294:
	addl	$1, -12(%ebp)
.L293:
	addl	$1, 8(%ebp)
.L292:
	movl	8(%ebp), %eax
	movzbl	(%eax), %eax
	testb	%al, %al
	jne	.L295
	nop
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE60:
	.size	fix_unboxed, .-fix_unboxed
	.globl	Lfailure
	.type	Lfailure, @function
Lfailure:
.LFB61:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$40, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	leal	12(%ebp), %eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	pushl	%eax
	pushl	-28(%ebp)
	call	fix_unboxed
	addl	$8, %esp
	movl	-16(%ebp), %eax
	subl	$8, %esp
	pushl	%eax
	pushl	-28(%ebp)
	call	vfailure
	addl	$16, %esp
	nop
	movl	-12(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L297
	call	__stack_chk_fail_local
.L297:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE61:
	.size	Lfailure, .-Lfailure
	.section	.rodata
	.align 4
.LC73:
	.string	"match failure at %s:%d:%d, value '%s'\n"
	.text
	.globl	Bmatch_failure
	.type	Bmatch_failure, @function
Bmatch_failure:
.LFB62:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	call	createStringBuf
	subl	$12, %esp
	pushl	8(%ebp)
	call	printValue
	addl	$16, %esp
	movl	stringBuf@GOTOFF(%ebx), %eax
	subl	$12, %esp
	pushl	%eax
	pushl	20(%ebp)
	pushl	16(%ebp)
	pushl	12(%ebp)
	leal	.LC73@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$32, %esp
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE62:
	.size	Bmatch_failure, .-Bmatch_failure
	.section	.rodata
.LC74:
	.string	"++:1"
.LC75:
	.string	"++:2"
	.text
	.globl	Li__Infix_4343
	.type	Li__Infix_4343, @function
Li__Infix_4343:
.LFB63:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%esi
	pushl	%ebx
	subl	$16, %esp
	.cfi_offset 6, -12
	.cfi_offset 3, -16
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	$1, -20(%ebp)
	movl	$1, -16(%ebp)
	movl	$1, -12(%ebp)
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L300
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L300
	subl	$8, %esp
	leal	.LC74@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L300:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L301
	movl	12(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L301
	subl	$8, %esp
	leal	.LC75@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L301:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -20(%ebp)
	movl	12(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -16(%ebp)
	call	__pre_gc@PLT
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	addl	%edx, %eax
	addl	$5, %eax
	subl	$12, %esp
	pushl	%eax
	call	alloc
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	addl	%edx, %eax
	sall	$3, %eax
	orl	$1, %eax
	movl	%eax, %edx
	movl	-12(%ebp), %eax
	movl	%edx, (%eax)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %ecx
	movl	-20(%ebp), %eax
	leal	4(%eax), %edx
	movl	-12(%ebp), %eax
	addl	$4, %eax
	subl	$4, %esp
	pushl	%ecx
	pushl	%edx
	pushl	%eax
	call	strncpy@PLT
	addl	$16, %esp
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %ecx
	movl	-16(%ebp), %eax
	leal	4(%eax), %edx
	movl	-12(%ebp), %eax
	leal	4(%eax), %esi
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	addl	%esi, %eax
	subl	$4, %esp
	pushl	%ecx
	pushl	%edx
	pushl	%eax
	call	strncpy@PLT
	addl	$16, %esp
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	addl	%eax, %edx
	movl	-12(%ebp), %eax
	movb	$0, 4(%eax,%edx)
	call	__post_gc@PLT
	movl	-12(%ebp), %eax
	addl	$4, %eax
	leal	-8(%ebp), %esp
	popl	%ebx
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE63:
	.size	Li__Infix_4343, .-Li__Infix_4343
	.section	.rodata
.LC76:
	.string	"sprintf:1"
	.text
	.globl	Lsprintf
	.type	Lsprintf, @function
Lsprintf:
.LFB64:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$36, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	movl	-28(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L304
	movl	-28(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L304
	subl	$8, %esp
	leal	.LC76@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L304:
	leal	12(%ebp), %eax
	movl	%eax, -20(%ebp)
	movl	-20(%ebp), %eax
	subl	$8, %esp
	pushl	%eax
	pushl	-28(%ebp)
	call	fix_unboxed
	addl	$16, %esp
	call	createStringBuf
	movl	-20(%ebp), %eax
	subl	$8, %esp
	pushl	%eax
	pushl	-28(%ebp)
	call	vprintStringBuf
	addl	$16, %esp
	call	__pre_gc@PLT
	movl	stringBuf@GOTOFF(%ebx), %eax
	subl	$12, %esp
	pushl	%eax
	call	Bstring
	addl	$16, %esp
	movl	%eax, -16(%ebp)
	call	__post_gc@PLT
	call	deleteStringBuf
	movl	-16(%ebp), %eax
	movl	-12(%ebp), %edx
	xorl	%gs:20, %edx
	je	.L306
	call	__stack_chk_fail_local
.L306:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE64:
	.size	Lsprintf, .-Lsprintf
	.section	.rodata
.LC77:
	.string	"fprintf:1"
.LC78:
	.string	"fprintf:2"
.LC79:
	.string	"fprintf (...): %s\n"
	.text
	.globl	Lfprintf
	.type	Lfprintf, @function
Lfprintf:
.LFB65:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$36, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	12(%ebp), %eax
	movl	%eax, -32(%ebp)
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	movl	$1, -16(%ebp)
	movl	-28(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L308
	subl	$8, %esp
	leal	.LC77@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC32@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L308:
	movl	-32(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L309
	movl	-32(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L309
	subl	$8, %esp
	leal	.LC78@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L309:
	leal	16(%ebp), %eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	subl	$8, %esp
	pushl	%eax
	pushl	-32(%ebp)
	call	fix_unboxed
	addl	$16, %esp
	movl	-16(%ebp), %eax
	subl	$4, %esp
	pushl	%eax
	pushl	-32(%ebp)
	pushl	-28(%ebp)
	call	vfprintf@PLT
	addl	$16, %esp
	testl	%eax, %eax
	jns	.L312
	call	__errno_location@PLT
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	strerror@PLT
	addl	$16, %esp
	subl	$8, %esp
	pushl	%eax
	leal	.LC79@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L312:
	nop
	movl	-12(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L311
	call	__stack_chk_fail_local
.L311:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE65:
	.size	Lfprintf, .-Lfprintf
	.section	.rodata
.LC80:
	.string	"printf:1"
	.text
	.globl	Lprintf
	.type	Lprintf, @function
Lprintf:
.LFB66:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$36, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	movl	$1, -16(%ebp)
	movl	-28(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L314
	movl	-28(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L314
	subl	$8, %esp
	leal	.LC80@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L314:
	leal	12(%ebp), %eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	subl	$8, %esp
	pushl	%eax
	pushl	-28(%ebp)
	call	fix_unboxed
	addl	$16, %esp
	movl	-16(%ebp), %eax
	subl	$8, %esp
	pushl	%eax
	pushl	-28(%ebp)
	call	vprintf@PLT
	addl	$16, %esp
	testl	%eax, %eax
	jns	.L315
	call	__errno_location@PLT
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	strerror@PLT
	addl	$16, %esp
	subl	$8, %esp
	pushl	%eax
	leal	.LC79@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L315:
	movl	stdout@GOT(%ebx), %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	fflush@PLT
	addl	$16, %esp
	nop
	movl	-12(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L316
	call	__stack_chk_fail_local
.L316:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE66:
	.size	Lprintf, .-Lprintf
	.section	.rodata
.LC81:
	.string	"fopen:1"
.LC82:
	.string	"fopen:2"
	.align 4
.LC83:
	.string	"fopen (\"%s\", \"%s\"): %s, %s, %s\n"
	.text
	.globl	Lfopen
	.type	Lfopen, @function
Lfopen:
.LFB67:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L318
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L318
	subl	$8, %esp
	leal	.LC81@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L318:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L319
	movl	12(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L319
	subl	$8, %esp
	leal	.LC82@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L319:
	subl	$8, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	fopen@PLT
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	cmpl	$0, -12(%ebp)
	je	.L320
	movl	-12(%ebp), %eax
	jmp	.L317
.L320:
	call	__errno_location@PLT
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	strerror@PLT
	addl	$16, %esp
	pushl	%eax
	pushl	12(%ebp)
	pushl	8(%ebp)
	leal	.LC83@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L317:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE67:
	.size	Lfopen, .-Lfopen
	.section	.rodata
.LC84:
	.string	"fclose"
	.text
	.globl	Lfclose
	.type	Lfclose, @function
Lfclose:
.LFB68:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L323
	subl	$8, %esp
	leal	.LC84@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC32@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L323:
	subl	$12, %esp
	pushl	8(%ebp)
	call	fclose@PLT
	addl	$16, %esp
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE68:
	.size	Lfclose, .-Lfclose
	.section	.rodata
.LC85:
	.string	"%m[^\n]"
.LC86:
	.string	"readLine (): %s\n"
	.text
	.globl	LreadLine
	.type	LreadLine, @function
LreadLine:
.LFB69:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	subl	$8, %esp
	leal	-20(%ebp), %eax
	pushl	%eax
	leal	.LC85@GOTOFF(%ebx), %eax
	pushl	%eax
	call	__isoc99_scanf@PLT
	addl	$16, %esp
	cmpl	$1, %eax
	jne	.L325
	movl	-20(%ebp), %eax
	subl	$12, %esp
	pushl	%eax
	call	Bstring
	addl	$16, %esp
	movl	%eax, -16(%ebp)
	movl	-20(%ebp), %eax
	subl	$12, %esp
	pushl	%eax
	call	free@PLT
	addl	$16, %esp
	movl	-16(%ebp), %eax
	jmp	.L328
.L325:
	call	__errno_location@PLT
	movl	(%eax), %eax
	testl	%eax, %eax
	je	.L327
	call	__errno_location@PLT
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	strerror@PLT
	addl	$16, %esp
	subl	$8, %esp
	pushl	%eax
	leal	.LC86@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L327:
	subl	$12, %esp
	pushl	$0
	call	LmakeString
	addl	$16, %esp
.L328:
	movl	-12(%ebp), %edx
	xorl	%gs:20, %edx
	je	.L329
	call	__stack_chk_fail_local
.L329:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE69:
	.size	LreadLine, .-LreadLine
	.section	.rodata
.LC87:
	.string	"fread"
.LC88:
	.string	"r"
.LC89:
	.string	"fread (\"%s\"): %s\n"
	.text
	.globl	Lfread
	.type	Lfread, @function
Lfread:
.LFB70:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L331
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L331
	subl	$8, %esp
	leal	.LC87@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L331:
	subl	$8, %esp
	leal	.LC88@GOTOFF(%ebx), %eax
	pushl	%eax
	pushl	8(%ebp)
	call	fopen@PLT
	addl	$16, %esp
	movl	%eax, -20(%ebp)
	cmpl	$0, -20(%ebp)
	je	.L332
	subl	$4, %esp
	pushl	$2
	pushl	$0
	pushl	-20(%ebp)
	call	fseek@PLT
	addl	$16, %esp
	testl	%eax, %eax
	js	.L332
	subl	$12, %esp
	pushl	-20(%ebp)
	call	ftell@PLT
	addl	$16, %esp
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	subl	$12, %esp
	pushl	%eax
	call	LmakeString
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	subl	$12, %esp
	pushl	-20(%ebp)
	call	rewind@PLT
	addl	$16, %esp
	movl	-16(%ebp), %eax
	pushl	-20(%ebp)
	pushl	%eax
	pushl	$1
	pushl	-12(%ebp)
	call	fread@PLT
	addl	$16, %esp
	movl	%eax, %edx
	movl	-16(%ebp), %eax
	cmpl	%eax, %edx
	jne	.L332
	subl	$12, %esp
	pushl	-20(%ebp)
	call	fclose@PLT
	addl	$16, %esp
	movl	-12(%ebp), %eax
	jmp	.L330
.L332:
	call	__errno_location@PLT
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	strerror@PLT
	addl	$16, %esp
	subl	$4, %esp
	pushl	%eax
	pushl	8(%ebp)
	leal	.LC89@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L330:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE70:
	.size	Lfread, .-Lfread
	.section	.rodata
.LC90:
	.string	"fwrite:1"
.LC91:
	.string	"fwrite:2"
.LC92:
	.string	"w"
.LC93:
	.string	"fwrite (\"%s\"): %s\n"
	.text
	.globl	Lfwrite
	.type	Lfwrite, @function
Lfwrite:
.LFB71:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L335
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L335
	subl	$8, %esp
	leal	.LC90@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L335:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L336
	movl	12(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	je	.L336
	subl	$8, %esp
	leal	.LC91@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC51@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L336:
	subl	$8, %esp
	leal	.LC92@GOTOFF(%ebx), %eax
	pushl	%eax
	pushl	8(%ebp)
	call	fopen@PLT
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	cmpl	$0, -12(%ebp)
	je	.L337
	subl	$4, %esp
	pushl	12(%ebp)
	leal	.LC45@GOTOFF(%ebx), %eax
	pushl	%eax
	pushl	-12(%ebp)
	call	fprintf@PLT
	addl	$16, %esp
	testl	%eax, %eax
	js	.L337
	subl	$12, %esp
	pushl	-12(%ebp)
	call	fclose@PLT
	addl	$16, %esp
	jmp	.L334
.L337:
	call	__errno_location@PLT
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	strerror@PLT
	addl	$16, %esp
	subl	$4, %esp
	pushl	%eax
	pushl	8(%ebp)
	leal	.LC93@GOTOFF(%ebx), %eax
	pushl	%eax
	call	failure
	addl	$16, %esp
.L334:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE71:
	.size	Lfwrite, .-Lfwrite
	.globl	Lfst
	.type	Lfst, @function
Lfst:
.LFB72:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	subl	$8, %esp
	pushl	$1
	pushl	8(%ebp)
	call	Belem
	addl	$16, %esp
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE72:
	.size	Lfst, .-Lfst
	.globl	Lsnd
	.type	Lsnd, @function
Lsnd:
.LFB73:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	subl	$8, %esp
	pushl	$3
	pushl	8(%ebp)
	call	Belem
	addl	$16, %esp
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE73:
	.size	Lsnd, .-Lsnd
	.globl	Lhd
	.type	Lhd, @function
Lhd:
.LFB74:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	subl	$8, %esp
	pushl	$1
	pushl	8(%ebp)
	call	Belem
	addl	$16, %esp
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE74:
	.size	Lhd, .-Lhd
	.globl	Ltl
	.type	Ltl, @function
Ltl:
.LFB75:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	subl	$8, %esp
	pushl	$3
	pushl	8(%ebp)
	call	Belem
	addl	$16, %esp
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE75:
	.size	Ltl, .-Ltl
	.section	.rodata
.LC94:
	.string	"> "
	.text
	.globl	Lread
	.type	Lread, @function
Lread:
.LFB76:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	movl	$1, -16(%ebp)
	subl	$12, %esp
	leal	.LC94@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printf@PLT
	addl	$16, %esp
	movl	stdout@GOT(%ebx), %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	fflush@PLT
	addl	$16, %esp
	subl	$8, %esp
	leal	-16(%ebp), %eax
	pushl	%eax
	leal	.LC34@GOTOFF(%ebx), %eax
	pushl	%eax
	call	__isoc99_scanf@PLT
	addl	$16, %esp
	movl	-16(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	movl	-12(%ebp), %edx
	xorl	%gs:20, %edx
	je	.L349
	call	__stack_chk_fail_local
.L349:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE76:
	.size	Lread, .-Lread
	.section	.rodata
.LC95:
	.string	"%d\n"
	.text
	.globl	Lwrite
	.type	Lwrite, @function
Lwrite:
.LFB77:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	sarl	%eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC95@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printf@PLT
	addl	$16, %esp
	movl	stdout@GOT(%ebx), %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	fflush@PLT
	addl	$16, %esp
	movl	$0, %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE77:
	.size	Lwrite, .-Lwrite
	.globl	set_args
	.type	set_args, @function
set_args:
.LFB78:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$36, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	12(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	movl	8(%ebp), %eax
	movl	%eax, -16(%ebp)
	movl	$0, -24(%ebp)
	call	__pre_gc@PLT
	movl	-16(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	subl	$12, %esp
	pushl	%eax
	call	LmakeArray
	addl	$16, %esp
	movl	%eax, -24(%ebp)
	subl	$12, %esp
	leal	-24(%ebp), %eax
	pushl	%eax
	call	push_extra_root
	addl	$16, %esp
	movl	$0, -20(%ebp)
	jmp	.L353
.L354:
	movl	-20(%ebp), %eax
	leal	0(,%eax,4), %edx
	movl	-28(%ebp), %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	Bstring
	addl	$16, %esp
	movl	%eax, %ecx
	movl	-24(%ebp), %eax
	movl	-20(%ebp), %edx
	sall	$2, %edx
	addl	%edx, %eax
	movl	%ecx, %edx
	movl	%edx, (%eax)
	addl	$1, -20(%ebp)
.L353:
	movl	-20(%ebp), %eax
	cmpl	-16(%ebp), %eax
	jl	.L354
	subl	$12, %esp
	leal	-24(%ebp), %eax
	pushl	%eax
	call	pop_extra_root
	addl	$16, %esp
	call	__post_gc@PLT
	movl	-24(%ebp), %edx
	movl	global_sysargs@GOT(%ebx), %eax
	movl	%edx, (%eax)
	subl	$12, %esp
	movl	global_sysargs@GOT(%ebx), %eax
	pushl	%eax
	call	push_extra_root
	addl	$16, %esp
	nop
	movl	-12(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L355
	call	__stack_chk_fail_local
.L355:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE78:
	.size	set_args, .-set_args
	.data
	.align 4
	.type	SPACE_SIZE, @object
	.size	SPACE_SIZE, 4
SPACE_SIZE:
	.long	16384
	.text
	.type	free_pool, @function
free_pool:
.LFB79:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %edx
	movl	(%edx), %edx
	movl	%edx, -16(%ebp)
	movl	8(%ebp), %edx
	movl	12(%edx), %edx
	movl	%edx, -12(%ebp)
	movl	8(%ebp), %edx
	movl	$0, (%edx)
	movl	8(%ebp), %edx
	movl	$0, 12(%edx)
	movl	8(%ebp), %edx
	movl	$0, 4(%edx)
	movl	8(%ebp), %edx
	movl	$0, 8(%edx)
	subl	$8, %esp
	pushl	-12(%ebp)
	pushl	-16(%ebp)
	movl	%eax, %ebx
	call	munmap@PLT
	addl	$16, %esp
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE79:
	.size	free_pool, .-free_pool
	.section	.rodata
	.align 4
.LC96:
	.string	"EROOR: init_to_space: mmap failed\n"
	.text
	.type	init_to_space, @function
init_to_space:
.LFB80:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	$0, -12(%ebp)
	cmpl	$0, 8(%ebp)
	je	.L359
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	addl	%eax, %eax
	movl	%eax, SPACE_SIZE@GOTOFF(%ebx)
.L359:
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	sall	$2, %eax
	movl	%eax, -12(%ebp)
	subl	$8, %esp
	pushl	$0
	pushl	$-1
	pushl	$98
	pushl	$3
	pushl	-12(%ebp)
	pushl	$0
	call	mmap@PLT
	addl	$32, %esp
	movl	%eax, to_space@GOTOFF(%ebx)
	movl	to_space@GOTOFF(%ebx), %eax
	cmpl	$-1, %eax
	jne	.L360
	subl	$12, %esp
	leal	.LC96@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L360:
	movl	to_space@GOTOFF(%ebx), %eax
	movl	%eax, 8+to_space@GOTOFF(%ebx)
	movl	to_space@GOTOFF(%ebx), %eax
	movl	SPACE_SIZE@GOTOFF(%ebx), %edx
	sall	$2, %edx
	addl	%edx, %eax
	movl	%eax, 4+to_space@GOTOFF(%ebx)
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	movl	%eax, 12+to_space@GOTOFF(%ebx)
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE80:
	.size	init_to_space, .-init_to_space
	.type	gc_swap_spaces, @function
gc_swap_spaces:
.LFB81:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	subl	$12, %esp
	leal	from_space@GOTOFF(%ebx), %eax
	pushl	%eax
	call	free_pool
	addl	$16, %esp
	movl	to_space@GOTOFF(%ebx), %eax
	movl	%eax, from_space@GOTOFF(%ebx)
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	movl	%eax, 8+from_space@GOTOFF(%ebx)
	movl	4+to_space@GOTOFF(%ebx), %eax
	movl	%eax, 4+from_space@GOTOFF(%ebx)
	movl	12+to_space@GOTOFF(%ebx), %eax
	movl	%eax, 12+from_space@GOTOFF(%ebx)
	movl	$0, to_space@GOTOFF(%ebx)
	movl	$0, 8+to_space@GOTOFF(%ebx)
	movl	$0, 4+to_space@GOTOFF(%ebx)
	movl	$0, 12+to_space@GOTOFF(%ebx)
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE81:
	.size	gc_swap_spaces, .-gc_swap_spaces
	.type	copy_elements, @function
copy_elements:
.LFB82:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	$0, -20(%ebp)
	movl	$0, -16(%ebp)
	movl	$0, -20(%ebp)
	jmp	.L363
.L367:
	movl	-20(%ebp), %eax
	leal	0(,%eax,4), %edx
	movl	12(%ebp), %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	movl	%eax, -12(%ebp)
	movl	-12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L364
	movl	from_space@GOTOFF(%ebx), %edx
	movl	-12(%ebp), %eax
	cmpl	%eax, %edx
	ja	.L364
	movl	4+from_space@GOTOFF(%ebx), %edx
	movl	-12(%ebp), %eax
	cmpl	%eax, %edx
	ja	.L365
.L364:
	movl	8(%ebp), %eax
	movl	-12(%ebp), %edx
	movl	%edx, (%eax)
	addl	$4, 8(%ebp)
	jmp	.L366
.L365:
	movl	-12(%ebp), %eax
	subl	$12, %esp
	pushl	%eax
	call	gc_copy
	addl	$16, %esp
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %edx
	movl	8(%ebp), %eax
	movl	%edx, (%eax)
	addl	$4, 8(%ebp)
.L366:
	addl	$1, -20(%ebp)
.L363:
	movl	-20(%ebp), %eax
	cmpl	16(%ebp), %eax
	jl	.L367
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE82:
	.size	copy_elements, .-copy_elements
	.type	extend_spaces, @function
extend_spaces:
.LFB83:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	$1, -20(%ebp)
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	sall	$2, %eax
	movl	%eax, -16(%ebp)
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	sall	$3, %eax
	movl	%eax, -12(%ebp)
	movl	to_space@GOTOFF(%ebx), %eax
	pushl	$0
	pushl	-12(%ebp)
	pushl	-16(%ebp)
	pushl	%eax
	call	mremap@PLT
	addl	$16, %esp
	movl	%eax, -20(%ebp)
	cmpl	$-1, -20(%ebp)
	jne	.L369
	movl	$1, %eax
	jmp	.L370
.L369:
	movl	4+to_space@GOTOFF(%ebx), %eax
	movl	SPACE_SIZE@GOTOFF(%ebx), %edx
	sall	$2, %edx
	addl	%edx, %eax
	movl	%eax, 4+to_space@GOTOFF(%ebx)
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	addl	%eax, %eax
	movl	%eax, SPACE_SIZE@GOTOFF(%ebx)
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	movl	%eax, 12+to_space@GOTOFF(%ebx)
	movl	$0, %eax
.L370:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE83:
	.size	extend_spaces, .-extend_spaces
	.section	.rodata
.LC97:
	.string	"ERROR: gc_copy: out-of-space\n"
.LC98:
	.string	"ERROR: gc_copy: weird tag"
	.text
	.globl	gc_copy
	.type	gc_copy, @function
gc_copy:
.LFB84:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -20(%ebp)
	movl	$0, -16(%ebp)
	movl	$0, -24(%ebp)
	movl	$0, -12(%ebp)
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L372
	movl	from_space@GOTOFF(%ebx), %eax
	cmpl	%eax, 8(%ebp)
	jb	.L372
	movl	4+from_space@GOTOFF(%ebx), %eax
	cmpl	%eax, 8(%ebp)
	jb	.L373
.L372:
	movl	8(%ebp), %eax
	jmp	.L374
.L373:
	movl	to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L375
	movl	4+to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L376
.L375:
	movl	4+to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	je	.L376
	subl	$12, %esp
	leal	.LC97@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L376:
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L377
	movl	to_space@GOTOFF(%ebx), %edx
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L377
	movl	4+to_space@GOTOFF(%ebx), %edx
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	jbe	.L377
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	jmp	.L374
.L377:
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	movl	%eax, -24(%ebp)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$3, %eax
	je	.L379
	cmpl	$3, %eax
	jg	.L380
	cmpl	$1, %eax
	je	.L381
	jmp	.L378
.L380:
	cmpl	$5, %eax
	je	.L382
	cmpl	$7, %eax
	jne	.L378
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, -12(%ebp)
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %edx
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	addl	$1, %eax
	sall	$2, %eax
	addl	%eax, %edx
	movl	current@GOT(%ebx), %eax
	movl	%edx, (%eax)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	addl	$4, -24(%ebp)
	movl	-24(%ebp), %edx
	movl	-20(%ebp), %eax
	movl	%edx, (%eax)
	subl	$4, %esp
	pushl	-12(%ebp)
	pushl	8(%ebp)
	pushl	-24(%ebp)
	call	copy_elements
	addl	$16, %esp
	jmp	.L384
.L379:
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %edx
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	addl	$1, %eax
	sall	$2, %eax
	subl	$1, %eax
	andl	$-4, %eax
	addl	$4, %eax
	addl	%eax, %edx
	movl	current@GOT(%ebx), %eax
	movl	%edx, (%eax)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	addl	$4, -24(%ebp)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, -12(%ebp)
	movl	-24(%ebp), %edx
	movl	-20(%ebp), %eax
	movl	%edx, (%eax)
	subl	$4, %esp
	pushl	-12(%ebp)
	pushl	8(%ebp)
	pushl	-24(%ebp)
	call	copy_elements
	addl	$16, %esp
	jmp	.L384
.L381:
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %edx
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	addl	$4, %eax
	andl	$-4, %eax
	addl	$4, %eax
	addl	%eax, %edx
	movl	current@GOT(%ebx), %eax
	movl	%edx, (%eax)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	addl	$4, -24(%ebp)
	movl	-24(%ebp), %edx
	movl	-20(%ebp), %eax
	movl	%edx, (%eax)
	subl	$8, %esp
	pushl	8(%ebp)
	pushl	-24(%ebp)
	call	strcpy@PLT
	addl	$16, %esp
	jmp	.L384
.L382:
	movl	8(%ebp), %eax
	subl	$8, %eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	movl	4(%eax), %eax
	shrl	$3, %eax
	movl	%eax, -12(%ebp)
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	movl	-12(%ebp), %edx
	addl	$2, %edx
	sall	$2, %edx
	addl	%eax, %edx
	movl	current@GOT(%ebx), %eax
	movl	%edx, (%eax)
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	addl	$4, -24(%ebp)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	addl	$4, -24(%ebp)
	movl	-24(%ebp), %edx
	movl	-20(%ebp), %eax
	movl	%edx, (%eax)
	subl	$4, %esp
	pushl	-12(%ebp)
	pushl	8(%ebp)
	pushl	-24(%ebp)
	call	copy_elements
	addl	$16, %esp
	jmp	.L384
.L378:
	subl	$12, %esp
	leal	.LC98@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L384:
	movl	-24(%ebp), %eax
.L374:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE84:
	.size	gc_copy, .-gc_copy
	.globl	gc_test_and_copy_root
	.type	gc_test_and_copy_root, @function
gc_test_and_copy_root:
.LFB85:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %edx
	movl	(%edx), %edx
	andl	$1, %edx
	testl	%edx, %edx
	jne	.L387
	movl	from_space@GOTOFF(%eax), %ecx
	movl	8(%ebp), %edx
	movl	(%edx), %edx
	cmpl	%edx, %ecx
	ja	.L387
	movl	4+from_space@GOTOFF(%eax), %edx
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	jbe	.L387
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	gc_copy
	addl	$16, %esp
	movl	%eax, %edx
	movl	8(%ebp), %eax
	movl	%edx, (%eax)
.L387:
	nop
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE85:
	.size	gc_test_and_copy_root, .-gc_test_and_copy_root
	.globl	gc_root_scan_data
	.type	gc_root_scan_data, @function
gc_root_scan_data:
.LFB86:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	__start_custom_data@GOT(%ebx), %eax
	movl	%eax, -12(%ebp)
	jmp	.L389
.L390:
	subl	$12, %esp
	pushl	-12(%ebp)
	call	gc_test_and_copy_root
	addl	$16, %esp
	addl	$4, -12(%ebp)
.L389:
	movl	__stop_custom_data@GOT(%ebx), %eax
	cmpl	%eax, -12(%ebp)
	jb	.L390
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE86:
	.size	gc_root_scan_data, .-gc_root_scan_data
	.type	init_extra_roots, @function
init_extra_roots:
.LFB87:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	$0, extra_roots@GOTOFF(%eax)
	nop
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE87:
	.size	init_extra_roots, .-init_extra_roots
	.section	.rodata
	.align 4
.LC99:
	.string	"EROOR: init_pool: mmap failed\n"
	.text
	.globl	init_pool
	.type	init_pool, @function
init_pool:
.LFB88:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	sall	$2, %eax
	movl	%eax, -12(%ebp)
	subl	$8, %esp
	pushl	$0
	pushl	$-1
	pushl	$98
	pushl	$3
	pushl	-12(%ebp)
	pushl	$0
	call	mmap@PLT
	addl	$32, %esp
	movl	%eax, from_space@GOTOFF(%ebx)
	movl	$0, to_space@GOTOFF(%ebx)
	movl	to_space@GOTOFF(%ebx), %eax
	cmpl	$-1, %eax
	jne	.L393
	subl	$12, %esp
	leal	.LC99@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L393:
	movl	from_space@GOTOFF(%ebx), %eax
	movl	%eax, 8+from_space@GOTOFF(%ebx)
	movl	from_space@GOTOFF(%ebx), %eax
	movl	SPACE_SIZE@GOTOFF(%ebx), %edx
	sall	$2, %edx
	addl	%edx, %eax
	movl	%eax, 4+from_space@GOTOFF(%ebx)
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	movl	%eax, 12+from_space@GOTOFF(%ebx)
	movl	$0, 8+to_space@GOTOFF(%ebx)
	movl	$0, 4+to_space@GOTOFF(%ebx)
	movl	$0, 12+to_space@GOTOFF(%ebx)
	call	init_extra_roots
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE88:
	.size	init_pool, .-init_pool
	.section	.rodata
	.align 4
.LC100:
	.string	"gc: ASSERT: !IN_PASSIVE_SPACE(current) to_begin = %p to_end = %p              current = %p\n"
	.align 4
.LC101:
	.string	"ASSERT: !IN_PASSIVE_SPACE(current)\n"
.LC102:
	.string	"runtime.c"
.LC103:
	.string	"IN_PASSIVE_SPACE(current)"
.LC104:
	.string	"current + size < to_space.end"
	.text
	.type	gc, @function
gc:
.LFB89:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	%edx, (%eax)
	call	gc_root_scan_data
	call	__gc_root_scan_stack@PLT
	movl	$0, -12(%ebp)
	jmp	.L395
.L396:
	movl	-12(%ebp), %eax
	movl	4+extra_roots@GOTOFF(%ebx,%eax,4), %eax
	subl	$12, %esp
	pushl	%eax
	call	gc_test_and_copy_root
	addl	$16, %esp
	addl	$1, -12(%ebp)
.L395:
	movl	extra_roots@GOTOFF(%ebx), %eax
	cmpl	%eax, -12(%ebp)
	jl	.L396
	movl	to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L397
	movl	4+to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L399
.L397:
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %ecx
	movl	4+to_space@GOTOFF(%ebx), %edx
	movl	to_space@GOTOFF(%ebx), %eax
	pushl	%ecx
	pushl	%edx
	pushl	%eax
	leal	.LC100@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printf@PLT
	addl	$16, %esp
	movl	stdout@GOT(%ebx), %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	fflush@PLT
	addl	$16, %esp
	subl	$12, %esp
	leal	.LC101@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L401:
	call	extend_spaces
	testl	%eax, %eax
	je	.L399
	call	gc_swap_spaces
	subl	$12, %esp
	pushl	$1
	call	init_to_space
	addl	$16, %esp
	subl	$12, %esp
	pushl	8(%ebp)
	call	gc
	addl	$16, %esp
	jmp	.L400
.L399:
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	movl	8(%ebp), %edx
	sall	$2, %edx
	addl	%eax, %edx
	movl	4+to_space@GOTOFF(%ebx), %eax
	cmpl	%eax, %edx
	jnb	.L401
	movl	to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L402
	movl	4+to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L405
.L402:
	leal	__PRETTY_FUNCTION__.3232@GOTOFF(%ebx), %eax
	pushl	%eax
	pushl	$1620
	leal	.LC102@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC103@GOTOFF(%ebx), %eax
	pushl	%eax
	call	__assert_fail@PLT
.L405:
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	movl	8(%ebp), %edx
	sall	$2, %edx
	addl	%eax, %edx
	movl	4+to_space@GOTOFF(%ebx), %eax
	cmpl	%eax, %edx
	jb	.L404
	leal	__PRETTY_FUNCTION__.3232@GOTOFF(%ebx), %eax
	pushl	%eax
	pushl	$1621
	leal	.LC102@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC104@GOTOFF(%ebx), %eax
	pushl	%eax
	call	__assert_fail@PLT
.L404:
	call	gc_swap_spaces
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	movl	8(%ebp), %edx
	sall	$2, %edx
	addl	%edx, %eax
	movl	%eax, 8+from_space@GOTOFF(%ebx)
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
.L400:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE89:
	.size	gc, .-gc
	.globl	alloc
	.type	alloc, @function
alloc:
.LFB90:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	$1, -12(%ebp)
	movl	8(%ebp), %edx
	subl	$1, %edx
	shrl	$2, %edx
	addl	$1, %edx
	movl	%edx, 8(%ebp)
	movl	8+from_space@GOTOFF(%eax), %edx
	movl	8(%ebp), %ecx
	sall	$2, %ecx
	addl	%edx, %ecx
	movl	4+from_space@GOTOFF(%eax), %edx
	cmpl	%edx, %ecx
	jnb	.L407
	movl	8+from_space@GOTOFF(%eax), %edx
	movl	%edx, -12(%ebp)
	movl	8+from_space@GOTOFF(%eax), %edx
	movl	8(%ebp), %ecx
	sall	$2, %ecx
	addl	%ecx, %edx
	movl	%edx, 8+from_space@GOTOFF(%eax)
	movl	-12(%ebp), %eax
	jmp	.L408
.L407:
	subl	$12, %esp
	pushl	$0
	call	init_to_space
	addl	$16, %esp
	subl	$12, %esp
	pushl	8(%ebp)
	call	gc
	addl	$16, %esp
.L408:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE90:
	.size	alloc, .-alloc
	.data
	.align 4
	.type	chars.2795, @object
	.size	chars.2795, 4
chars.2795:
	.long	1
	.local	buf.2796
	.comm	buf.2796,6,4
	.section	.rodata
	.type	__PRETTY_FUNCTION__.3232, @object
	.size	__PRETTY_FUNCTION__.3232, 3
__PRETTY_FUNCTION__.3232:
	.string	"gc"
	.section	.text.__x86.get_pc_thunk.ax,"axG",@progbits,__x86.get_pc_thunk.ax,comdat
	.globl	__x86.get_pc_thunk.ax
	.hidden	__x86.get_pc_thunk.ax
	.type	__x86.get_pc_thunk.ax, @function
__x86.get_pc_thunk.ax:
.LFB91:
	.cfi_startproc
	movl	(%esp), %eax
	ret
	.cfi_endproc
.LFE91:
	.section	.text.__x86.get_pc_thunk.dx,"axG",@progbits,__x86.get_pc_thunk.dx,comdat
	.globl	__x86.get_pc_thunk.dx
	.hidden	__x86.get_pc_thunk.dx
	.type	__x86.get_pc_thunk.dx, @function
__x86.get_pc_thunk.dx:
.LFB92:
	.cfi_startproc
	movl	(%esp), %edx
	ret
	.cfi_endproc
.LFE92:
	.section	.text.__x86.get_pc_thunk.bx,"axG",@progbits,__x86.get_pc_thunk.bx,comdat
	.globl	__x86.get_pc_thunk.bx
	.hidden	__x86.get_pc_thunk.bx
	.type	__x86.get_pc_thunk.bx, @function
__x86.get_pc_thunk.bx:
.LFB93:
	.cfi_startproc
	movl	(%esp), %ebx
	ret
	.cfi_endproc
.LFE93:
	.hidden	__stack_chk_fail_local
	.ident	"GCC: (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0"
	.section	.note.GNU-stack,"",@progbits
