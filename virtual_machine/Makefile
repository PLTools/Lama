CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O3
LIBS = -lffi -ldl
LDFLAGS = -rdynamic
BUILD_DIR = .vm-build
TARGET = lama.exe
SOURCES = lama.c converter.c vm.c bytecode.c ffi.c loader.c symbols.c ops.c memory.c opcodes.c
OBJECTS = $(addprefix $(BUILD_DIR)/,$(SOURCES:.c=.o))

RUNTIME_DIR = ../runtime
RUNTIME_LIB = $(BUILD_DIR)/runtime/runtime.a

all: $(TARGET)

debug: CFLAGS += -DDEBUG_PRINT -g3 -Og -O0 -fsanitize=address
debug: $(TARGET)

$(TARGET): $(OBJECTS) $(RUNTIME_LIB) | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJECTS) -Wl,--whole-archive $(RUNTIME_LIB) -Wl,--no-whole-archive $(LIBS)

$(RUNTIME_LIB):
	$(MAKE) -C $(RUNTIME_DIR) LAMA_ENV=0 BUILD_DIR=$(abspath $(BUILD_DIR)/runtime)

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)
	$(MAKE) -C $(RUNTIME_DIR) BUILD_DIR=$(abspath $(BUILD_DIR)/runtime) clean

.PHONY: all debug clean
