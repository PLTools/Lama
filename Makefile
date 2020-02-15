EXECUTABLE = src/lamac
INSTALL ?= install -v
MKDIR ?= mkdir
SHELL := /bin/bash

.PHONY: all regression

all:
	pushd src && make && popd
	pushd runtime && make && popd
	pushd stdlib && make && popd

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
	pushd regression && make clean check && popd
	pushd regression/x86only && make clean check && popd
	pushd stdlib/regression && make clean check && popd

clean:
	pushd src && make clean && popd
	pushd runtime && make clean && popd
	pushd stdlib && make clean && popd
	pushd regression && make clean && popd


