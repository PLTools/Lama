TESTS=$(sort $(basename $(wildcard test*.lama)))
LOGS=$(TESTS:=.log)

LAMAC=../src/lama-impl
RM=rm -rf

.PHONY: check $(TESTS)

check: $(TESTS) expr_tests

$(TESTS): %: %.lama
	@echo $@
	@ulimit -s -S 32768; cat $@.input | $(LAMAC) $@.lama -i > $@.log && diff $@.log orig/$@.log 
	@ulimit -s -S 32768; cat $@.input | $(LAMAC) $@.lama -s > $@.log && diff $@.log orig/$@.log
	$(LAMAC) $@.lama && cat $@.input | ./$@ > $@.log && diff $@.log orig/$@.log

expr_tests:
	make -C expressions
	make -C deep-expressions

clean:
	$(RM) *.s *.i *~ $(LOGS) $(TESTS) *.run *.sm
	make -C expressions clean
	make -C deep-expressions clean
