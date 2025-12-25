CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2 -g

TARGET = interpreter
SOURCES = interpreter.c bytecode.c
HEADERS = opcodes.h bytecode.h
OBJECTS = $(SOURCES:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) -o $@ $^

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: all clean distclean

interpreter.o: interpreter.c bytecode.h opcodes.h
bytecode.o: bytecode.c bytecode.h
