EXECUTABLE = src/lamac
INSTALL ?= install -v
MKDIR ?= mkdir
BUILDDIR = build

.PHONY: all regression

all:
	$(MAKE) -C src
	$(MAKE) -C runtime
	$(MAKE) -C stdlib

STD_FILES=$(shell ls stdlib/*.[oi] stdlib/*.lama runtime/runtime.a runtime/Std.i)

build: all
	mkdir -p $(BUILDDIR)
	cp -r runtime/Std.i runtime/runtime.a stdlib/* src/lamac $(BUILDDIR)

install: all
	$(INSTALL) $(EXECUTABLE) `opam var bin`
	$(MKDIR) -p `opam var share`/Lama
	$(INSTALL) $(STD_FILES) `opam var share`/Lama/

uninstall:
	$(RM) -r `opam var share`/Lama
	$(RM) `opam var bin`/$(EXECUTABLE)

regression-all: regression regression-expressions

regression:
	$(MAKE) clean check -j8 -C regression
	$(MAKE) clean check -j8 -C stdlib/regression

regression-expressions:
	$(MAKE) clean check -j8 -C regression/expressions
	$(MAKE) clean check -j8 -C regression/deep-expressions

negative_scenarios_tests:
	$(MAKE) -C runtime negative_tests

clean:
	$(MAKE) clean -C src
	$(MAKE) clean -C runtime
	$(MAKE) clean -C stdlib
	$(MAKE) clean -C regression
	$(MAKE) clean -C byterun
	$(MAKE) clean -C bench
	rm -rf $(BUILDDIR)
