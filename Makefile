SHELL := /bin/bash

.PHONY: all regression

all:
	pushd src && make && popd
	pushd runtime && make && popd
	pushd stdlib && make && popd

#install: ;

regression:
	pushd regression && make clean check && popd
	pushd regression/x86only && make clean check && popd
	pushd stdlib/regression && make clean check && popd

clean:
	pushd src && make clean && popd
	pushd runtime && make clean && popd
	pushd stdlib && make clean && popd
	pushd regression && make clean && popd


