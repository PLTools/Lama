TESTS=$(sort $(basename $(wildcard generated*.lama)))

RC = ../../src/lamac

.PHONY: check $(TESTS)

check: $(TESTS)

$(TESTS): %: %.lama
	@echo "regression/expressions/$@"
	@LAMA=../../runtime $(RC) $< && cat $@.input | ./$@ > $@.log && diff $@.log orig/$@.log
#	@cat $@.input | LAMA=../../runtime $(RC) -i $< > $@.log && diff $@.log orig/$@.log
#	@cat $@.input | LAMA=../../runtime $(RC) -s $< > $@.log && diff $@.log orig/$@.log

clean:
	rm -f *.log *.s *~
	find . -maxdepth 1 -type f -not -name '*.*' -not -name 'Makefile' -delete

