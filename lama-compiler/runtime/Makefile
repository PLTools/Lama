all: runtime.o

runtime.o: runtime.c
	gcc -g -m32 -no-pie -c runtime.c

clean:
	rm -f *.a *.o *~
