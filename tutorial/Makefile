SHELL := /bin/bash

FILES=$(wildcard *.lama)
ALL=$(sort $(FILES:.lama=))
LAMAC=../src/lamac

all: $(ALL)

%: %.lama
	$(LAMAC) $<

clean:
	rm -Rf *.s *.o *.i *~ $(ALL)
