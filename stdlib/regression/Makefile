TESTS=$(sort $(basename $(wildcard test*.expr)))

RC=../../src/rc.opt

.PHONY: check $(TESTS)

check: $(TESTS)

$(TESTS): %: %.expr
	@echo $@
	RC_RUNTIME=../../runtime $(RC) -I .. $< && ./$@ > $@.log && diff $@.log orig/$@.log

clean:
	$(RM) test*.log *.s *~ $(TESTS)
