SHELL := /bin/bash

FILES=$(wildcard *.expr)
ALL=$(sort $(FILES:.expr=.o))
RC=../src/rc.opt

all: $(ALL)

Fun.o: Ref.o

Collection.o: List.o Ref.o

Array.o: List.o

Ostap.o: List.o Collection.o Ref.o Fun.o Matcher.o

Expr.o: Ostap.o

%.o: %.expr
	$(RC) -I . -c $<

clean:
	rm -Rf *.s *.o *.i *~
	pushd regression && make clean && popd

