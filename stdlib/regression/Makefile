TESTS=$(sort $(filter-out test02 test30, $(basename $(wildcard test*.lama))))

LAMAC=../../src/lamac

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)
else ifeq ($(UNAME_S),Darwin)
    ARCH = arch -x86_64
endif

.PHONY: check $(TESTS)

check: $(TESTS)

$(TESTS): %: %.lama
	@echo "stdlib/regression/$@"
	@LAMA=../../runtime $(LAMAC) -I .. -ds -dp $< && $(ARCH) ./$@ > $@.log && diff $@.log orig/$@.log

clean:
	$(RM) test*.log *.s *~ $(TESTS) *.i
