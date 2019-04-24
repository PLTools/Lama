	.data

filler:	.fill	6, 4, 1

	.globl	__gc_data_start

	.globl	__gc_data_end

__gc_data_start:

global_i:	.int	1

global_lists:	.int	1

__gc_data_end:

string_0:	.string	"%s\n"

	.text

	.globl	main

# LABEL ("main") / []

main:

# BEGIN ("main", [], []) / []

	pushl	%ebp
	movl	%esp,	%ebp
	subl	$Lmain_SIZE,	%esp
	movl	%esp,	%edi
	movl	$filler,	%esi
	movl	$LSmain_SIZE,	%ecx
	rep movsl	
# CALL ("L__gc_init", 0) / []

	call	L__gc_init
	addl	$0,	%esp
	movl	%eax,	%ebx
# DROP / [R (0)]

# LDA ("lists") / []

	leal	global_lists,	%ebx
# CONST (0) / [R (0)]

	movl	$1,	%ecx
# CONST (1) / [R (1); R (0)]

	movl	$3,	%esi
# CONST (2) / [R (2); R (1); R (0)]

	movl	$5,	%edi
# CONST (3) / [R (3); R (2); R (1); R (0)]

	movl	$7,	-4(%ebp)
# CONST (4) / [S (0); R (3); R (2); R (1); R (0)]

	movl	$9,	-8(%ebp)
# CONST (0) / [S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$1,	-12(%ebp)
# SEXP ("cons", 2) / [S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-16(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-16(%ebp)
	pushl	-12(%ebp)
	pushl	-8(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-8(%ebp)
# SEXP ("cons", 2) / [S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-12(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-12(%ebp)
	pushl	-8(%ebp)
	pushl	-4(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-4(%ebp)
# SEXP ("cons", 2) / [S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-8(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	-8(%ebp)
	pushl	-4(%ebp)
	pushl	%edi
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	%edi
# SEXP ("cons", 2) / [R (3); R (2); R (1); R (0)]

	movl	$848787,	-4(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	-4(%ebp)
	pushl	%edi
	pushl	%esi
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%ecx
	popl	%ebx
	movl	%eax,	%esi
# CONST (1) / [R (2); R (1); R (0)]

	movl	$3,	%edi
# CONST (0) / [R (3); R (2); R (1); R (0)]

	movl	$1,	-4(%ebp)
# SEXP ("cons", 2) / [S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-8(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	-8(%ebp)
	pushl	-4(%ebp)
	pushl	%edi
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	%edi
# CONST (2) / [R (3); R (2); R (1); R (0)]

	movl	$5,	-4(%ebp)
# CONST (3) / [S (0); R (3); R (2); R (1); R (0)]

	movl	$7,	-8(%ebp)
# CONST (0) / [S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$1,	-12(%ebp)
# SEXP ("cons", 2) / [S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-16(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-16(%ebp)
	pushl	-12(%ebp)
	pushl	-8(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-8(%ebp)
# SEXP ("cons", 2) / [S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-12(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-12(%ebp)
	pushl	-8(%ebp)
	pushl	-4(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-4(%ebp)
# CONST (4) / [S (0); R (3); R (2); R (1); R (0)]

	movl	$9,	-8(%ebp)
# CONST (5) / [S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$11,	-12(%ebp)
# CONST (6) / [S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$13,	-16(%ebp)
# CONST (0) / [S (3); S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$1,	-20(%ebp)
# SEXP ("cons", 2) / [S (4); S (3); S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-24(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-24(%ebp)
	pushl	-20(%ebp)
	pushl	-16(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-16(%ebp)
# SEXP ("cons", 2) / [S (3); S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-20(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-20(%ebp)
	pushl	-16(%ebp)
	pushl	-12(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-12(%ebp)
# CONST (0) / [S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$1,	-16(%ebp)
# SEXP ("cons", 2) / [S (3); S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-20(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-20(%ebp)
	pushl	-16(%ebp)
	pushl	-12(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-12(%ebp)
# SEXP ("cons", 2) / [S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-16(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-16(%ebp)
	pushl	-12(%ebp)
	pushl	-8(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-8(%ebp)
# CONST (0) / [S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$1,	-12(%ebp)
# SEXP ("cons", 2) / [S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-16(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-16(%ebp)
	pushl	-12(%ebp)
	pushl	-8(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-8(%ebp)
# SEXP ("cons", 2) / [S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-12(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-12(%ebp)
	pushl	-8(%ebp)
	pushl	-4(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-4(%ebp)
# SEXP ("cons", 2) / [S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-8(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	-8(%ebp)
	pushl	-4(%ebp)
	pushl	%edi
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	%edi
# CONST (1) / [R (3); R (2); R (1); R (0)]

	movl	$3,	-4(%ebp)
# CONST (2) / [S (0); R (3); R (2); R (1); R (0)]

	movl	$5,	-8(%ebp)
# CONST (3) / [S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$7,	-12(%ebp)
# CONST (4) / [S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$9,	-16(%ebp)
# CONST (0) / [S (3); S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$1,	-20(%ebp)
# SEXP ("cons", 2) / [S (4); S (3); S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-24(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-24(%ebp)
	pushl	-20(%ebp)
	pushl	-16(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-16(%ebp)
# SEXP ("cons", 2) / [S (3); S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-20(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-20(%ebp)
	pushl	-16(%ebp)
	pushl	-12(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-12(%ebp)
# SEXP ("cons", 2) / [S (2); S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-16(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-16(%ebp)
	pushl	-12(%ebp)
	pushl	-8(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-8(%ebp)
# SEXP ("cons", 2) / [S (1); S (0); R (3); R (2); R (1); R (0)]

	movl	$848787,	-12(%ebp)
	pushl	%ebx
	pushl	%ecx
	pushl	%esi
	pushl	%edi
	pushl	-12(%ebp)
	pushl	-8(%ebp)
	pushl	-4(%ebp)
	pushl	$3
	call	Bsexp
	addl	$16,	%esp
	popl	%edi
	popl	%esi
	popl	%ecx
	popl	%ebx
	movl	%eax,	-4(%ebp)
# CALL (".array", 4) / [S (0); R (3); R (2); R (1); R (0)]

	pushl	%ebx
	pushl	-4(%ebp)
	pushl	%edi
	pushl	%esi
	pushl	%ecx
	pushl	$4
	call	Barray
	addl	$20,	%esp
	popl	%ebx
	movl	%eax,	%ecx
# STI / [R (1); R (0)]

	movl	%ecx,	%eax
	movl	%eax,	(%ebx)
	movl	%eax,	%ebx
# DROP / [R (0)]

# LDA ("i") / []

	leal	global_i,	%ebx
# CONST (0) / [R (0)]

	movl	$1,	%ecx
# STI / [R (1); R (0)]

	movl	%ecx,	%eax
	movl	%eax,	(%ebx)
	movl	%eax,	%ebx
# DROP / [R (0)]

# JMP ("L55") / []

	jmp	L55
# LABEL ("L54") / []

L54:

# STRING ("%s\\n") / []

	movl	$string_0,	%ebx
	pushl	%ebx
	call	Bstring
	addl	$4,	%esp
	movl	%eax,	%ebx
# LD ("lists") / [R (0)]

	movl	global_lists,	%ecx
# LD ("i") / [R (1); R (0)]

	movl	global_i,	%esi
# CALL (".elem", 2) / [R (2); R (1); R (0)]

	pushl	%ebx
	pushl	%esi
	pushl	%ecx
	call	Belem
	addl	$8,	%esp
	popl	%ebx
	movl	%eax,	%ecx
# CALL (".stringval", 1) / [R (1); R (0)]

	pushl	%ebx
	pushl	%ecx
	call	Bstringval
	addl	$4,	%esp
	popl	%ebx
	movl	%eax,	%ecx
# CALL ("Lprintf", 2) / [R (1); R (0)]

	pushl	%ecx
	pushl	%ebx
	call	Lprintf
	addl	$8,	%esp
	movl	%eax,	%ebx
# DROP / [R (0)]

# LDA ("i") / []

	leal	global_i,	%ebx
# LD ("i") / [R (0)]

	movl	global_i,	%ecx
# CONST (1) / [R (1); R (0)]

	movl	$3,	%esi
# BINOP ("+") / [R (2); R (1); R (0)]

	addl	%esi,	%ecx
	decl	%ecx
# STI / [R (1); R (0)]

	movl	%ecx,	%eax
	movl	%eax,	(%ebx)
	movl	%eax,	%ebx
# DROP / [R (0)]

# LABEL ("L55") / []

L55:

# LD ("i") / []

	movl	global_i,	%ebx
# LD ("lists") / [R (0)]

	movl	global_lists,	%ecx
# CALL (".length", 1) / [R (1); R (0)]

	pushl	%ebx
	pushl	%ecx
	call	Blength
	addl	$4,	%esp
	popl	%ebx
	movl	%eax,	%ecx
# BINOP ("<") / [R (1); R (0)]

	xorl	%eax,	%eax
	cmpl	%ecx,	%ebx
	setl	%al
	sall	%eax
	orl	$0x0001,	%eax
	movl	%eax,	%ebx
# CJMP ("nz", "L54") / [R (0)]

	sarl	%ebx
	cmpl	$0,	%ebx
	jnz	L54
# CONST (0) / []

	movl	$1,	%ebx
# CALL ("Lraw", 1) / [R (0)]

	pushl	%ebx
	call	Lraw
	addl	$4,	%esp
	movl	%eax,	%ebx
# RET / [R (0)]

	movl	%ebx,	%eax
	jmp	Lmain_epilogue
# END / []

Lmain_epilogue:

	movl	%ebp,	%esp
	popl	%ebp
	ret
	.set	Lmain_SIZE,	24

	.set	LSmain_SIZE,	6

