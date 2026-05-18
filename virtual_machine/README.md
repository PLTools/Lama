# Lama virtual machine

This directory contains the implementation of the virtual machine for the Lama programming language. The VM is a stack-based execution engine designed to run Lama bytecode.

Documentation is split as follows:

* [`SPEC.md`](SPEC.md) - bytecode file format and instruction reference
* `README.md` - architectural overview of the VM implementation

## Architecture overview (work in progress)

The Lama VM follows a stack-based architecture where operands are pushed onto a data stack, and operations consume these operands and push results back.

![Architecture](arch.png)
(work in progress, each iteration the architecture will change)

### Key Components

* **Interpreter (`interpreter.c`)**: The core execution loop that fetches, decodes, and executes bytecode instructions.
* **Data stack (`stack.c`, `stack.h`)**: A growable stack used for evaluating expressions, passing function arguments, and storing local variables.
* **Call stack (`call_stack.c`, `call_stack.h`)**: Manages function activation records (frames), tracking return addresses and stack base pointers.
* **Instruction set (`opcodes.h`)**: Defines the bytecode opcodes

### Interaction with Runtime

The VM is tightly integrated with the Lama runtime (`../runtime/`). It relies on the runtime for:

* **Memory management**: Automatic garbage collection for heap-allocated objects.
* **Built-in functions**: IO operations (read/write), array/S-expression/string handling.
