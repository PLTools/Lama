EXECUTABLE = src/lamac
INSTALL ?= install -v
MKDIR ?= mkdir

.PHONY: all regression

all:
	$(MAKE) -C src
	$(MAKE) -C runtime
	$(MAKE) -C byterun
	$(MAKE) -C stdlib

STD_FILES=$(shell ls stdlib/*.[oi] stdlib/*.lama runtime/runtime.a runtime/Std.i)

install: all
	$(INSTALL) $(EXECUTABLE) `opam var bin`
	$(MKDIR) -p `opam var share`/Lama
	$(INSTALL) $(STD_FILES) `opam var share`/Lama/

uninstall:
	$(RM) -r `opam var share`/Lama
	$(RM) `opam var bin`/$(EXECUTABLE)

regression-all: regression regression-expressions regression-lama-in-lama

regression:
	$(MAKE) clean check -j8 -C regression
	$(MAKE) clean check -j8 -C stdlib/regression

regression-expressions:
	$(MAKE) clean check -j8 -C regression/expressions
	$(MAKE) clean check -j8 -C regression/deep-expressions

regression-lama-in-lama: all
	mkdir tmp-lama
	cp runtime/Std.i tmp-lama
	cp runtime/runtime.a tmp-lama
	cp -R stdlib/* tmp-lama
	$(MAKE) -C lama-compiler

clean:
	$(MAKE) clean -C src
	$(MAKE) clean -C runtime
	$(MAKE) clean -C stdlib
	$(MAKE) clean -C regression
	$(MAKE) clean -C byterun
	$(MAKE) clean -C bench
	$(MAKE) clean -C lama-compiler
	if [ -d tmp-lama ]; then rm -Rf tmp-lama; fi
