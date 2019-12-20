	.file	"runtime.c"
	.text
	.local	from_space
	.comm	from_space,16,4
	.local	to_space
	.comm	to_space,16,4
	.comm	current,4,4
	.globl	Blength
	.type	Blength, @function
Blength:
.LFB5:
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
	subl	$4, %eax
	movl	%eax, -4(%ebp)
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE5:
	.size	Blength, .-Blength
	.section	.rodata
	.align 4
.LC0:
	.string	"_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	.text
	.globl	de_hash
	.type	de_hash, @function
de_hash:
.LFB6:
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
	leal	.LC0@GOTOFF(%eax), %edx
	movl	%edx, chars.2648@GOTOFF(%eax)
	leal	5+buf.2649@GOTOFF(%eax), %edx
	movl	%edx, -8(%ebp)
	movl	-8(%ebp), %edx
	leal	-1(%edx), %ecx
	movl	%ecx, -8(%ebp)
	movb	$0, (%edx)
	jmp	.L4
.L5:
	movl	chars.2648@GOTOFF(%eax), %edx
	movl	8(%ebp), %ecx
	andl	$63, %ecx
	leal	(%edx,%ecx), %ebx
	movl	-8(%ebp), %edx
	leal	-1(%edx), %ecx
	movl	%ecx, -8(%ebp)
	movzbl	(%ebx), %ecx
	movb	%cl, (%edx)
	sarl	$6, 8(%ebp)
.L4:
	cmpl	$0, 8(%ebp)
	jne	.L5
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
.LFE6:
	.size	de_hash, .-de_hash
	.local	stringBuf
	.comm	stringBuf,12,4
	.type	createStringBuf, @function
createStringBuf:
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
.LFE7:
	.size	createStringBuf, .-createStringBuf
	.type	deleteStringBuf, @function
deleteStringBuf:
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
.LFE8:
	.size	deleteStringBuf, .-deleteStringBuf
	.type	extendStringBuf, @function
extendStringBuf:
.LFB9:
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
.LFE9:
	.size	extendStringBuf, .-extendStringBuf
	.type	printStringBuf, @function
printStringBuf:
.LFB10:
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
	movl	8(%ebp), %eax
	movl	%eax, -44(%ebp)
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	movl	$1, -28(%ebp)
	movl	$0, -24(%ebp)
	movl	$0, -20(%ebp)
	movl	$1, -16(%ebp)
.L11:
	leal	12(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	stringBuf@GOTOFF(%ebx), %eax
	movl	4+stringBuf@GOTOFF(%ebx), %edx
	addl	%edx, %eax
	movl	%eax, -16(%ebp)
	movl	8+stringBuf@GOTOFF(%ebx), %edx
	movl	4+stringBuf@GOTOFF(%ebx), %eax
	subl	%eax, %edx
	movl	%edx, %eax
	movl	%eax, -20(%ebp)
	movl	-28(%ebp), %edx
	movl	-20(%ebp), %eax
	pushl	%edx
	pushl	-44(%ebp)
	pushl	%eax
	pushl	-16(%ebp)
	call	vsnprintf@PLT
	addl	$16, %esp
	movl	%eax, -24(%ebp)
	movl	-24(%ebp), %eax
	cmpl	-20(%ebp), %eax
	jl	.L12
	call	extendStringBuf
	jmp	.L11
.L12:
	movl	4+stringBuf@GOTOFF(%ebx), %edx
	movl	-24(%ebp), %eax
	addl	%edx, %eax
	movl	%eax, 4+stringBuf@GOTOFF(%ebx)
	nop
	movl	-12(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L13
	call	__stack_chk_fail_local
.L13:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE10:
	.size	printStringBuf, .-printStringBuf
	.section	.rodata
.LC1:
	.string	"%d"
.LC2:
	.string	"\"%s\""
.LC3:
	.string	"<closure "
.LC4:
	.string	"%x"
.LC5:
	.string	", "
.LC6:
	.string	">"
.LC7:
	.string	"["
.LC8:
	.string	"]"
.LC9:
	.string	"cons"
.LC10:
	.string	"{"
.LC11:
	.string	"}"
.LC12:
	.string	"%s"
.LC13:
	.string	" ("
.LC14:
	.string	")"
.LC15:
	.string	"*** invalid tag: %x ***"
	.text
	.type	printValue, @function
printValue:
.LFB11:
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
	je	.L15
	movl	8(%ebp), %eax
	sarl	%eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC1@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L42
.L15:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$3, %eax
	je	.L18
	cmpl	$3, %eax
	jg	.L19
	cmpl	$1, %eax
	je	.L20
	jmp	.L17
.L19:
	cmpl	$5, %eax
	je	.L21
	cmpl	$7, %eax
	je	.L22
	jmp	.L17
.L20:
	movl	-16(%ebp), %eax
	addl	$4, %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC2@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L16
.L22:
	subl	$12, %esp
	leal	.LC3@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	movl	$0, -24(%ebp)
	jmp	.L23
.L27:
	cmpl	$0, -24(%ebp)
	je	.L24
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
	jmp	.L25
.L24:
	movl	-16(%ebp), %eax
	leal	4(%eax), %edx
	movl	-24(%ebp), %eax
	sall	$2, %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC4@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
.L25:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	leal	-1(%eax), %edx
	movl	-24(%ebp), %eax
	cmpl	%eax, %edx
	je	.L26
	subl	$12, %esp
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
.L26:
	addl	$1, -24(%ebp)
.L23:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	cmpl	%eax, %edx
	ja	.L27
	subl	$12, %esp
	leal	.LC6@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L16
.L18:
	subl	$12, %esp
	leal	.LC7@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	movl	$0, -24(%ebp)
	jmp	.L28
.L30:
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
	je	.L29
	subl	$12, %esp
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
.L29:
	addl	$1, -24(%ebp)
.L28:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	cmpl	%eax, %edx
	ja	.L30
	subl	$12, %esp
	leal	.LC8@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L16
.L21:
	movl	8(%ebp), %eax
	subl	$8, %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	de_hash
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	subl	$8, %esp
	leal	.LC9@GOTOFF(%ebx), %eax
	pushl	%eax
	pushl	-12(%ebp)
	call	strcmp@PLT
	addl	$16, %esp
	testl	%eax, %eax
	jne	.L31
	movl	-16(%ebp), %eax
	movl	%eax, -20(%ebp)
	subl	$12, %esp
	leal	.LC10@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L32
.L35:
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
	jne	.L40
	subl	$12, %esp
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	subl	$4, -20(%ebp)
.L32:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	testl	%eax, %eax
	jne	.L35
	jmp	.L34
.L40:
	nop
.L34:
	subl	$12, %esp
	leal	.LC11@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L41
.L31:
	subl	$8, %esp
	pushl	-12(%ebp)
	leal	.LC12@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	testl	%eax, %eax
	je	.L41
	subl	$12, %esp
	leal	.LC13@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	movl	$0, -24(%ebp)
	jmp	.L37
.L39:
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
	je	.L38
	subl	$12, %esp
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
.L38:
	addl	$1, -24(%ebp)
.L37:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	cmpl	%eax, %edx
	ja	.L39
	subl	$12, %esp
	leal	.LC14@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L41
.L17:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC15@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L42
.L41:
	nop
.L16:
.L42:
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE11:
	.size	printValue, .-printValue
	.section	.rodata
	.align 4
.LC16:
	.string	"***** INTERNAL ERROR: invalid tag %d in compare *****\n"
	.text
	.globl	Lcompare
	.type	Lcompare, @function
Lcompare:
.LFB12:
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
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L44
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L45
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	subl	%eax, %edx
	movl	%edx, %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L46
.L45:
	movl	$-1, %eax
	jmp	.L46
.L44:
	movl	12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L47
	movl	$3, %eax
	jmp	.L46
.L47:
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
	je	.L48
	movl	-36(%ebp), %eax
	subl	-32(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L46
.L48:
	movl	-36(%ebp), %eax
	cmpl	$3, %eax
	je	.L50
	cmpl	$3, %eax
	jg	.L51
	cmpl	$1, %eax
	je	.L52
	jmp	.L49
.L51:
	cmpl	$5, %eax
	je	.L53
	cmpl	$7, %eax
	je	.L54
	jmp	.L49
.L52:
	movl	-40(%ebp), %eax
	leal	4(%eax), %edx
	movl	-44(%ebp), %eax
	addl	$4, %eax
	subl	$8, %esp
	pushl	%edx
	pushl	%eax
	call	strcmp@PLT
	addl	$16, %esp
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L46
.L54:
	movl	-44(%ebp), %eax
	addl	$4, %eax
	movl	(%eax), %edx
	movl	-40(%ebp), %eax
	addl	$4, %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	je	.L55
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
	jmp	.L46
.L55:
	movl	-28(%ebp), %eax
	cmpl	-24(%ebp), %eax
	je	.L56
	movl	-28(%ebp), %eax
	subl	-24(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L46
.L56:
	movl	$1, -48(%ebp)
	jmp	.L57
.L50:
	movl	-28(%ebp), %eax
	cmpl	-24(%ebp), %eax
	je	.L58
	movl	-28(%ebp), %eax
	subl	-24(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L46
.L58:
	movl	$0, -48(%ebp)
	jmp	.L57
.L53:
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
	je	.L59
	movl	-20(%ebp), %eax
	subl	-16(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L46
.L59:
	movl	-28(%ebp), %eax
	cmpl	-24(%ebp), %eax
	je	.L60
	movl	-28(%ebp), %eax
	subl	-24(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L46
.L60:
	movl	$0, -48(%ebp)
	jmp	.L57
.L49:
	movl	stderr@GOT(%ebx), %eax
	movl	(%eax), %eax
	subl	$4, %esp
	pushl	-36(%ebp)
	leal	.LC16@GOTOFF(%ebx), %edx
	pushl	%edx
	pushl	%eax
	call	fprintf@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$255
	call	exit@PLT
.L57:
	jmp	.L61
.L63:
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
	je	.L62
	movl	-12(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L46
.L62:
	addl	$1, -48(%ebp)
.L61:
	movl	-48(%ebp), %eax
	cmpl	-28(%ebp), %eax
	jl	.L63
	movl	$1, %eax
.L46:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE12:
	.size	Lcompare, .-Lcompare
	.globl	Belem
	.type	Belem, @function
Belem:
.LFB13:
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
	subl	$4, %eax
	movl	%eax, -4(%ebp)
	sarl	12(%ebp)
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	jne	.L65
	movl	-4(%ebp), %edx
	movl	12(%ebp), %eax
	addl	%edx, %eax
	addl	$4, %eax
	movzbl	(%eax), %eax
	movsbl	%al, %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L66
.L65:
	movl	-4(%ebp), %eax
	leal	4(%eax), %edx
	movl	12(%ebp), %eax
	sall	$2, %eax
	addl	%edx, %eax
	movl	(%eax), %eax
.L66:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE13:
	.size	Belem, .-Belem
	.globl	Bstring
	.type	Bstring, @function
Bstring:
.LFB14:
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
	movl	$0, -12(%ebp)
	call	__pre_gc@PLT
	subl	$12, %esp
	pushl	8(%ebp)
	call	strlen@PLT
	addl	$16, %esp
	movl	%eax, -16(%ebp)
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
	addl	$1, %eax
	movl	%eax, %edx
	movl	-12(%ebp), %eax
	addl	$4, %eax
	subl	$4, %esp
	pushl	%edx
	pushl	8(%ebp)
	pushl	%eax
	call	strncpy@PLT
	addl	$16, %esp
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
.LFE14:
	.size	Bstring, .-Bstring
	.globl	Bstringval
	.type	Bstringval, @function
Bstringval:
.LFB15:
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
.LFE15:
	.size	Bstringval, .-Bstringval
	.globl	Bclosure
	.type	Bclosure, @function
Bclosure:
.LFB16:
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
	jmp	.L72
.L73:
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
.L72:
	movl	-24(%ebp), %eax
	cmpl	8(%ebp), %eax
	jl	.L73
	call	__post_gc@PLT
	movl	-16(%ebp), %eax
	addl	$4, %eax
	movl	-12(%ebp), %ecx
	xorl	%gs:20, %ecx
	je	.L75
	call	__stack_chk_fail_local
.L75:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE16:
	.size	Bclosure, .-Bclosure
	.globl	Barray
	.type	Barray, @function
Barray:
.LFB17:
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
	jmp	.L77
.L78:
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
.L77:
	movl	-24(%ebp), %eax
	cmpl	8(%ebp), %eax
	jl	.L78
	call	__post_gc@PLT
	movl	-16(%ebp), %eax
	addl	$4, %eax
	movl	-12(%ebp), %ecx
	xorl	%gs:20, %ecx
	je	.L80
	call	__stack_chk_fail_local
.L80:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE17:
	.size	Barray, .-Barray
	.globl	Bsexp
	.type	Bsexp, @function
Bsexp:
.LFB18:
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
	jmp	.L82
.L83:
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
.L82:
	movl	8(%ebp), %eax
	subl	$1, %eax
	cmpl	%eax, -32(%ebp)
	jl	.L83
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
	je	.L85
	call	__stack_chk_fail_local
.L85:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE18:
	.size	Bsexp, .-Bsexp
	.globl	Btag
	.type	Btag, @function
Btag:
.LFB19:
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
	je	.L87
	movl	$1, %eax
	jmp	.L88
.L87:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -4(%ebp)
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$5, %eax
	jne	.L89
	movl	8(%ebp), %eax
	subl	$8, %eax
	movl	(%eax), %eax
	cmpl	%eax, 12(%ebp)
	jne	.L89
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	16(%ebp), %eax
	cmpl	%eax, %edx
	jne	.L89
	movl	$1, %eax
	jmp	.L90
.L89:
	movl	$0, %eax
.L90:
	addl	%eax, %eax
	orl	$1, %eax
.L88:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE19:
	.size	Btag, .-Btag
	.globl	Barray_patt
	.type	Barray_patt, @function
Barray_patt:
.LFB20:
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
	je	.L92
	movl	$1, %eax
	jmp	.L93
.L92:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -4(%ebp)
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$3, %eax
	jne	.L94
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	cmpl	%eax, %edx
	jne	.L94
	movl	$1, %eax
	jmp	.L95
.L94:
	movl	$0, %eax
.L95:
	addl	%eax, %eax
	orl	$1, %eax
.L93:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE20:
	.size	Barray_patt, .-Barray_patt
	.globl	Bstring_patt
	.type	Bstring_patt, @function
Bstring_patt:
.LFB21:
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
	movl	$1, -16(%ebp)
	movl	$1, -12(%ebp)
	movl	8(%ebp), %edx
	andl	$1, %edx
	testl	%edx, %edx
	je	.L97
	movl	$1, %eax
	jmp	.L98
.L97:
	movl	8(%ebp), %edx
	subl	$4, %edx
	movl	%edx, -16(%ebp)
	movl	12(%ebp), %edx
	subl	$4, %edx
	movl	%edx, -12(%ebp)
	movl	-16(%ebp), %edx
	movl	(%edx), %edx
	andl	$7, %edx
	cmpl	$1, %edx
	je	.L99
	movl	$1, %eax
	jmp	.L98
.L99:
	movl	-12(%ebp), %edx
	leal	4(%edx), %ecx
	movl	-16(%ebp), %edx
	addl	$4, %edx
	subl	$8, %esp
	pushl	%ecx
	pushl	%edx
	movl	%eax, %ebx
	call	strcmp@PLT
	addl	$16, %esp
	testl	%eax, %eax
	jne	.L100
	movl	$3, %eax
	jmp	.L98
.L100:
	movl	$1, %eax
.L98:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE21:
	.size	Bstring_patt, .-Bstring_patt
	.globl	Bclosure_tag_patt
	.type	Bclosure_tag_patt, @function
Bclosure_tag_patt:
.LFB22:
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
	je	.L103
	movl	$1, %eax
	jmp	.L104
.L103:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$7, %eax
	jne	.L105
	movl	$3, %eax
	jmp	.L104
.L105:
	movl	$1, %eax
.L104:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE22:
	.size	Bclosure_tag_patt, .-Bclosure_tag_patt
	.globl	Bboxed_patt
	.type	Bboxed_patt, @function
Bboxed_patt:
.LFB23:
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
	jne	.L108
	movl	$3, %eax
	jmp	.L110
.L108:
	movl	$1, %eax
.L110:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE23:
	.size	Bboxed_patt, .-Bboxed_patt
	.globl	Bunboxed_patt
	.type	Bunboxed_patt, @function
Bunboxed_patt:
.LFB24:
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
.LFE24:
	.size	Bunboxed_patt, .-Bunboxed_patt
	.globl	Barray_tag_patt
	.type	Barray_tag_patt, @function
Barray_tag_patt:
.LFB25:
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
	je	.L114
	movl	$1, %eax
	jmp	.L115
.L114:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$3, %eax
	jne	.L116
	movl	$3, %eax
	jmp	.L115
.L116:
	movl	$1, %eax
.L115:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE25:
	.size	Barray_tag_patt, .-Barray_tag_patt
	.globl	Bstring_tag_patt
	.type	Bstring_tag_patt, @function
Bstring_tag_patt:
.LFB26:
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
	je	.L119
	movl	$1, %eax
	jmp	.L120
.L119:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	jne	.L121
	movl	$3, %eax
	jmp	.L120
.L121:
	movl	$1, %eax
.L120:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE26:
	.size	Bstring_tag_patt, .-Bstring_tag_patt
	.globl	Bsexp_tag_patt
	.type	Bsexp_tag_patt, @function
Bsexp_tag_patt:
.LFB27:
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
	je	.L124
	movl	$1, %eax
	jmp	.L125
.L124:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$5, %eax
	jne	.L126
	movl	$3, %eax
	jmp	.L125
.L126:
	movl	$1, %eax
.L125:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE27:
	.size	Bsexp_tag_patt, .-Bsexp_tag_patt
	.globl	Bsta
	.type	Bsta, @function
Bsta:
.LFB28:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	16(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$1, %eax
	jne	.L129
	movl	8(%ebp), %eax
	sarl	%eax
	movl	%eax, %edx
	movl	12(%ebp), %eax
	sarl	%eax
	movl	%eax, %ecx
	movl	16(%ebp), %eax
	addl	%ecx, %eax
	movb	%dl, (%eax)
	jmp	.L130
.L129:
	movl	12(%ebp), %eax
	sarl	%eax
	leal	0(,%eax,4), %edx
	movl	16(%ebp), %eax
	addl	%eax, %edx
	movl	8(%ebp), %eax
	movl	%eax, (%edx)
.L130:
	movl	8(%ebp), %eax
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE28:
	.size	Bsta, .-Bsta
	.globl	Lraw
	.type	Lraw, @function
Lraw:
.LFB29:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %eax
	sarl	%eax
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE29:
	.size	Lraw, .-Lraw
	.section	.rodata
.LC17:
	.string	"Format string: %s\n"
.LC18:
	.string	"First arg: %d\n"
.LC19:
	.string	"Second arg: %d\n"
.LC20:
	.string	"arg: %d\n"
	.text
	.globl	Lprintf
	.type	Lprintf, @function
Lprintf:
.LFB30:
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
	movl	$1, -24(%ebp)
	leal	-28(%ebp), %eax
	movl	%eax, -20(%ebp)
	movl	-28(%ebp), %eax
	movl	%eax, -16(%ebp)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC17@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printf@PLT
	addl	$16, %esp
	movl	-20(%ebp), %eax
	addl	$4, %eax
	movl	(%eax), %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC18@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printf@PLT
	addl	$16, %esp
	movl	-20(%ebp), %eax
	addl	$8, %eax
	movl	(%eax), %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC19@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printf@PLT
	addl	$16, %esp
	jmp	.L135
.L137:
	movl	-16(%ebp), %eax
	movzbl	(%eax), %eax
	cmpb	$37, %al
	jne	.L136
	addl	$4, -20(%ebp)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC20@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printf@PLT
	addl	$16, %esp
.L136:
	addl	$1, -16(%ebp)
.L135:
	movl	-16(%ebp), %eax
	movzbl	(%eax), %eax
	testb	%al, %al
	jne	.L137
	leal	12(%ebp), %eax
	movl	%eax, -24(%ebp)
	movl	-24(%ebp), %edx
	movl	-28(%ebp), %eax
	subl	$8, %esp
	pushl	%edx
	pushl	%eax
	call	vprintf@PLT
	addl	$16, %esp
	nop
	movl	-12(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L138
	call	__stack_chk_fail_local
.L138:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE30:
	.size	Lprintf, .-Lprintf
	.globl	i__Infix_4343
	.type	i__Infix_4343, @function
i__Infix_4343:
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
	movl	$1, -20(%ebp)
	movl	$1, -16(%ebp)
	movl	$1, -12(%ebp)
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
	movl	%eax, %edx
	movl	-12(%ebp), %eax
	movl	%edx, (%eax)
	movl	-20(%ebp), %eax
	leal	4(%eax), %edx
	movl	-12(%ebp), %eax
	addl	$4, %eax
	subl	$8, %esp
	pushl	%edx
	pushl	%eax
	call	strcpy@PLT
	addl	$16, %esp
	movl	-16(%ebp), %eax
	leal	4(%eax), %edx
	movl	-12(%ebp), %eax
	addl	$4, %eax
	subl	$8, %esp
	pushl	%edx
	pushl	%eax
	call	strcat@PLT
	addl	$16, %esp
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
.LFE31:
	.size	i__Infix_4343, .-i__Infix_4343
	.globl	Lfprintf
	.type	Lfprintf, @function
Lfprintf:
.LFB32:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$36, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %edx
	movl	%edx, -28(%ebp)
	movl	12(%ebp), %edx
	movl	%edx, -32(%ebp)
	movl	%gs:20, %ecx
	movl	%ecx, -12(%ebp)
	xorl	%ecx, %ecx
	movl	$1, -16(%ebp)
	leal	16(%ebp), %edx
	movl	%edx, -16(%ebp)
	movl	-16(%ebp), %edx
	subl	$4, %esp
	pushl	%edx
	pushl	-32(%ebp)
	pushl	-28(%ebp)
	movl	%eax, %ebx
	call	vfprintf@PLT
	addl	$16, %esp
	nop
	movl	-12(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L142
	call	__stack_chk_fail_local
.L142:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE32:
	.size	Lfprintf, .-Lfprintf
	.globl	Lfopen
	.type	Lfopen, @function
Lfopen:
.LFB33:
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
	subl	$8, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
	movl	%eax, %ebx
	call	fopen@PLT
	addl	$16, %esp
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE33:
	.size	Lfopen, .-Lfopen
	.globl	Lfclose
	.type	Lfclose, @function
Lfclose:
.LFB34:
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
	subl	$12, %esp
	pushl	8(%ebp)
	movl	%eax, %ebx
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
.LFE34:
	.size	Lfclose, .-Lfclose
	.section	.rodata
.LC21:
	.string	"> "
	.text
	.globl	Lread
	.type	Lread, @function
Lread:
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
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	movl	$1, -16(%ebp)
	subl	$12, %esp
	leal	.LC21@GOTOFF(%ebx), %eax
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
	leal	.LC1@GOTOFF(%ebx), %eax
	pushl	%eax
	call	__isoc99_scanf@PLT
	addl	$16, %esp
	movl	-16(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	movl	-12(%ebp), %edx
	xorl	%gs:20, %edx
	je	.L148
	call	__stack_chk_fail_local
.L148:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE35:
	.size	Lread, .-Lread
	.section	.rodata
.LC22:
	.string	"%d\n"
	.text
	.globl	Lwrite
	.type	Lwrite, @function
Lwrite:
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
	sarl	%eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC22@GOTOFF(%ebx), %eax
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
.LFE36:
	.size	Lwrite, .-Lwrite
	.data
	.align 4
	.type	SPACE_SIZE, @object
	.size	SPACE_SIZE, 4
SPACE_SIZE:
	.long	1280
	.text
	.type	swap, @function
swap:
.LFB37:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$16, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, -4(%ebp)
	movl	12(%ebp), %eax
	movl	(%eax), %edx
	movl	8(%ebp), %eax
	movl	%edx, (%eax)
	movl	12(%ebp), %eax
	movl	-4(%ebp), %edx
	movl	%edx, (%eax)
	nop
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE37:
	.size	swap, .-swap
	.type	gc_swap_spaces, @function
gc_swap_spaces:
.LFB38:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	leal	to_space@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	from_space@GOTOFF(%ebx), %eax
	pushl	%eax
	call	swap
	addl	$8, %esp
	leal	4+to_space@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	4+from_space@GOTOFF(%ebx), %eax
	pushl	%eax
	call	swap
	addl	$8, %esp
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	movl	%eax, 8+from_space@GOTOFF(%ebx)
	movl	to_space@GOTOFF(%ebx), %eax
	movl	%eax, 8+to_space@GOTOFF(%ebx)
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE38:
	.size	gc_swap_spaces, .-gc_swap_spaces
	.type	copy_elements, @function
copy_elements:
.LFB39:
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
	jmp	.L154
.L158:
	movl	-20(%ebp), %eax
	leal	0(,%eax,4), %edx
	movl	12(%ebp), %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	movl	%eax, -12(%ebp)
	movl	-12(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L155
	movl	from_space@GOTOFF(%ebx), %edx
	movl	-12(%ebp), %eax
	cmpl	%eax, %edx
	ja	.L155
	movl	4+from_space@GOTOFF(%ebx), %edx
	movl	-12(%ebp), %eax
	cmpl	%eax, %edx
	ja	.L156
.L155:
	movl	8(%ebp), %eax
	movl	-12(%ebp), %edx
	movl	%edx, (%eax)
	addl	$4, 8(%ebp)
	jmp	.L157
.L156:
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
.L157:
	addl	$1, -20(%ebp)
.L154:
	movl	-20(%ebp), %eax
	cmpl	16(%ebp), %eax
	jl	.L158
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE39:
	.size	copy_elements, .-copy_elements
	.section	.rodata
	.align 4
.LC23:
	.string	"EROOR: extend_spaces: mmap failed\n"
	.text
	.type	extend_spaces, @function
extend_spaces:
.LFB40:
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
	movl	$1, -24(%ebp)
	movl	$1, -20(%ebp)
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	sall	$2, %eax
	movl	%eax, -16(%ebp)
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	sall	$3, %eax
	movl	%eax, -12(%ebp)
	movl	from_space@GOTOFF(%ebx), %eax
	pushl	$0
	pushl	-12(%ebp)
	pushl	-16(%ebp)
	pushl	%eax
	call	mremap@PLT
	addl	$16, %esp
	movl	%eax, -24(%ebp)
	movl	to_space@GOTOFF(%ebx), %eax
	pushl	$0
	pushl	-12(%ebp)
	pushl	-16(%ebp)
	pushl	%eax
	call	mremap@PLT
	addl	$16, %esp
	movl	%eax, -20(%ebp)
	cmpl	$-1, -24(%ebp)
	je	.L160
	cmpl	$-1, -20(%ebp)
	jne	.L161
.L160:
	subl	$12, %esp
	leal	.LC23@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L161:
	movl	4+from_space@GOTOFF(%ebx), %eax
	movl	SPACE_SIZE@GOTOFF(%ebx), %edx
	sall	$2, %edx
	addl	%edx, %eax
	movl	%eax, 4+from_space@GOTOFF(%ebx)
	movl	4+to_space@GOTOFF(%ebx), %eax
	movl	SPACE_SIZE@GOTOFF(%ebx), %edx
	sall	$2, %edx
	addl	%edx, %eax
	movl	%eax, 4+to_space@GOTOFF(%ebx)
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	addl	%eax, %eax
	movl	%eax, SPACE_SIZE@GOTOFF(%ebx)
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	movl	%eax, 12+from_space@GOTOFF(%ebx)
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
.LFE40:
	.size	extend_spaces, .-extend_spaces
	.section	.rodata
.LC24:
	.string	"ERROR: gc_copy: out-of-space\n"
.LC25:
	.string	"ERROR: gc_copy: weird tag"
	.text
	.globl	gc_copy
	.type	gc_copy, @function
gc_copy:
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
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -20(%ebp)
	movl	$0, -16(%ebp)
	movl	$0, -24(%ebp)
	movl	$0, -12(%ebp)
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L163
	movl	from_space@GOTOFF(%ebx), %eax
	cmpl	%eax, 8(%ebp)
	jb	.L163
	movl	4+from_space@GOTOFF(%ebx), %eax
	cmpl	%eax, 8(%ebp)
	jb	.L164
.L163:
	movl	8(%ebp), %eax
	jmp	.L165
.L164:
	movl	to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L166
	movl	4+to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L167
.L166:
	movl	4+to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	je	.L167
	subl	$12, %esp
	leal	.LC24@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L167:
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L168
	movl	to_space@GOTOFF(%ebx), %edx
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L168
	movl	4+to_space@GOTOFF(%ebx), %edx
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	jbe	.L168
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	jmp	.L165
.L168:
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	movl	%eax, -24(%ebp)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	andl	$7, %eax
	cmpl	$3, %eax
	je	.L170
	cmpl	$3, %eax
	jg	.L171
	cmpl	$1, %eax
	je	.L172
	jmp	.L169
.L171:
	cmpl	$5, %eax
	je	.L173
	cmpl	$7, %eax
	jne	.L169
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %edx
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	addl	$1, %eax
	sall	$4, %eax
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
	subl	$1, %eax
	movl	%eax, -12(%ebp)
	movl	-24(%ebp), %edx
	movl	-20(%ebp), %eax
	movl	%edx, (%eax)
	movl	8(%ebp), %eax
	movl	(%eax), %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	movl	8(%ebp), %eax
	leal	4(%eax), %edx
	movl	%edx, 8(%ebp)
	subl	$4, %esp
	pushl	-12(%ebp)
	pushl	%eax
	pushl	-24(%ebp)
	call	copy_elements
	addl	$16, %esp
	jmp	.L175
.L170:
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %edx
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	addl	$1, %eax
	sall	$4, %eax
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
	jmp	.L175
.L172:
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %edx
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	shrl	$3, %eax
	addl	$4, %eax
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
	subl	$8, %esp
	pushl	8(%ebp)
	pushl	-24(%ebp)
	call	strcpy@PLT
	addl	$16, %esp
	jmp	.L175
.L173:
	movl	8(%ebp), %eax
	subl	$8, %eax
	movl	%eax, -16(%ebp)
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %edx
	movl	-16(%ebp), %eax
	movl	4(%eax), %eax
	shrl	$3, %eax
	addl	$2, %eax
	sall	$4, %eax
	addl	%eax, %edx
	movl	current@GOT(%ebx), %eax
	movl	%edx, (%eax)
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	addl	$4, -24(%ebp)
	movl	-16(%ebp), %eax
	movl	4(%eax), %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	addl	$4, -24(%ebp)
	movl	-16(%ebp), %eax
	movl	4(%eax), %eax
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
	jmp	.L175
.L169:
	subl	$12, %esp
	leal	.LC25@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L175:
	movl	-24(%ebp), %eax
.L165:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE41:
	.size	gc_copy, .-gc_copy
	.globl	gc_test_and_copy_root
	.type	gc_test_and_copy_root, @function
gc_test_and_copy_root:
.LFB42:
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
	jne	.L178
	movl	from_space@GOTOFF(%eax), %ecx
	movl	8(%ebp), %edx
	movl	(%edx), %edx
	cmpl	%edx, %ecx
	ja	.L178
	movl	4+from_space@GOTOFF(%eax), %edx
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	jbe	.L178
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	gc_copy
	addl	$16, %esp
	movl	%eax, %edx
	movl	8(%ebp), %eax
	movl	%edx, (%eax)
.L178:
	nop
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE42:
	.size	gc_test_and_copy_root, .-gc_test_and_copy_root
	.globl	gc_root_scan_data
	.type	gc_root_scan_data, @function
gc_root_scan_data:
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
	movl	__gc_data_start@GOT(%ebx), %eax
	movl	%eax, -12(%ebp)
	jmp	.L180
.L181:
	subl	$12, %esp
	pushl	-12(%ebp)
	call	gc_test_and_copy_root
	addl	$16, %esp
	addl	$4, -12(%ebp)
.L180:
	movl	__gc_data_end@GOT(%ebx), %eax
	cmpl	%eax, -12(%ebp)
	jne	.L181
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE43:
	.size	gc_root_scan_data, .-gc_root_scan_data
	.section	.rodata
	.align 4
.LC26:
	.string	"EROOR: init_pool: mmap failed\n"
	.text
	.globl	init_pool
	.type	init_pool, @function
init_pool:
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
	je	.L183
	movl	from_space@GOTOFF(%ebx), %eax
	cmpl	$-1, %eax
	jne	.L184
.L183:
	subl	$12, %esp
	leal	.LC26@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L184:
	movl	from_space@GOTOFF(%ebx), %eax
	movl	%eax, 8+from_space@GOTOFF(%ebx)
	movl	from_space@GOTOFF(%ebx), %eax
	movl	SPACE_SIZE@GOTOFF(%ebx), %edx
	sall	$2, %edx
	addl	%edx, %eax
	movl	%eax, 4+from_space@GOTOFF(%ebx)
	movl	SPACE_SIZE@GOTOFF(%ebx), %eax
	movl	%eax, 12+from_space@GOTOFF(%ebx)
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
.LFE44:
	.size	init_pool, .-init_pool
	.type	free_pool, @function
free_pool:
.LFB45:
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
	movl	8(%ebp), %edx
	movl	12(%edx), %ecx
	movl	8(%ebp), %edx
	movl	(%edx), %edx
	subl	$8, %esp
	pushl	%ecx
	pushl	%edx
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
.LFE45:
	.size	free_pool, .-free_pool
	.section	.rodata
	.align 4
.LC27:
	.string	"ASSERT: !IN_PASSIVE_SPACE(current)\n"
.LC28:
	.string	"runtime.c"
.LC29:
	.string	"IN_PASSIVE_SPACE(current)"
.LC30:
	.string	"current + size < to_space.end"
	.text
	.type	gc, @function
gc:
.LFB46:
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
	movl	to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	%edx, (%eax)
	call	gc_root_scan_data
	call	__gc_root_scan_stack@PLT
	movl	to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L188
	movl	4+to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L190
.L188:
	subl	$12, %esp
	leal	.LC27@GOTOFF(%ebx), %eax
	pushl	%eax
	call	perror@PLT
	addl	$16, %esp
	subl	$12, %esp
	pushl	$1
	call	exit@PLT
.L191:
	call	extend_spaces
.L190:
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	movl	8(%ebp), %edx
	sall	$2, %edx
	addl	%eax, %edx
	movl	4+to_space@GOTOFF(%ebx), %eax
	cmpl	%eax, %edx
	jnb	.L191
	movl	to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L192
	movl	4+to_space@GOTOFF(%ebx), %edx
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	cmpl	%eax, %edx
	ja	.L196
.L192:
	leal	__PRETTY_FUNCTION__.2918@GOTOFF(%ebx), %eax
	pushl	%eax
	pushl	$865
	leal	.LC28@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC29@GOTOFF(%ebx), %eax
	pushl	%eax
	call	__assert_fail@PLT
.L196:
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	movl	8(%ebp), %edx
	sall	$2, %edx
	addl	%eax, %edx
	movl	4+to_space@GOTOFF(%ebx), %eax
	cmpl	%eax, %edx
	jb	.L194
	leal	__PRETTY_FUNCTION__.2918@GOTOFF(%ebx), %eax
	pushl	%eax
	pushl	$866
	leal	.LC28@GOTOFF(%ebx), %eax
	pushl	%eax
	leal	.LC30@GOTOFF(%ebx), %eax
	pushl	%eax
	call	__assert_fail@PLT
.L194:
	call	gc_swap_spaces
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	movl	8(%ebp), %edx
	sall	$2, %edx
	addl	%edx, %eax
	movl	%eax, 8+from_space@GOTOFF(%ebx)
	movl	current@GOT(%ebx), %eax
	movl	(%eax), %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE46:
	.size	gc, .-gc
	.globl	alloc
	.type	alloc, @function
alloc:
.LFB47:
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
	movl	8+from_space@GOTOFF(%eax), %edx
	movl	8(%ebp), %ecx
	sall	$2, %ecx
	addl	%edx, %ecx
	movl	4+from_space@GOTOFF(%eax), %edx
	cmpl	%edx, %ecx
	jnb	.L198
	movl	8+from_space@GOTOFF(%eax), %edx
	movl	%edx, -12(%ebp)
	movl	8+from_space@GOTOFF(%eax), %edx
	movl	8(%ebp), %ecx
	sall	$2, %ecx
	addl	%ecx, %edx
	movl	%edx, 8+from_space@GOTOFF(%eax)
	movl	-12(%ebp), %eax
	jmp	.L199
.L198:
	subl	$12, %esp
	pushl	8(%ebp)
	call	gc
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	subl	$12, %esp
	pushl	8(%ebp)
	call	gc
	addl	$16, %esp
.L199:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE47:
	.size	alloc, .-alloc
	.data
	.align 4
	.type	chars.2648, @object
	.size	chars.2648, 4
chars.2648:
	.long	1
	.local	buf.2649
	.comm	buf.2649,6,4
	.section	.rodata
	.type	__PRETTY_FUNCTION__.2918, @object
	.size	__PRETTY_FUNCTION__.2918, 3
__PRETTY_FUNCTION__.2918:
	.string	"gc"
	.section	.text.__x86.get_pc_thunk.ax,"axG",@progbits,__x86.get_pc_thunk.ax,comdat
	.globl	__x86.get_pc_thunk.ax
	.hidden	__x86.get_pc_thunk.ax
	.type	__x86.get_pc_thunk.ax, @function
__x86.get_pc_thunk.ax:
.LFB48:
	.cfi_startproc
	movl	(%esp), %eax
	ret
	.cfi_endproc
.LFE48:
	.section	.text.__x86.get_pc_thunk.bx,"axG",@progbits,__x86.get_pc_thunk.bx,comdat
	.globl	__x86.get_pc_thunk.bx
	.hidden	__x86.get_pc_thunk.bx
	.type	__x86.get_pc_thunk.bx, @function
__x86.get_pc_thunk.bx:
.LFB49:
	.cfi_startproc
	movl	(%esp), %ebx
	ret
	.cfi_endproc
.LFE49:
	.hidden	__stack_chk_fail_local
	.ident	"GCC: (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0"
	.section	.note.GNU-stack,"",@progbits
