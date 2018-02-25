TESTS=test001 test002 test003 test004 test005 test006 test007 test008

RC=../src/rc.opt

.PHONY: check $(TESTS) 

check: $(TESTS) 

$(TESTS): %: %.expr
	cat $@.input | $(RC) -i $< > $@.log && diff $@.log orig/$@.log
	cat $@.input | $(RC) -s $< > $@.log && diff $@.log orig/$@.log

clean:
	rm -f test*.log *.s *~ $(TESTS)
