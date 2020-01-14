TESTS=$(sort $(basename $(wildcard test*.expr)))

RC=../src/rc.opt

.PHONY: check $(TESTS)

check: $(TESTS)

$(TESTS): %: %.expr
	@echo $@
	cat $@.input | $(RC) -i $< > $@.log && diff $@.log orig/$@.log
	cat $@.input | $(RC) -s $< > $@.log && diff $@.log orig/$@.log
	$(RC) $< && cat $@.input | ./$@ > $@.log && diff $@.log orig/$@.log

clean:
	$(RM) test*.log *.s *~ $(TESTS) *.i
	$(MAKE) clean -C expressions
	$(MAKE) clean -C deep-expressions
	$(MAKE) clean -C x86only
