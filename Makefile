SHELL := /bin/bash

.PHONY: all

all:
	pushd src && make && popd

clean:
	pushd src && make clean && popd

