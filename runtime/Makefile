CC=gcc

all: gc_runtime.o gc.o runtime.o
	ar rc runtime.a gc_runtime.o runtime.o gc.o

test.o: gc.c gc.h gc_runtime.s runtime.c runtime.h runtime_common.h virt_stack.c virt_stack.h test_main.c test_util.s
	$(CC) -o test.o -g2 -fstack-protector-all -DDEBUG_VERSION -m32 gc.c gc_runtime.s virt_stack.c runtime.c test_main.c test_util.s

virt_stack.o: virt_stack.h virt_stack.c
	$(CC) -g2 -fstack-protector-all -m32 -c virt_stack.c

gc.o: gc.c gc.h
	$(CC) -g2 -rdynamic -fstack-protector-all -m32 -c gc.c

gc_runtime.o: gc_runtime.s
	$(CC) -g2 -fstack-protector-all -m32 -c gc_runtime.s

runtime.o: runtime.c runtime.h
	$(CC) -g2 -fstack-protector-all -m32 -c runtime.c

clean:
	$(RM) *.a *.o *~
