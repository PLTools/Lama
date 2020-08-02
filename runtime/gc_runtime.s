			.data
printf_format:		.string	"Stack root: %lx\n"
printf_format2:		.string	"BOT: %lx\n"
printf_format3:		.string	"TOP: %lx\n"
printf_format4:		.string	"EAX: %lx\n"
printf_format5:		.string	"LOL\n"
__gc_stack_bottom:	.long	0
__gc_stack_top:	        .long	0

			.globl	__pre_gc
			.globl	__post_gc
			.globl	__gc_init
			.globl	__gc_root_scan_stack
			.globl	__gc_stack_top
			.globl	__gc_stack_bottom
			.extern	init_pool
			.extern	gc_test_and_copy_root
			.text

__gc_init:		movl	%ebp, __gc_stack_bottom
			addl	$4, __gc_stack_bottom
			call	__init
			ret

	// if __gc_stack_top is equal to 0
	// then set __gc_stack_top to %ebp
	// else return
__pre_gc:
			pushl	%eax
			movl	__gc_stack_top, %eax
			cmpl	$0, %eax
			jne	__pre_gc_2
			movl	%ebp, %eax
			// addl	$8, %eax
			movl	%eax, __gc_stack_top
__pre_gc_2:
			popl	%eax
			ret

	// if __gc_stack_top has been set by the caller
	//   (i.e. it is equal to its %ebp)
	// then set __gc_stack_top to 0
	// else return
__post_gc:
			pushl	%eax
			movl	__gc_stack_top, %eax
			cmpl	%eax, %ebp
			jnz	__post_gc2
			movl	$0, __gc_stack_top
__post_gc2:
			popl	%eax
			ret
	
	// Scan stack for roots
	// strting from __gc_stack_top
	// till __gc_stack_bottom
__gc_root_scan_stack:
			pushl	%ebp
			movl	%esp, %ebp
			pushl	%ebx
			pushl	%edx
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
  			pushl	%eax
      			call	gc_test_and_copy_root
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
