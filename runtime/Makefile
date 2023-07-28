CC=gcc
FLAGS=-m32 -g2 -fstack-protector-all -DFULL_INVARIANT_CHECKS -DLAMA_ENV

all: gc_runtime.o gc.o runtime.o
	ar rc runtime.a gc_runtime.o runtime.o gc.o

test.o: gc.c gc.h gc_runtime.s runtime.c runtime.h runtime_common.h virt_stack.c virt_stack.h test_main.c test_util.s
	$(CC) -o test.o -DDEBUG_VERSION $(FLAGS) gc.c gc_runtime.s virt_stack.c ext_arr.c runtime.c test_main.c test_util.s

virt_stack.o: virt_stack.h virt_stack.c
	$(CC) $(FLAGS) -c virt_stack.c

gc.o: gc.c gc.h
	$(CC) -rdynamic $(FLAGS) -c gc.c

gc_runtime.o: gc_runtime.s
	$(CC) $(FLAGS) -c gc_runtime.s

runtime.o: runtime.c runtime.h
	$(CC) $(FLAGS) -c runtime.c

clean:
	$(RM) *.a *.o *~
