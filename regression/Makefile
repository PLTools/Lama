TESTS=test001 test002 test003 test004 test005 test006 test007 test008 test009 test010 test011 test012 test013 test014 test015 test016 test017 test018 test019 test020 test021 test022 test023 test024 test025 test026 test027 test028 test029

RC=../src/rc.opt

.PHONY: check $(TESTS) 

check: $(TESTS)

$(TESTS): %: %.expr
#	@$(RC) $< && cat $@.input | ./$@ > $@.log && diff $@.log orig/$@.log
	@cat $@.input | $(RC) -i $< > $@.log && diff $@.log orig/$@.log
	@cat $@.input | $(RC) -s $< > $@.log && diff $@.log orig/$@.log

clean:
	rm -f test*.log *.s *~ $(TESTS)
