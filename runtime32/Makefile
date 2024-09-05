RUNTIME=runtime.a

.DEFAULT  := $(RUNTIME)

$(RUNTIME): gc_runtime.o runtime.o
	ar rc $@ gc_runtime.o runtime.o

gc_runtime.o: gc_runtime.s
	$(CC) -g -fstack-protector-all -m32 -c gc_runtime.s

runtime.o: runtime.c runtime.h
	$(CC) -g -fstack-protector-all -m32 -c runtime.c

clean:
	$(RM) *.a *.o *~
