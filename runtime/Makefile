UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)
    CC=gcc
else ifeq ($(UNAME_S),Darwin)
    CC=clang
    ARCH = -arch x86_64
endif

LAMA_ENV ?= 1
BUILD_DIR ?= .

# Virtual machine doesn't work well with this parameter
ifeq ($(LAMA_ENV), 1)
   	ENV_FLAGS := -DLAMA_ENV
else
	  ENV_FLAGS := 
endif

DISABLE_WARNINGS=-Wno-shift-negative-value
COMMON_FLAGS=$(DISABLE_WARNINGS) -g -fstack-protector-all $(ARCH) --std=c11
PROD_FLAGS=$(COMMON_FLAGS) $(ENV_FLAGS)
TEST_FLAGS=$(COMMON_FLAGS) -DDEBUG_VERSION
UNIT_TESTS_FLAGS=$(TEST_FLAGS)
INVARIANTS_CHECK_FLAGS=$(TEST_FLAGS) -DFULL_INVARIANT_CHECKS

all: $(BUILD_DIR)/gc.o $(BUILD_DIR)/runtime.o $(BUILD_DIR)/printf.o
	ar rc $(BUILD_DIR)/runtime.a $(BUILD_DIR)/runtime.o $(BUILD_DIR)/gc.o $(BUILD_DIR)/printf.o

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/gc.o: gc.c gc.h | $(BUILD_DIR)
	$(CC) $(PROD_FLAGS) -c gc.c -o $(BUILD_DIR)/gc.o

$(BUILD_DIR)/runtime.o: runtime.c runtime.h | $(BUILD_DIR)
	$(CC) $(PROD_FLAGS) -c runtime.c -o $(BUILD_DIR)/runtime.o

$(BUILD_DIR)/printf.o: printf.S | $(BUILD_DIR)
	$(CC) $(PROD_FLAGS) -Wa,--noexecstack -x assembler-with-cpp -c -g printf.S -o $(BUILD_DIR)/printf.o

clean:
	$(RM) $(BUILD_DIR)/*.a $(BUILD_DIR)/*.o *~ negative_scenarios/*.err
