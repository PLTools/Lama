CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2
TARGET = interpreter.exe
SOURCES = interpreter.c bytecode.c stack.c call_stack.c opcodes.c
HEADERS = opcodes.h bytecode.h stack.h call_stack.h
OBJECTS = $(SOURCES:.c=.o)

RUNTIME_DIR = ../runtime
RUNTIME_LIB = $(RUNTIME_DIR)/runtime.a

all: $(TARGET)

debug: CFLAGS += -DDEBUG_PRINT -g3 -Og
debug: clean all

$(TARGET): $(OBJECTS) $(RUNTIME_LIB)
	$(CC) -o $@ $^

$(RUNTIME_LIB):
	$(MAKE) -C $(RUNTIME_DIR)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: all debug clean distclean

interpreter.o: interpreter.c bytecode.h opcodes.h stack.h call_stack.h
bytecode.o: bytecode.c bytecode.h
stack.o: stack.c stack.h
call_stack.o: call_stack.c call_stack.h
opcodes.o: opcodes.c opcodes.h
