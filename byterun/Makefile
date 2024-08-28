FLAGS=-m32 -g2 -fstack-protector-all

all: byterun.o eval.o
	$(CC) $(FLAGS) -no-pie -o byterun byterun.o eval.o ../runtime/runtime.a

byterun.o: byterun.c
	$(CC) $(FLAGS) -no-pie -g -c byterun.c

eval.o: eval.s
	$(CC) $(FLAGS) -c eval.s

clean:
	$(RM) *.a *.o *~ byterun
