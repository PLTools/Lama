TESTS=$(basename $(wildcard test*.expr))

RC=../../src/rc.opt

.PHONY: check $(TESTS) 

check: $(TESTS)

$(TESTS): %: %.expr
	@RC_RUNTIME=../../runtime $(RC) $< && cat $@.input | ./$@ > $@.log && diff -u $@.log orig/$@.log

clean:
	rm -f test*.log *.s *~ $(TESTS)
