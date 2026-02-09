CC = gcc
#TODO: O2 doesn't work
CFLAGS = -Wall -Wextra -std=c99 -O0
LIBS = -lffi -ldl
LDFLAGS = -rdynamic
TARGET = lama.exe
SOURCES = lama.c decoder.c vm.c bytecode.c linker.c ffi.c module_manager.c arena.c
OBJECTS = $(SOURCES:.c=.o)

RUNTIME_DIR = ../runtime
RUNTIME_LIB = $(RUNTIME_DIR)/runtime.a

all: $(TARGET)

debug: CFLAGS += -DDEBUG_PRINT -g3 -Og -O0
debug: $(TARGET)

$(TARGET): $(OBJECTS) $(RUNTIME_LIB)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJECTS) -Wl,--whole-archive $(RUNTIME_LIB) -Wl,--no-whole-archive $(LIBS)

$(RUNTIME_LIB):
	$(MAKE) LAMA_ENV=0 -C $(RUNTIME_DIR)

%.o: %.c
	$(CC) $(CFLAGS) $(DEPFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET) $(OBJECTS:.o=.d)
	$(MAKE) -C $(RUNTIME_DIR) clean

.PHONY: all debug clean
