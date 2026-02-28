# Lama virtual machine

This directory contains the implementation of the virtual machine for the Lama programming language. The VM is a stack-based execution engine designed to run Lama bytecode.

## Architecture overview (work in progress)

The Lama VM follows a stack-based architecture where operands are pushed onto a data stack, and operations consume these operands and push results back.

![Architecture](arch.png)
(work in progress, each iteration the architecture will change)
### Key Components

*   **Interpreter (`interpreter.c`)**: The core execution loop that fetches, decodes, and executes bytecode instructions.
*   **Data stack (`stack.c`, `stack.h`)**: A growable stack used for evaluating expressions, passing function arguments, and storing local variables.
*   **Call stack (`call_stack.c`, `call_stack.h`)**: Manages function activation records (frames), tracking return addresses and stack base pointers.
*   **Instruction set (`opcodes.h`)**: Defines the bytecode opcodes 

### Interaction with Runtime

The VM is tightly integrated with the Lama runtime (`../runtime/`). It relies on the runtime for:
*   **Memory management**: Automatic garbage collection for heap-allocated objects.
*   **Built-in functions**: IO operations (read/write), array/S-expression/string handling.

## Bytecode format

### Layout
Bytes are laid out in little-endian order.
1. Header (16 bytes)
2. String table (variable)
3. Imports (number of imports * 4 bytes)
4. Public symbols (number of public symbols * 9 bytes)
5. Code section (until 0xFF)

### Header
| offset | size | field |
|--------|------|-------|
| 0 | 4 | string table size |
| 4 | 4 | globals count |
| 8 | 4 | number of imports |
| 12 | 4 | number of public symbols |

### Imports
Each entry is 4 bytes:
- `name_offset` (int32): offset into string table for module name

### Public symbols
Each entry is 9 bytes:
- `name_offset` (int32): offset into string table
- `code_offset` (int32): for functions: bytecode offset; for globals: global index
- `flag` (uint8): 0 = function, 1 = global

### External references
CALL (0x56) and CLOSURE (0x54) instructions use negative values for external function references.
LD (0x20) and ST (0x40) instructions use negative values for external global references.

The encoding is the same for both:
- Non-negative values: local references (bytecode offset for functions, global index for globals)
- Negative values: `string_table_offset = -value -1`

The string at that offset is looked up to resolve the external symbol at load time. 


