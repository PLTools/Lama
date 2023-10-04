CC=gcc
COMMON_FLAGS=-m32 -g2 -fstack-protector-all
PROD_FLAGS=$(COMMON_FLAGS) -DLAMA_ENV
TEST_FLAGS=$(COMMON_FLAGS) -DDEBUG_VERSION
UNIT_TESTS_FLAGS=$(TEST_FLAGS)
INVARIANTS_CHECK_FLAGS=$(TEST_FLAGS) -DFULL_INVARIANT_CHECKS

# this target is the most important one, its' artefacts should be used as a runtime of Lama
all: gc.o runtime.o
	ar rc runtime.a runtime.o gc.o

NEGATIVE_TESTS=$(sort $(basename $(notdir $(wildcard negative_scenarios/*_neg.c))))

$(NEGATIVE_TESTS): %: negative_scenarios/%.c
	@echo "Running test $@"
	@$(CC) -o $@.o $(COMMON_FLAGS) negative_scenarios/$@.c gc.c
	@./$@.o 2> negative_scenarios/$@.err || diff negative_scenarios/$@.err negative_scenarios/expected/$@.err

negative_tests: $(NEGATIVE_TESTS)

# this is a target that runs unit tests, scenarios are written in a single file `test_main.c`
unit_tests.o: gc.c gc.h runtime.c runtime.h runtime_common.h virt_stack.c virt_stack.h test_main.c test_util.s
	$(CC) -o unit_tests.o $(UNIT_TESTS_FLAGS) gc.c virt_stack.c runtime.c test_main.c test_util.s

# this target also runs unit tests but with additional expensive checks of GC invariants which aren't used in production version
invariants_check.o: gc.c gc.h runtime.c runtime.h runtime_common.h virt_stack.c virt_stack.h test_main.c test_util.s
	$(CC) -o invariants_check.o $(INVARIANTS_CHECK_FLAGS) gc.c virt_stack.c runtime.c test_main.c test_util.s

# this target also runs unit tests but with additional expensive checks of GC invariants which aren't used in production version
# additionally, it prints debug information
invariants_check_debug_print.o: gc.c gc.h runtime.c runtime.h runtime_common.h virt_stack.c virt_stack.h test_main.c test_util.s
	$(CC) -o invariants_check_debug_print.o $(INVARIANTS_CHECK_FLAGS) -DDEBUG_PRINT gc.c virt_stack.c runtime.c test_main.c test_util.s

virt_stack.o: virt_stack.h virt_stack.c
	$(CC) $(PROD_FLAGS) -c virt_stack.c

gc.o: gc.c gc.h
	$(CC) -rdynamic $(PROD_FLAGS) -c gc.c

runtime.o: runtime.c runtime.h
	$(CC) $(PROD_FLAGS) -c runtime.c

clean:
	$(RM) *.a *.o *~ negative_scenarios/*.err
