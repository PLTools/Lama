	.file	"runtime.c"
	.text
	.globl	Blength
	.type	Blength, @function
Blength:
.LFB6:
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
	subl	$4, %eax
	movl	%eax, -4(%ebp)
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	addl	%eax, %eax
	andl	$33554430, %eax
	orl	$1, %eax
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE6:
	.size	Blength, .-Blength
	.globl	de_hash
	.type	de_hash, @function
de_hash:
.LFB7:
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
	leal	5+buf.3077@GOTOFF(%eax), %edx
	movl	%edx, -8(%ebp)
	movl	-8(%ebp), %edx
	leal	-1(%edx), %ecx
	movl	%ecx, -8(%ebp)
	movb	$0, (%edx)
	jmp	.L4
.L5:
	movl	chars.3076@GOTOFF(%eax), %edx
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
.LFE7:
	.size	de_hash, .-de_hash
	.local	stringBuf
	.comm	stringBuf,12,4
	.type	createStringBuf, @function
createStringBuf:
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
.LFE8:
	.size	createStringBuf, .-createStringBuf
	.type	deleteStringBuf, @function
deleteStringBuf:
.LFB9:
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
.LFE9:
	.size	deleteStringBuf, .-deleteStringBuf
	.type	extendStringBuf, @function
extendStringBuf:
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
.LFE10:
	.size	extendStringBuf, .-extendStringBuf
	.type	printStringBuf, @function
printStringBuf:
.LFB11:
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
.L11:
	leal	12(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	stringBuf@GOTOFF(%ebx), %eax
	movl	4+stringBuf@GOTOFF(%ebx), %edx
	addl	%edx, %eax
	movl	%eax, -24(%ebp)
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
	pushl	-24(%ebp)
	call	vsnprintf@PLT
	addl	$16, %esp
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	cmpl	-20(%ebp), %eax
	jl	.L12
	call	extendStringBuf
	jmp	.L11
.L12:
	movl	4+stringBuf@GOTOFF(%ebx), %edx
	movl	-16(%ebp), %eax
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
.LFE11:
	.size	printStringBuf, .-printStringBuf
	.section	.rodata
.LC0:
	.string	"%d"
.LC1:
	.string	"\"%s\""
.LC2:
	.string	"["
.LC3:
	.string	", "
.LC4:
	.string	"]"
.LC5:
	.string	"`%s"
.LC6:
	.string	" ("
.LC7:
	.string	")"
.LC8:
	.string	"*** invalid tag: %x ***"
	.text
	.type	printValue, @function
printValue:
.LFB12:
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
	je	.L15
	movl	8(%ebp), %eax
	sarl	%eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC0@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L28
.L15:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -12(%ebp)
	movl	-12(%ebp), %eax
	movl	(%eax), %eax
	andl	$-16777216, %eax
	cmpl	$16777216, %eax
	je	.L17
	cmpl	$33554432, %eax
	je	.L18
	testl	%eax, %eax
	jne	.L19
	movl	-12(%ebp), %eax
	addl	$4, %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC1@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L16
.L17:
	subl	$12, %esp
	leal	.LC2@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	movl	$0, -20(%ebp)
	jmp	.L20
.L22:
	movl	-12(%ebp), %eax
	leal	4(%eax), %edx
	movl	-20(%ebp), %eax
	sall	$2, %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	printValue
	addl	$16, %esp
	movl	-12(%ebp), %eax
	movl	(%eax), %eax
	andl	$16777215, %eax
	subl	$1, %eax
	cmpl	%eax, -20(%ebp)
	je	.L21
	subl	$12, %esp
	leal	.LC3@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
.L21:
	addl	$1, -20(%ebp)
.L20:
	movl	-12(%ebp), %eax
	movl	(%eax), %eax
	andl	$16777215, %eax
	cmpl	%eax, -20(%ebp)
	jl	.L22
	subl	$12, %esp
	leal	.LC4@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L16
.L18:
	movl	8(%ebp), %eax
	subl	$8, %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	de_hash
	addl	$16, %esp
	subl	$8, %esp
	pushl	%eax
	leal	.LC5@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	movl	-12(%ebp), %eax
	movl	(%eax), %eax
	andl	$16777215, %eax
	testl	%eax, %eax
	je	.L27
	subl	$12, %esp
	leal	.LC6@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	movl	$0, -16(%ebp)
	jmp	.L24
.L26:
	movl	-12(%ebp), %eax
	leal	4(%eax), %edx
	movl	-16(%ebp), %eax
	sall	$2, %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	subl	$12, %esp
	pushl	%eax
	call	printValue
	addl	$16, %esp
	movl	-12(%ebp), %eax
	movl	(%eax), %eax
	andl	$16777215, %eax
	subl	$1, %eax
	cmpl	%eax, -16(%ebp)
	je	.L25
	subl	$12, %esp
	leal	.LC3@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
.L25:
	addl	$1, -16(%ebp)
.L24:
	movl	-12(%ebp), %eax
	movl	(%eax), %eax
	andl	$16777215, %eax
	cmpl	%eax, -16(%ebp)
	jl	.L26
	subl	$12, %esp
	leal	.LC7@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L27
.L19:
	movl	-12(%ebp), %eax
	movl	(%eax), %eax
	andl	$-16777216, %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC8@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printStringBuf
	addl	$16, %esp
	jmp	.L28
.L27:
	nop
.L16:
.L28:
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE12:
	.size	printValue, .-printValue
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
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -4(%ebp)
	sarl	12(%ebp)
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	andl	$-16777216, %eax
	testl	%eax, %eax
	jne	.L30
	movl	-4(%ebp), %edx
	movl	12(%ebp), %eax
	addl	%edx, %eax
	addl	$4, %eax
	movzbl	(%eax), %eax
	movsbl	%al, %eax
	addl	%eax, %eax
	orl	$1, %eax
	jmp	.L31
.L30:
	movl	-4(%ebp), %eax
	leal	4(%eax), %edx
	movl	12(%ebp), %eax
	sall	$2, %eax
	addl	%edx, %eax
	movl	(%eax), %eax
.L31:
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
	subl	$12, %esp
	pushl	8(%ebp)
	call	strlen@PLT
	addl	$16, %esp
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	addl	$5, %eax
	subl	$12, %esp
	pushl	%eax
	call	malloc@PLT
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	movl	-12(%ebp), %eax
	movl	-16(%ebp), %edx
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
	.globl	Barray
	.type	Barray, @function
Barray:
.LFB16:
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
	movl	%gs:20, %ecx
	movl	%ecx, -12(%ebp)
	xorl	%ecx, %ecx
	movl	8(%ebp), %edx
	addl	$1, %edx
	sall	$2, %edx
	subl	$12, %esp
	pushl	%edx
	movl	%eax, %ebx
	call	malloc@PLT
	addl	$16, %esp
	movl	%eax, -20(%ebp)
	movl	8(%ebp), %eax
	orl	$16777216, %eax
	movl	%eax, %edx
	movl	-20(%ebp), %eax
	movl	%edx, (%eax)
	leal	12(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	$0, -24(%ebp)
	jmp	.L37
.L38:
	movl	-28(%ebp), %eax
	leal	4(%eax), %edx
	movl	%edx, -28(%ebp)
	movl	(%eax), %eax
	movl	%eax, -16(%ebp)
	movl	-20(%ebp), %eax
	leal	4(%eax), %edx
	movl	-24(%ebp), %eax
	sall	$2, %eax
	addl	%eax, %edx
	movl	-16(%ebp), %eax
	movl	%eax, (%edx)
	addl	$1, -24(%ebp)
.L37:
	movl	-24(%ebp), %eax
	cmpl	8(%ebp), %eax
	jl	.L38
	movl	-20(%ebp), %eax
	addl	$4, %eax
	movl	-12(%ebp), %ecx
	xorl	%gs:20, %ecx
	je	.L40
	call	__stack_chk_fail_local
.L40:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE16:
	.size	Barray, .-Barray
	.globl	Bsexp
	.type	Bsexp, @function
Bsexp:
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
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	%gs:20, %ecx
	movl	%ecx, -12(%ebp)
	xorl	%ecx, %ecx
	movl	8(%ebp), %edx
	addl	$2, %edx
	sall	$2, %edx
	subl	$12, %esp
	pushl	%edx
	movl	%eax, %ebx
	call	malloc@PLT
	addl	$16, %esp
	movl	%eax, -24(%ebp)
	movl	-24(%ebp), %eax
	addl	$4, %eax
	movl	%eax, -20(%ebp)
	movl	8(%ebp), %eax
	subl	$1, %eax
	orl	$33554432, %eax
	movl	%eax, %edx
	movl	-20(%ebp), %eax
	movl	%edx, (%eax)
	leal	12(%ebp), %eax
	movl	%eax, -32(%ebp)
	movl	$0, -28(%ebp)
	jmp	.L42
.L43:
	movl	-32(%ebp), %eax
	leal	4(%eax), %edx
	movl	%edx, -32(%ebp)
	movl	(%eax), %eax
	movl	%eax, -16(%ebp)
	movl	-20(%ebp), %eax
	leal	4(%eax), %edx
	movl	-28(%ebp), %eax
	sall	$2, %eax
	addl	%eax, %edx
	movl	-16(%ebp), %eax
	movl	%eax, (%edx)
	addl	$1, -28(%ebp)
.L42:
	movl	8(%ebp), %eax
	subl	$1, %eax
	cmpl	%eax, -28(%ebp)
	jl	.L43
	movl	-32(%ebp), %eax
	leal	4(%eax), %edx
	movl	%edx, -32(%ebp)
	movl	(%eax), %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	movl	-20(%ebp), %eax
	addl	$4, %eax
	movl	-12(%ebp), %ecx
	xorl	%gs:20, %ecx
	je	.L45
	call	__stack_chk_fail_local
.L45:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE17:
	.size	Bsexp, .-Bsexp
	.globl	Btag
	.type	Btag, @function
Btag:
.LFB18:
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
	subl	$4, %eax
	movl	%eax, -4(%ebp)
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	andl	$-16777216, %eax
	cmpl	$33554432, %eax
	jne	.L47
	movl	8(%ebp), %eax
	subl	$8, %eax
	movl	(%eax), %eax
	cmpl	%eax, 12(%ebp)
	jne	.L47
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	andl	$16777215, %eax
	cmpl	%eax, 16(%ebp)
	jne	.L47
	movl	$1, %eax
	jmp	.L48
.L47:
	movl	$0, %eax
.L48:
	addl	%eax, %eax
	orl	$1, %eax
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE18:
	.size	Btag, .-Btag
	.globl	Barray_patt
	.type	Barray_patt, @function
Barray_patt:
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
	movl	8(%ebp), %eax
	andl	$1, %eax
	testl	%eax, %eax
	je	.L51
	movl	$1, %eax
	jmp	.L52
.L51:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -4(%ebp)
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	andl	$-16777216, %eax
	cmpl	$16777216, %eax
	jne	.L53
	movl	-4(%ebp), %eax
	movl	(%eax), %eax
	andl	$16777215, %eax
	cmpl	%eax, 12(%ebp)
	jne	.L53
	movl	$1, %eax
	jmp	.L54
.L53:
	movl	$0, %eax
.L54:
	addl	%eax, %eax
	orl	$1, %eax
.L52:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE19:
	.size	Barray_patt, .-Barray_patt
	.globl	Bstring_patt
	.type	Bstring_patt, @function
Bstring_patt:
.LFB20:
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
	andl	$1, %edx
	testl	%edx, %edx
	je	.L56
	movl	$1, %eax
	jmp	.L57
.L56:
	movl	8(%ebp), %edx
	subl	$4, %edx
	movl	%edx, -16(%ebp)
	movl	12(%ebp), %edx
	subl	$4, %edx
	movl	%edx, -12(%ebp)
	movl	-16(%ebp), %edx
	movl	(%edx), %edx
	andl	$-16777216, %edx
	testl	%edx, %edx
	je	.L58
	movl	$1, %eax
	jmp	.L57
.L58:
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
	jne	.L59
	movl	$3, %eax
	jmp	.L57
.L59:
	movl	$1, %eax
.L57:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE20:
	.size	Bstring_patt, .-Bstring_patt
	.globl	Bboxed_patt
	.type	Bboxed_patt, @function
Bboxed_patt:
.LFB21:
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
	jne	.L62
	movl	$3, %eax
	jmp	.L64
.L62:
	movl	$1, %eax
.L64:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE21:
	.size	Bboxed_patt, .-Bboxed_patt
	.globl	Bunboxed_patt
	.type	Bunboxed_patt, @function
Bunboxed_patt:
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
	addl	%eax, %eax
	andl	$2, %eax
	orl	$1, %eax
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE22:
	.size	Bunboxed_patt, .-Bunboxed_patt
	.globl	Barray_tag_patt
	.type	Barray_tag_patt, @function
Barray_tag_patt:
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
	je	.L68
	movl	$1, %eax
	jmp	.L69
.L68:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$-16777216, %eax
	cmpl	$16777216, %eax
	jne	.L70
	movl	$3, %eax
	jmp	.L69
.L70:
	movl	$1, %eax
.L69:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE23:
	.size	Barray_tag_patt, .-Barray_tag_patt
	.globl	Bstring_tag_patt
	.type	Bstring_tag_patt, @function
Bstring_tag_patt:
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
	andl	$1, %eax
	testl	%eax, %eax
	je	.L73
	movl	$1, %eax
	jmp	.L74
.L73:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$-16777216, %eax
	testl	%eax, %eax
	jne	.L75
	movl	$3, %eax
	jmp	.L74
.L75:
	movl	$1, %eax
.L74:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE24:
	.size	Bstring_tag_patt, .-Bstring_tag_patt
	.globl	Bsexp_tag_patt
	.type	Bsexp_tag_patt, @function
Bsexp_tag_patt:
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
	je	.L78
	movl	$1, %eax
	jmp	.L79
.L78:
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	(%eax), %eax
	andl	$-16777216, %eax
	cmpl	$33554432, %eax
	jne	.L80
	movl	$3, %eax
	jmp	.L79
.L80:
	movl	$1, %eax
.L79:
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE25:
	.size	Bsexp_tag_patt, .-Bsexp_tag_patt
	.globl	Bsta
	.type	Bsta, @function
Bsta:
.LFB26:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$56, %esp
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	16(%ebp), %eax
	movl	%eax, -44(%ebp)
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	leal	20(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	$0, -24(%ebp)
	jmp	.L83
.L84:
	movl	-28(%ebp), %eax
	leal	4(%eax), %edx
	movl	%edx, -28(%ebp)
	movl	(%eax), %eax
	sarl	%eax
	movl	%eax, -20(%ebp)
	movl	-20(%ebp), %eax
	leal	0(,%eax,4), %edx
	movl	-44(%ebp), %eax
	addl	%edx, %eax
	movl	(%eax), %eax
	movl	%eax, -44(%ebp)
	addl	$1, -24(%ebp)
.L83:
	movl	8(%ebp), %eax
	subl	$1, %eax
	cmpl	%eax, -24(%ebp)
	jl	.L84
	movl	-28(%ebp), %eax
	leal	4(%eax), %edx
	movl	%edx, -28(%ebp)
	movl	(%eax), %eax
	sarl	%eax
	movl	%eax, -20(%ebp)
	movl	-44(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	andl	$-16777216, %eax
	testl	%eax, %eax
	jne	.L85
	movl	12(%ebp), %eax
	sarl	%eax
	movl	%eax, %ecx
	movl	-20(%ebp), %edx
	movl	-44(%ebp), %eax
	addl	%edx, %eax
	movl	%ecx, %edx
	movb	%dl, (%eax)
	jmp	.L88
.L85:
	movl	-20(%ebp), %eax
	leal	0(,%eax,4), %edx
	movl	-44(%ebp), %eax
	addl	%eax, %edx
	movl	12(%ebp), %eax
	movl	%eax, (%edx)
.L88:
	nop
	movl	-12(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L87
	call	__stack_chk_fail_local
.L87:
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE26:
	.size	Bsta, .-Bsta
	.globl	Lraw
	.type	Lraw, @function
Lraw:
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
	sarl	%eax
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE27:
	.size	Lraw, .-Lraw
	.globl	Lprintf
	.type	Lprintf, @function
Lprintf:
.LFB28:
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
	movl	%gs:20, %ecx
	movl	%ecx, -12(%ebp)
	xorl	%ecx, %ecx
	leal	12(%ebp), %edx
	movl	%edx, -16(%ebp)
	movl	-16(%ebp), %edx
	subl	$8, %esp
	pushl	%edx
	pushl	-28(%ebp)
	movl	%eax, %ebx
	call	vprintf@PLT
	addl	$16, %esp
	nop
	movl	-12(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L92
	call	__stack_chk_fail_local
.L92:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE28:
	.size	Lprintf, .-Lprintf
	.globl	Lstrcat
	.type	Lstrcat, @function
Lstrcat:
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
	movl	8(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -20(%ebp)
	movl	12(%ebp), %eax
	subl	$4, %eax
	movl	%eax, -16(%ebp)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	andl	$16777215, %eax
	movl	%eax, %edx
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	andl	$16777215, %eax
	addl	%edx, %eax
	addl	$5, %eax
	subl	$12, %esp
	pushl	%eax
	call	malloc@PLT
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	andl	$16777215, %eax
	movl	%eax, %edx
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	andl	$16777215, %eax
	addl	%eax, %edx
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
	movl	-12(%ebp), %eax
	addl	$4, %eax
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE29:
	.size	Lstrcat, .-Lstrcat
	.globl	Lfprintf
	.type	Lfprintf, @function
Lfprintf:
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
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	8(%ebp), %edx
	movl	%edx, -28(%ebp)
	movl	12(%ebp), %edx
	movl	%edx, -32(%ebp)
	movl	%gs:20, %ecx
	movl	%ecx, -12(%ebp)
	xorl	%ecx, %ecx
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
	je	.L96
	call	__stack_chk_fail_local
.L96:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE30:
	.size	Lfprintf, .-Lfprintf
	.globl	Lfopen
	.type	Lfopen, @function
Lfopen:
.LFB31:
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
.LFE31:
	.size	Lfopen, .-Lfopen
	.globl	Lfclose
	.type	Lfclose, @function
Lfclose:
.LFB32:
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
.LFE32:
	.size	Lfclose, .-Lfclose
	.section	.rodata
.LC9:
	.string	"> "
	.text
	.globl	Lread
	.type	Lread, @function
Lread:
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
	movl	%gs:20, %eax
	movl	%eax, -12(%ebp)
	xorl	%eax, %eax
	subl	$12, %esp
	leal	.LC9@GOTOFF(%ebx), %eax
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
	leal	.LC0@GOTOFF(%ebx), %eax
	pushl	%eax
	call	__isoc99_scanf@PLT
	addl	$16, %esp
	movl	-16(%ebp), %eax
	addl	%eax, %eax
	orl	$1, %eax
	movl	-12(%ebp), %edx
	xorl	%gs:20, %edx
	je	.L102
	call	__stack_chk_fail_local
.L102:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE33:
	.size	Lread, .-Lread
	.section	.rodata
.LC10:
	.string	"%d\n"
	.text
	.globl	Lwrite
	.type	Lwrite, @function
Lwrite:
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
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	movl	8(%ebp), %eax
	sarl	%eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC10@GOTOFF(%ebx), %eax
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
.LFE34:
	.size	Lwrite, .-Lwrite
	.section	.rodata
.LC11:
	.string	"Start, end: %lx, %lx\n"
.LC12:
	.string	"Root: %lx %lx %lx\n"
	.text
	.globl	__gc_root_scan_data
	.type	__gc_root_scan_data, @function
__gc_root_scan_data:
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
	movl	__gc_data_start@GOT(%ebx), %eax
	movl	%eax, -16(%ebp)
	subl	$4, %esp
	movl	__gc_data_end@GOT(%ebx), %eax
	pushl	%eax
	movl	__gc_data_start@GOT(%ebx), %eax
	pushl	%eax
	leal	.LC11@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printf@PLT
	addl	$16, %esp
	jmp	.L106
.L108:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	andl	$1, %eax
	testl	%eax, %eax
	jne	.L107
	movl	-16(%ebp), %eax
	movl	(%eax), %edx
	movl	-16(%ebp), %eax
	leal	-16(%ebp), %ecx
	pushl	%ecx
	pushl	%edx
	pushl	%eax
	leal	.LC12@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printf@PLT
	addl	$16, %esp
.L107:
	movl	-16(%ebp), %eax
	addl	$4, %eax
	movl	%eax, -16(%ebp)
.L106:
	movl	-16(%ebp), %eax
	movl	__gc_data_end@GOT(%ebx), %edx
	cmpl	%edx, %eax
	jne	.L108
	nop
	movl	-12(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L109
	call	__stack_chk_fail_local
.L109:
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE35:
	.size	__gc_root_scan_data, .-__gc_root_scan_data
	.section	.rodata
.LC13:
	.string	"STA 0x%lx\n"
	.text
	.globl	Ltest
	.type	Ltest, @function
Ltest:
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
	subl	$12, %esp
	pushl	$10
	call	putchar@PLT
	addl	$16, %esp
	movl	__start_text@GOT(%ebx), %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC13@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printf@PLT
	addl	$16, %esp
	movl	__stop_text@GOT(%ebx), %eax
	subl	$8, %esp
	pushl	%eax
	leal	.LC13@GOTOFF(%ebx), %eax
	pushl	%eax
	call	printf@PLT
	addl	$16, %esp
	call	__gc_root_scan_data
	call	__gc_root_scan_stack@PLT
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE36:
	.size	Ltest, .-Ltest
	.local	buf.3077
	.comm	buf.3077,6,4
	.section	.rodata
	.align 4
.LC14:
	.string	"_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNJPQRSTUVWXYZ"
	.section	.data.rel.local,"aw"
	.align 4
	.type	chars.3076, @object
	.size	chars.3076, 4
chars.3076:
	.long	.LC14
	.section	.text.__x86.get_pc_thunk.ax,"axG",@progbits,__x86.get_pc_thunk.ax,comdat
	.globl	__x86.get_pc_thunk.ax
	.hidden	__x86.get_pc_thunk.ax
	.type	__x86.get_pc_thunk.ax, @function
__x86.get_pc_thunk.ax:
.LFB37:
	.cfi_startproc
	movl	(%esp), %eax
	ret
	.cfi_endproc
.LFE37:
	.section	.text.__x86.get_pc_thunk.bx,"axG",@progbits,__x86.get_pc_thunk.bx,comdat
	.globl	__x86.get_pc_thunk.bx
	.hidden	__x86.get_pc_thunk.bx
	.type	__x86.get_pc_thunk.bx, @function
__x86.get_pc_thunk.bx:
.LFB38:
	.cfi_startproc
	movl	(%esp), %ebx
	ret
	.cfi_endproc
.LFE38:
	.hidden	__stack_chk_fail_local
	.ident	"GCC: (GNU) 8.2.1 20180831"
	.section	.note.GNU-stack,"",@progbits
