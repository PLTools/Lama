TESTS=$(basename $(wildcard test*.expr))

RC=../src/rc.opt

.PHONY: check $(TESTS) 

check: $(TESTS)

$(TESTS): %: %.expr
	@$(RC) $< && cat $@.input | ./$@ > $@.log && diff $@.log orig/$@.log
	cat $@.input | $(RC) -i $< > $@.log && diff $@.log orig/$@.log
	cat $@.input | $(RC) -s $< > $@.log && diff $@.log orig/$@.log

clean:
	rm -f test*.log *.s *~ $(TESTS)
