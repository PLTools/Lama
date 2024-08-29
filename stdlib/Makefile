.PHONY: all

SHELL := /bin/bash
FILES=$(wildcard *.lama)
ALL=$(sort $(FILES:.lama=.o))
LAMAC ?= ../src/lamac
BDIR ?= .

all: $(addprefix $(BDIR)/,$(ALL))

Fun.o: Ref.o

Data.o: Ref.o Collection.o

Collection.o: List.o Ref.o

$(BDIR)/Array.o: $(BDIR)/List.o

Ostap.o: List.o Collection.o Ref.o Fun.o Matcher.o

$(BDIR)/Buffer.o: $(BDIR)/List.o

$(BDIR)/STM.o: $(BDIR)/List.o $(BDIR)/Fun.o

$(BDIR)/%.o: %.lama
	LAMA=../runtime $(LAMAC) -g -I . -c $< -o $@

clean:
	$(RM) -r *.s *.o *.i *~
	pushd regression && make clean && popd

