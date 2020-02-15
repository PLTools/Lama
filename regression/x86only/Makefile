TESTS=$(sort $(basename $(wildcard test*.lama)))
LIBS=$(patsubst %.lama,%.o, $(sort $(wildcard Lib*.lama)))

LAMAC=../../src/lamac

.PHONY: check $(TESTS) 

check: $(TESTS)

%.o: %.lama
	LAMA=../../runtime $(LAMAC) -c -I . $<

$(TESTS): %: %.lama $(LIBS)
	LAMA=../../runtime $(LAMAC) -I . $< && cat $@.input | ./$@ > $@.log && diff -u $@.log orig/$@.log

clean:
	rm -f test*.log *.i *.o *.s *~ $(TESTS)
