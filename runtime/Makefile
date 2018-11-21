all: gc_runtime.o runtime.o
	ar rc runtime.a gc_runtime.o runtime.o 

gc_runtime.o: gc_runtime.s
	gcc -g -m32 -c gc_runtime.s

runtime.o: runtime.c
	gcc -g -m32 -c runtime.c

clean:
	rm -f *.a *.o *~

