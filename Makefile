EXECUTABLE = src/lamac
INSTALL ?= install -v
MKDIR ?= mkdir
SHELL := /bin/bash

.PHONY: all regression

all:
	make -C src 
	make -C runtime 
	make -C stdlib

STD_FILES=$(shell ls stdlib/*.[oi] stdlib/*.lama runtime/runtime.a runtime/Std.i)
#$(info $(STD_FILES))

install: all
	$(INSTALL) $(EXECUTABLE) `opam var bin`
	$(MKDIR) -p `opam var share`/Lama
	$(INSTALL) $(STD_FILES) `opam var share`/Lama/

uninstall:
	$(RM) -r `opam var share`/Lama
	$(RM) `opam var bin`/$(EXECUTABLE)

regression:
	make clean check -C regression
	make clean check -C stdlib/regression

clean:
	make clean -C src
	make clean -C runtime
	make clean -C stdlib
	make clean -C regression
	$(MAKE) clean -C bench

