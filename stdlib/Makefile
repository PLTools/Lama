FILES=$(wildcard *.expr)
ALL=$(sort $(FILES:.expr=.o))

all: $(ALL)

%.o: %.expr
	../src/rc.opt -c $<

clean:
	rm -Rf *.s *.o *.i *~

