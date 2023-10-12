# this is equivalent C-signature for this function
# size_t call_runtime_function(void *stack, void *func_ptr, int num_args, ...)

    .globl call_runtime_function
    .type call_runtime_function, @function
call_runtime_function:
    pushl %ebp
    movl %esp, %ebp

    # store old stack pointer
    movl %esp, %edi

    # move esp to point to the virtual stack
    movl 8(%ebp), %esp

    # push arguments onto the stack
    movl 16(%ebp), %ecx   # num_args
    test %ecx, %ecx
    jz f_call # in case function doesn't have any parameters

    leal 16(%ebp), %eax   # pointer to value BEFORE first argument
    leal (%eax,%ecx,4), %edx   # pointer to last argument (right-to-left)

push_args_loop:
    pushl (%edx)
    subl $4, %edx
    subl $1, %ecx
    jnz push_args_loop

    # call the function
f_call:
    movl 12(%ebp), %eax
    call *%eax

    # restore the old stack pointer
    movl %edi, %esp

    # pop the old frame pointer and return
    popl %ebp            # epilogue
    ret
