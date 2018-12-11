			.data
printf_format:		.string	"Stack root: %lx\n"
printf_format2:		.string	"BOT: %lx\n"
printf_format3:		.string	"TOP: %lx\n"
printf_format4:		.string	"EAX: %lx\n"
printf_format5:		.string	"LOL\n"
__gc_stack_bottom:	.long	0
__gc_stack_top:	        .long	0

			.globl	__set_w2
			.globl	__alloc_w1
			.globl	__alloc_w2
			.globl	__pre_gc
			.globl	L__gc_init
			.globl	__gc_root_scan_stack
			.extern	init_pool
			.extern	__gc_test_and_copy_root
			.text

__set_w2:
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%ecx
	pushl	%edx

	movl	8(%ebp), %ecx
	movl	12(%ebp), %edx
	subl	$8, %ecx
	movl	%edx, (%ecx)

	movl	$0, %eax
	pushl	%ecx
	pushl	%edx

	movl	%ebp, %esp 
	popl	%ebp
	ret

__alloc_w2:
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%ebx
	pushl	%ecx
	pushl	%edx
	pushl	%esi
	pushl	%edi
	
	movl	8(%ebp), %edx

	pushl	%edx
	call	alloc
	addl	$4, %esp

		pushl	$1
		pushl	$1
		pushl	$1
		pushl	$1
		pushl	$1
		addl	$20, %esp

	movl	12(%ebp), %ecx
	addl	$4, %eax
	movl	%ecx, (%eax)
	addl	$4, %eax

	popl	%ebx
	popl	%ecx
	popl	%edx
	popl	%esi
	popl	%edi

	movl	%ebp, %esp 
	popl	%ebp
	ret

__alloc_w1:
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%ebx
	pushl	%ecx
	pushl	%edx
	pushl	%esi
	pushl	%edi

	movl	4(%ebp), %edx

	pushl	%edx
	call	alloc

		pushl	$1
		pushl	$1
		pushl	$1
		pushl	$1
		pushl	$1
		addl	$20, %esp

	movl	8(%ebp), %ecx
	movl	%ecx, (%eax)
	addl	$4, %eax

	popl	%ebx
	popl	%ecx
	popl	%edx
	popl	%esi
	popl	%edi

	movl	%ebp, %esp 
	popl	%ebp
	ret

L__gc_init:		movl	%esp, __gc_stack_bottom
			addl	$4, __gc_stack_bottom
			call	init_pool
			ret

__pre_gc:
	//	movl	%ebp, __gc_stack_top
	//	ret
	
	// pushl	%eax
	// movl	(%ebp), %eax
	// movl	%eax, __gc_stack_top
	// popl	%eax

	pushl	%eax
	movl	(%ebp), %eax
	addl	$4, %eax
	movl	%eax, __gc_stack_top
	popl	%eax
	
	ret
	
__gc_root_scan_stack:
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%ebx
	pushl	%edx

//	pushl	__gc_stack_top
//	call 	Lwrite2
//	addl	$4, %esp
//	pushl	__gc_stack_bottom
//	call 	Lwrite2
//	addl	$4, %esp

//			movl	%esp, __gc_stack_top
//			movl	%esp, %eax
			movl	__gc_stack_top, %eax
			jmp 	next

loop:
			movl	(%eax), %ebx

	// check that it is not a pointer to code section
	// i.e. the following is not true:
	// __executable_start <= (%eax) <= __etext
check11:	
			leal	__executable_start, %edx
			cmpl	%ebx, %edx
			jna	check12
			jmp	check21

check12:	
			leal	__etext, %edx
			cmpl	%ebx, %edx
			jnb	next

	// check that it is not a pointer into the program stack
	// i.e. the following is not true:
	// __gc_stack_bottom <= (%eax) <= __gc_stack_top
check21:	
			cmpl	%ebx, __gc_stack_top
			jna	check22
			jmp	loop2

check22:
			cmpl	%ebx, __gc_stack_bottom
			jnb	next

	// check if it a valid pointer
	// i.e. the lastest bit is set to zero
loop2:
			andl	$0x00000001, %ebx
			jnz     next
gc_run_t:
			pushl 	%eax
//			pushl	(%eax)
  			pushl	%eax
      			call	__gc_test_and_copy_root
        		addl	$4, %esp
			popl	%eax

next:
			addl	$4, %eax
			cmpl	%eax, __gc_stack_bottom
			jne	loop
returnn:
			movl	$0, %eax
			popl	%edx
			popl	%ebx
			movl	%ebp, %esp 
			popl	%ebp
			ret
