all: byterun interpreter

interpreter: interpreter.cpp
	g++ -std=c++17 -m32 -fpermissive interpreter.cpp ../runtime/runtime.a -o interpreter

byterun: byterun.o
	$(CC) -m32 -g -o byterun byterun.o ../runtime/runtime.a
	

byterun.o: byterun.c
	$(CC) -g -fstack-protector-all -m32 -c byterun.c

# interpreter.o: interpreter.c
# 	$(CC) -g -fstack-protector-all -m32 -c interpreter.c

measure: lama all performance
	lamac -b ../performance/Sort.lama
	`which time` -f "Sort time\t%U" ./interpreter Sort.bc

lama:
	$(MAKE) -C ..

performance:
	$(MAKE) -C ../performance

clean:
	$(RM) *.a *.o *~
