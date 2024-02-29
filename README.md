| Lama         1.2    |
| ------------------- |
| [![Lama 1.2][1]][2] |

[1]:  https://github.com/PLTools/Lama/workflows/Build/badge.svg?branch=1.10
[2]:  https://github.com/PLTools/Lama/actions

# Lama

![lama](lama.svg) is a programming language developed by JetBrains Research for educational purposes as an exemplary language to introduce the domain of programming languages, compilers, and tools.
Its general characteristics are:

* procedural with first-class functions - functions can be passed as arguments, placed in data structures,
  returned and "constructed" at runtime via closure mechanism;
* with lexical static scoping;
* strict - all arguments of function application are evaluated before a function body;
* imperative - variables can be re-assigned, function calls can have side effects;
* untyped - no static type checking is performed;
* with S-expressions and pattern-matching;
* with user-defined infix operators, including those defined in local scopes;
* with automatic memory management (garbage collection).

The name ![lama](lama.svg) is an acronym for *Lambda-Algol* since the language has borrowed the syntactic shape of operators from **Algol-68**; [**Haskell**](http://www.haskell.org) and [**OCaml**](http://ocaml.org) can be mentioned as other languages of inspiration.

The main purpose of ![lama](lama.svg) is to present a repertoire of constructs with certain runtime behavior and relevant implementation techniques.
The lack of a type system (a vital feature for a real-world language
for software engineering) is an intensional decision that allows showing the unchained diversity of runtime behaviors, including those that a typical type system is called to prevent.
On the other hand the language can be used in the future as a raw substrate to apply various ways of software verification (including type systems).

The current implementation contains a native code compiler for **x86-32**, written in **OCaml**, a runtime library with garbage-collection support, written in **C**, and a small standard library, written in ![lama](lama.svg) itself.
The native code compiler uses **gcc** as a toolchain.

In addition, a source-level reference interpreter is implemented as well as a compiler to a small stack machine.
The stack machine code can in turn be either interpreted on a stack machine interpreter, or used as an intermediate representation by the native code compiler.

## Language Specification

The language specification can be found [here](lama-spec.pdf).

## Installation

Supported target: GNU/Linux x86_32 (x86_64 by running 32-bit mode)

***Mac*** users should connect by ssh to the docker container docker with a Linux distributive inside.

***Windows*** users should get Windows Subsystem for Linux a.k.a WSL (recommended) or cygwin.
Ubuntu-based variant of WSL is recommended.

* System-wide prerequisites:

  - `gcc-multilib`

    For example, (for Debian-based GNU/Linux):
    ```bash
    sudo apt install gcc-multilib
    ```

     On some versions, you need to install the additional package `lib32gcc-V-dev` (where `V` is output of `gcc --version`, e. g. `sudo apt install lib32gcc-9-dev`) in case of errors like
       ```
      /usr/bin/ld: cannot find -lgcc
      /usr/bin/ld: skipping incompatible /usr/lib/gcc/x86_64-linux-gnu/9/libgcc.a when searching for -lgcc
       ```
  - [opam](http://opam.ocaml.org) (>= 2.0.4)
  - [OCaml](http://ocaml.org) (>= 4.10.1). *Optional* because it can be easily installed through opam.
  Compiler variant with `flambda` switch is recommended.

* Check that `opam` is installed (using commands `which opam` or `opam --version`)

**Installation guide**

1. Install the right [switch](https://opam.ocaml.org/doc/Manual.html#Switches) for the OCaml compiler

    for fresh opam
    ```bash
    opam switch create lama --packages=ocaml-variants.4.14.0+options,ocaml-option-flambda
    ```
    for old opam
    ```bash
    opam switch create lama ocaml-variants.4.13.1+flambda
    ```

    * In the above command:

      - `opam switch create` is a subcommand to create a new switch
      - `ocaml-variants.4.14.0+flambda` is the name of a standard template for the switch
      - `lama` is an alias for the switch being created; on success a directory `$(HOME)/.opam/lama` should be created

2. Update PATH variable for the fresh switch. (You can add these commands to your `~/.bashrc` for convenience but they should be added by `opam`)
    ```bash
    eval $(opam env --switch=lama)
    ```

     * Check that the OCaml compiler is now available in PATH by running `which ocamlc`; it should answer with `/home/user/.opam/lama/bin/ocamlc` (or similar) and `ocamlc -v` should answer with
    ```
    The OCaml compiler, version 4.14.0
    Standard library directory: /home/user/.opam/lama/lib/ocaml
    ```

3. Pin Lama package using `opam` and right URL (remember of "#" being a comment character in various shells)

    ```bash
    opam pin add Lama https://github.com/PLTools/Lama.git\#1.20 --no-action
    ```

    The extra '#' sign is added because in various Shells it is the start of a comment

4. Install *dep*endencies on system-wide *ext*ernal packages and `lama` itself after that.

    ```bash
    opam depext Lama --yes
    ```
    ```bash
    opam install Lama --yes
    ```

5. Check that `lamac` executable was installed: `which lamac` should answer with

    ```
    /home/<USER>/.opam/lama/bin/lamac
    ```

### Smoke-testing (optional)

Clone the repository and run `make -C tutorial`.
It should build a local compiler `src/lamac` and a few tutorial executables in `tutorial/`.

### Useful links

* [Plugin for VS Code](https://marketplace.visualstudio.com/items?itemName=mrartemsav.lama-lsp)

### Changes in Lama 1.20

* New garbage collector: single-threaded stop-the-world `LISP2` (see GC Handbook for details: [1st edition](https://www.cs.kent.ac.uk/people/staff/rej/gcbook/), [2nd edition](http://gchandbook.org/)) [mark-compact](https://www.memorymanagement.org/glossary/m.html#term-mark-compact).
