TESTS=$(sort $(basename $(wildcard test*.lama)))

LAMAC=../../src/lamac

.PHONY: check $(TESTS)

check: $(TESTS)

$(TESTS): %: %.lama
	@echo $@
	LAMA=../../runtime $(LAMAC) -I .. -ds -dp $< && ./$@ > $@.log && diff $@.log orig/$@.log

clean:
	$(RM) test*.log *.s *~ $(TESTS) *.i
