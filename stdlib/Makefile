SHELL := /bin/bash

FILES=$(wildcard *.expr)
ALL=$(sort $(FILES:.expr=.o))
RC=../src/rc.opt

all: $(ALL)

Collection.o: List.o

Array.o: List.o

%.o: %.expr
	$(RC) -I . -c $<

clean:
	rm -Rf *.s *.o *.i *~
	pushd regression && make clean && popd

