TESTS=$(sort $(basename $(wildcard test*.lama)))

LAMAC=../src/lamac

.PHONY: check $(TESTS)

check: $(TESTS)

$(TESTS): %: %.lama
	@echo $@
	cat $@.input | $(LAMAC) -i $< > $@.log && diff $@.log orig/$@.log
	cat $@.input | $(LAMAC) -s $< > $@.log && diff $@.log orig/$@.log
	$(LAMAC) $< && cat $@.input | ./$@ > $@.log && diff $@.log orig/$@.log

clean:
	$(RM) test*.log *.s *~ $(TESTS) *.i
	$(MAKE) clean -C expressions
	$(MAKE) clean -C deep-expressions
	$(MAKE) clean -C x86only
