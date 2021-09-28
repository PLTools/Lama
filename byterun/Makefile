all: byterun.o
	$(CC) -m32 -g -o byterun byterun.o ../runtime/runtime.a 

byterun.o: byterun.c
	$(CC) -g -fstack-protector-all -m32 -c byterun.c

clean:
	$(RM) *.a *.o *~
