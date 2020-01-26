TESTS=$(sort $(basename $(wildcard test*.expr)))
LIBS=$(patsubst %.expr,%.o, $(sort $(wildcard Lib*.expr)))

RC=../../src/rc.opt

.PHONY: check $(TESTS) 

check: $(TESTS)

%.o: %.expr
	RC_RUNTIME=../../runtime $(RC) -c -I . $<

$(TESTS): %: %.expr $(LIBS)
	RC_RUNTIME=../../runtime $(RC) -I . $< && cat $@.input | ./$@ > $@.log && diff -u $@.log orig/$@.log

clean:
	rm -f test*.log *.i *.o *.s *~ $(TESTS)
