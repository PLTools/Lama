TESTS=$(sort $(basename $(wildcard generated*.lama)))

LAMAC = ../../src/lamac

.PHONY: check $(TESTS)

check: $(TESTS)

$(TESTS): %: %.lama
	@echo "regression/deep-expressions/$@"
	@LAMA=../../runtime $(LAMAC) $< && cat $@.input | ./$@ > $@.log && diff $@.log orig/$@.log
	@cat $@.input | LAMA=../../runtime $(LAMAC) -i $< > $@.log && diff $@.log orig/$@.log
	@cat $@.input | LAMA=../../runtime $(LAMAC) -s $< > $@.log && diff $@.log orig/$@.log

clean:
	rm -f *.log *.s *~
	find . -maxdepth 1 -type f -not -name '*.*' -not -name 'Makefile' -delete
