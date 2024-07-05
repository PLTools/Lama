UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)
    CC=gcc
else ifeq ($(UNAME_S),Darwin)
    CC=clang
    ARCH = -arch x86_64
endif

DISABLE_WARNINGS=-Wno-shift-negative-value
COMMON_FLAGS=$(DISABLE_WARNINGS) -g -fstack-protector-all $(ARCH) --std=c11
PROD_FLAGS=$(COMMON_FLAGS) -DLAMA_ENV
TEST_FLAGS=$(COMMON_FLAGS) -DDEBUG_VERSION
UNIT_TESTS_FLAGS=$(TEST_FLAGS)
INVARIANTS_CHECK_FLAGS=$(TEST_FLAGS) -DFULL_INVARIANT_CHECKS

all: gc.o runtime.o printf.o
	ar rc runtime.a runtime.o gc.o printf.o

gc.o: gc.c gc.h
	$(CC) $(PROD_FLAGS) -c gc.c -o gc.o

runtime.o: runtime.c runtime.h
	$(CC) $(PROD_FLAGS) -c runtime.c -o runtime.o

printf.o: printf.S
	$(CC) $(PROD_FLAGS) -x assembler-with-cpp -c -g printf.S -o printf.o

clean:
	$(RM) *.a *.o *~ negative_scenarios/*.err
