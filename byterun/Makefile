all: byterun.o interpreter.o
	$(CC) -m32 -g -o byterun byterun.o ../runtime/runtime.a
	$(CC) -m32 -g -o interpreter interpreter.o ../runtime/runtime.a

byterun.o: byterun.c
	$(CC) -g -fstack-protector-all -m32 -c byterun.c

interpreter.o: interpreter.c
	$(CC) -g -fstack-protector-all -m32 -c interpreter.c

clean:
	$(RM) *.a *.o *~
