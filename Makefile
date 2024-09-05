.PHONY: all regression
.PHONY: clean test regression regression-expressions regression-all uninstall install build

INSTALL ?= install -v
MKDIR ?= mkdir
BUILDDIR = _build

.DEFAULT_GOAL := build

all: build test

build:
	dune b src runtime runtime32 stdlib

install: all
	dune b @install --profile=release
	dune    install --profile=release
	$(MKDIR) -p `opam var share`/Lama/x64
	$(INSTALL) $(shell ls _build/default/stdlib/x64/*.[oi] _build/default/stdlib/x64/stdlib/*.lama \
		runtime/runtime.a runtime/Std.i) \
		`opam var share`/Lama/x64
	$(MKDIR) -p `opam var share`/Lama/x32
	$(INSTALL) $(shell ls _build/default/stdlib/x32/*.[oi] _build/default/stdlib/x32/stdlib/*.lama \
		runtime32/runtime.a runtime32/Std.i) \
		`opam var share`/Lama/x32

uninstall:
	$(RM) -r `opam var share`/Lama
	dune uninstall


regression-all: regression regression-expressions

test: regression
regression:
	dune test regression

regression-expressions:
	dune test regression_long

clean:
	@dune clean

