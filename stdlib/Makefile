SHELL := /bin/bash

FILES=$(wildcard *.lama)
ALL=$(sort $(FILES:.lama=.o))
LAMAC=../src/lamac

all: $(ALL)

Fun.o: Ref.o

Data.o: Ref.o Collection.o

Collection.o: List.o Ref.o

Array.o: List.o

Ostap.o: List.o Collection.o Ref.o Fun.o Matcher.o

Buffer.o: List.o

STM.o: List.o Fun.o

%.o: %.lama
	LAMA=../runtime $(LAMAC) -I . -c $<

clean:
	rm -Rf *.s *.o *.i *~
	pushd regression && make clean && popd

