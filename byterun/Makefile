# FLAGS=-m32 -g2 -fstack-protector-all
FLAGS=-g2 -fstack-protector-all

all: byterun.o
	$(CC) $(FLAGS) -o byterun byterun.o ../runtime/runtime.a

byterun.o: byterun.c
	$(CC) $(FLAGS) -g -c byterun.c

clean:
	$(RM) *.a *.o *~ byterun
