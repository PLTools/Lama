# compiler-workout

Supplementary repository for compiler course.

Prerequisites: ocaml [http://ocaml.org], opam [http://opam.ocaml.org].

Building:

* `opam pin add GT https://github.com/dboulytchev/GT.git`
* `opam pin add ostap https://github.com/dboulytchev/ostap.git`
* `opam install ostap`
* `opam install GT`
* To build the sources: `make` from the top project directory
* To test: `test.sh` from `regression` subfolder
