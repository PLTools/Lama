# ![Lama](../lama.svg) Bytecode and VM Instruction Reference

This document describes two representations:

  1. __Bytecode format__: the serialized instructions stored in `.bc` files.
  2. __VM representation__: the decoded (threaded code) representation executed by the VM.

## Table of contents

* [Data types](#data-types)
* [Bytecode file layout](#bytecode-file-layout)
* [External references](#external-references)
* [Instruction reference conventions](#instruction-reference-conventions)
* [BINOP](#binop)
* [CONST](#const)
* [STRING](#string)
* [SEXP](#sexp)
* [STA](#sta)
* [JMP](#jmp)
* [END](#end)
* [DROP](#drop)
* [DUP](#dup)
* [SWAP](#swap)
* [ELEM](#elem)
* [LD](#ld)
* [ST](#st)
* [CJMP](#cjmp)
* [BEGIN](#begin)
* [BEGIN_CLOSURE](#begin_closure)
* [CLOSURE](#closure)
* [CALLC](#callc)
* [CALL](#call)
* [TAG](#tag)
* [ARRAY](#array)
* [FAIL](#fail)
* [LINE](#line)
* [PATT](#patt)
* [BARRAY](#barray)
* [EOF](#eof)

## Data types

Types use fixed-width, little-endian, two's complement integer encodings. The following convention is being followed in the document:

| Type | Width | Range |
|:--|:--|:--|
| `uint8` | 1 byte | 0 to 255 |
| `int32` | 4 bytes | −2<sup>31</sup> to 2<sup>31</sup>−1 |

The `opcode` field of every bytecode instruction is `uint8`.

# Bytecode file layout

1. Header (20 bytes)
2. String table (`string_table_size` bytes)
3. Imports (`imports_count * 4` bytes)
4. Public symbols (`public_symbols_count * 9` bytes)
5. Code section (until `0xFF`)

### Header

| Field | Type | Description |
|:--|:--|:--|
| `magic` | `uint8[4]` | ASCII bytes `LaMa` |
| `string_table_size` | `int32` | size of the string table (in bytes) |
| `globals_count` | `int32` | number of global variables (stored on the stack) |
| `imports_count` | `int32` | number of imports |
| `public_symbols_count` | `int32` | number of public symbols |

### Imports

| Field | Type | Description |
|:--|:--|:--|
| `name_offset` | `int32` | offset into the string table for the module name |

### Public symbols

| Field | Type | Description |
|:--|:--|:--|
| `name_offset` | `int32` | offset into the string table |
| `code_offset` | `int32` | bytecode offset for functions, global index for globals |
| `flag` | `uint8` | `0` = function, `1` = global |

## External references

`CALL` (`0x56`) and `CLOSURE` (`0x54`) instructions use negative values for external function references. `LD_GLO` (`0x20`) and `ST_GLO` (`0x40`) instructions use negative values for external global references.

The encoding is the same for both:

* `value >= 0` : local references (bytecode offset for functions, global index for globals)
* `value < 0`: `string_table_offset = -value -1`

The string at that offset is looked up to resolve the external symbol at load time.

## Instruction reference conventions

* __Operation__ - a short description of what the instruction does.
* __Format__ - the bytecode mnemonic and operand types.
* __Forms__ - concrete opcode variants and their opcode values.
* __Operand stack__ - written as `before` → `after`. The top of stack is rightmost.
* __Description__ - bytecode-level meaning of the instruction and its operands.
* __Implementation notes__ - VM-internal representation after decoding, and the effect on registers `<ip, sp, bp>`.

The VM uses the following virtual registers:

* `ip` - instruction pointer into the decoded (threaded-code) stream
* `sp` - operand stack pointer. The operand stack grows downwards: a push decrements `sp`, and a pop increments it.
* `bp` - base pointer of the current call frame

## BINOP

### Operation

Apply a binary operator to the top two stack values.

### Format

```text
BINOP<op>
```

### Forms

```text
ADD = 0x01
SUB = 0x02
MUL = 0x03
DIV = 0x04
MOD = 0x05
LT  = 0x06
LE  = 0x07
GT  = 0x08
GE  = 0x09
EQ  = 0x0A
NE  = 0x0B
AND = 0x0C
OR  = 0x0D
```

### Operand stack

`..., x, y` → `..., result`

### Description

Each binary operator pops its two operands from the stack, applies the corresponding runtime operation, and pushes the result.

The operand order is `x` then `y`, so the topmost stack value is the right operand.

### Implementation notes

```text
ADD -> [op_add]
SUB -> [op_sub]
MUL -> [op_mul]
DIV -> [op_div]
MOD -> [op_mod]
LT  -> [op_lt]
LE  -> [op_le]
GT  -> [op_gt]
GE  -> [op_ge]
EQ  -> [op_eq]
NE  -> [op_ne]
AND -> [op_and]
OR  -> [op_or]
```

All binary operator handlers pop `y`, then `x`, call `runtime_fn(x, y)`, and push the resulting value.

`<ip, sp, bp>` → `<ip + 1, sp + 1, bp>`

## CONST

### Operation

Push a constant on the stack.

### Format

```text
CONST value:int32
```

### Forms

```text
CONST = 0x10
```

### Operand stack

`...` → `..., value`

### Description

`value` is a signed 32-bit integer literal encoded directly in the bytecode.

### Implementation notes

```text
[op_const][value]
```

Pushes `BOX(value)` onto the stack.

`<ip, sp, bp>` → `<ip + 2, sp - 1, bp>`

## STRING

### Operation

Push a string on the stack.

### Format

```text
STRING string_offset:int32
```

### Forms

```text
STRING = 0x11
```

### Operand stack

`...` → `..., value`

### Description

`string_offset` is an offset into the string table pointing to the literal bytes of the string.

### Implementation notes

```text
[op_string][str]
```

`string_offset` is resolved during decoding to a direct C string pointer `str`.

`<ip, sp, bp>` → `<ip + 2, sp - 1, bp>`

## SEXP

### Operation

Create an S-expression

### Format

```text
SEXP tag_offset:int32 n_fields:int32
```

### Forms

```text
SEXP = 0x12
```

### Operand stack

`..., field_1, ..., field_n` → `..., sexp`

### Description

`tag_offset` is an offset into the string table pointing to the S-expression tag name. `n_fields` is the number of fields consumed from the top of the operand stack.

The fields are taken from the stack and used as the contents of the constructed S-expression.

### Implementation notes

```text
[op_sexp][tag_hash][n_fields]
```

`tag_offset` is resolved beforehand during decoding to `tag_hash` (using runtime `LtagHash`).

`<ip, sp, bp>` → `<ip + 3, sp + n_fields - 1, bp>`

## STA

### Operation

Store a value into an aggregate.

### Format

```text
STA
```

### Forms

```text
STA = 0x14
```

### Operand stack

`..., aggregate, index, value` → `..., value`

### Description

`aggregate` represents an array, S-expression, or string.

`STA` stores `value` into `aggregate[index]`.

The target aggregate and index are taken from the operand stack. The updated value remains on the stack after the store.

### Implementation notes

```text
[op_sta]
```

Calls `Bsta(aggregate, index, value)` and leaves `value` on the stack.

`<ip, sp, bp>` → `<ip + 1, sp + 2, bp>`

## JMP

### Operation

Jump unconditionally to a target instruction.

### Format

```text
JMP target:int32
```

### Forms

```text
JMP = 0x15
```

### Operand stack

`...` → `...`

### Description

`target` is a bytecode offset naming the jump destination within the code section.

### Implementation notes

```text
[op_jmp][target]
```

`target` is resolved during decoding to a threaded-code instruction pointer.

`<ip, sp, bp>` → `<target, sp, bp>`

## END

### Operation

Return from the current function.

### Format

```text
END
```

### Forms

```text
END = 0x16
```

### Operand stack

`..., return_value` → `..., return_value`

### Description

`END` terminates the current function body and returns the top stack value to the caller.

### Implementation notes

```text
[op_end]
```

Restores the caller frame and pushes the return value onto the caller stack.

`<ip, sp, bp>` → `<saved_ip, saved_sp - 1, saved_bp>`

## DROP

### Operation

Drop the top stack value.

### Format

```text
DROP
```

### Forms

```text
DROP = 0x18
```

### Operand stack

`..., value` → `...`

### Description

`DROP` removes the top value from the operand stack.

### Implementation notes

```text
[op_drop]
```

`<ip, sp, bp>` → `<ip + 1, sp + 1, bp>`

## DUP

### Operation

Duplicate the top stack value.

### Format

```text
DUP
```

### Forms

```text
DUP = 0x19
```

### Operand stack

`..., value` → `..., value, value`

### Description

`DUP` copies the top value of the operand stack.

### Implementation notes

```text
[op_dup]
```

`<ip, sp, bp>` → `<ip + 1, sp - 1, bp>`

## SWAP

### Operation

Swap the top two stack values.

### Format

```text
SWAP
```

### Forms

```text
SWAP = 0x1A
```

### Operand stack

`..., x, y` → `..., y, x`

### Description

`SWAP` exchanges the top two values on the operand stack.

### Implementation notes

```text
[op_swap]
```

`<ip, sp, bp>` → `<ip + 1, sp, bp>`

## ELEM

### Operation

Load a value from an aggregate.

### Format

```text
ELEM
```

### Forms

```text
ELEM = 0x1B
```

### Operand stack

`..., aggregate, index` → `..., value`

### Description

`aggregate` represents an array, S-expression, or string.

`ELEM` loads the value stored at `aggregate[index]`.

### Implementation notes

```text
[op_elem]
```

Calls `Belem(aggregate, index)` and pushes the loaded value.

`<ip, sp, bp>` → `<ip + 1, sp + 1, bp>`

## LD

### Operation

Load a variable to the stack.

### Format

```text
LD<mode> operand:int32
```

### Forms

```text
LD_GLO = 0x20
LD_LOC = 0x21
LD_ARG = 0x22
LD_CLO = 0x23
```

### Operand stack

`...` → `..., value`

### Description

`LD_GLO`:

* `operand` field uses the same external global reference encoding described in [external references](#external-references).

`LD_LOC`:

* `operand` is a local slot index.

`LD_ARG`:

* `operand` is an argument slot index.

`LD_CLO`:

* `operand` is a closure capture index.

### Implementation notes

```text
LD_GLO -> [op_ld_glo][global_ptr]
LD_LOC -> [op_ld_loc][local]
LD_ARG -> [op_ld_arg][arg]
LD_CLO -> [op_ld_clo][capture]
```

`LD_GLO` resolves `operand` during decoding to `global_ptr`.
`LD_CLO` reads captured value `operand` from `closure[operand + 1]`.

`<ip, sp, bp>` → `<ip + 2, sp - 1, bp>`

## ST

### Operation

Store a value into a variable.

### Format

```text
ST<mode> operand:int32
```

### Forms

```text
ST_GLO = 0x40
ST_LOC = 0x41
ST_ARG = 0x42
ST_CLO = 0x43
```

### Operand stack

`..., value` → `..., value`

### Description

`ST_GLO`:

* `operand` field uses the same external global reference encoding described in [external references](#external-references).

`ST_LOC`:

* `operand` is a local slot index.

`ST_ARG`:

* `operand` is an argument slot index.

`ST_CLO`:

* `operand` is a closure capture index.

### Implementation notes

```text
ST_GLO -> [op_st_glo][global_ptr]
ST_LOC -> [op_st_loc][local]
ST_ARG -> [op_st_arg][arg]
ST_CLO -> [op_st_clo][capture]
```

`ST_GLO` resolves `operand` during decoding to `global_ptr`.
`ST_CLO` stores captured value `operand` in `closure[operand + 1]`.

`<ip, sp, bp>` → `<ip + 2, sp, bp>`

## CJMP

### Operation

Jump conditionally to a target instruction.

### Format

```text
CJMP<cond> target:int32
```

### Forms

```text
CJMP_Z  = 0x50
CJMP_NZ = 0x51
```

### Operand stack

`..., value` → `...`

### Description

`target` is a bytecode offset naming the jump destination within the code section.

`CJMP_Z` jumps when `value == 0`. `CJMP_NZ` jumps when `value != 0`.

### Implementation notes

```text
CJMP_Z  -> [op_cjmp_z][target]
CJMP_NZ -> [op_cjmp_nz][target]
```

`target` is resolved during decoding to a threaded-code instruction pointer.

`<ip, sp, bp>` → `<(target | ip + 2), sp + 1, bp>`

## BEGIN

### Operation

Enter a function body and allocate local slots.

### Format

```text
BEGIN n_args:int32 n_locals:int32
```

### Forms

```text
BEGIN = 0x52
```

### Operand stack

`..., arg_1, ..., arg_n` → `..., arg_1, ..., arg_n, local_1, ..., local_m`

### Description

`n_args` is the number of function arguments and `n_locals` is the number of local slots allocated for the function body.

Each local slot is initialized to `BOX(0)`.

### Implementation notes

```text
[op_begin][n_args][n_locals]
```

`<ip, sp, bp>` → `<ip + 3, sp - n_locals, bp>`

## BEGIN_CLOSURE

### Operation

Enter a closure body and allocate local slots.

### Format

```text
BEGIN_CLOSURE n_args:int32 n_locals:int32 n_captured:int32
```

### Forms

```text
BEGIN_CLOSURE = 0x53
```

### Operand stack

`..., arg_1, ..., arg_n, closure` → `..., arg_1, ..., arg_n, closure, local_1, ..., local_m`

### Description

`n_args` is the number of call arguments, `n_locals` is the number of local slots allocated for the closure body, and `n_captured` is the number of captured values expected by the closure entry point.

Each local slot is initialized to `BOX(0)`.

### Implementation notes

```text
[op_begin_closure][n_args][n_locals]
```

`n_captured` is validated during decoding and is not carried into the threaded representation.

`<ip, sp, bp>` → `<ip + 3, sp - n_locals, bp>`

## CLOSURE

### Operation

Create a closure object and push it on the stack.

### Format

```text
CLOSURE target:int32 n_captured:int32 (kind:uint8 index:int32)*
```

### Forms

```text
CLOSURE = 0x54
```

### Operand stack

`...` → `..., closure`

### Description

`target` is a bytecode offset naming the closure entry point. `n_captured` is the number of captured values stored in the closure.

Each capture designation is encoded as a `(kind:uint8 index:int32)` pair, where:

* `kind = 0` denotes a global variable
* `kind = 1` denotes a local variable
* `kind = 2` denotes a function argument
* `kind = 3` denotes a captured closure variable

The `target` operand uses the same external function reference encoding described in [external references](#external-references).

### Implementation notes

```text
capture_* -> LD<mode>
[op_closure][target][n_captured]
```

Each capture designation is translated during decoding into a corresponding [LD](#ld) instruction. `target` is then resolved to a threaded-code instruction pointer.

`op_closure` consumes the already loaded captured values from the stack. The runtime closure layout is:

* `closure[0]` = entry point
* `closure[i + 1]` = captured value `i`

`<ip, sp, bp>` → `<ip + 2 * n_captured + 3, sp - 1, bp>`

## CALLC

### Operation

Call a closure value.

### Format

```text
CALLC n_args:int32
```

### Forms

```text
CALLC = 0x55
```

### Operand stack

`..., arg_1, ..., arg_n, closure` → `..., result`

### Description

`n_args` is the number of call arguments. The closure value is taken from the top of the stack.

### Implementation notes

```text
[op_callc][n_args]
```

Reads the entry point from `closure[0]`, pushes a new call frame, and transfers control to it.

`<ip, sp, bp>` → `<target, sp - 4, new_bp>`

## CALL

### Operation

Call a function.

### Format

```text
CALL target:int32 n_args:int32
```

### Forms

```text
CALL = 0x56
```

### Operand stack

`..., arg_1, ..., arg_n` → `..., result`

### Description

`target` is a bytecode offset naming the call target. `n_args` is the number of call arguments.

The `target` operand uses the same external function reference encoding described in [external references](#external-references).

### Implementation notes

```text
[op_call][target][n_args]
```

`target` is resolved during decoding to a threaded-code instruction pointer.

`<ip, sp, bp>` → `<target, sp - 4, new_bp>`

## TAG

### Operation

Check whether a value is an S-expression with a given tag and arity.

### Format

```text
TAG tag_offset:int32 n_fields:int32
```

### Forms

```text
TAG = 0x57
```

### Operand stack

`..., value` → `..., result`

### Description

`tag_offset` is an offset into the string table naming the expected S-expression tag. `n_fields` is the expected number of fields.

### Implementation notes

```text
[op_tag][tag_hash][n_fields]
```

`tag_offset` is resolved during decoding to `tag_hash` (using runtime `LtagHash`).

`<ip, sp, bp>` → `<ip + 3, sp, bp>`

## ARRAY

### Operation

Check whether a value is an array of a given length.

### Format

```text
ARRAY n:int32
```

### Forms

```text
ARRAY = 0x58
```

### Operand stack

`..., value` → `..., result`

### Description

`n` is the expected array length.

### Implementation notes

```text
[op_array][n]
```

`<ip, sp, bp>` → `<ip + 2, sp, bp>`

## FAIL

### Operation

Raise a pattern-match failure.

### Format

```text
FAIL<keep> line:int32 col:int32
```

### Forms

```text
FAIL      = 0x59
FAIL_KEEP = 0x5A
```

### Operand stack

`..., value` → `...` for `FAIL`

`..., value` → `..., value` for `FAIL_KEEP`

### Description

`line` and `col` identify the source position reported for the match failure.

`FAIL` consumes the top value before reporting the failure. `FAIL_KEEP` reports the failure while keeping the top value.

### Implementation notes

```text
[op_fail][line][col][drop_value][module_name]
```

`<ip, sp, bp>` → `⊥`

## LINE

### Operation

Emit a line marker.

### Format

```text
LINE line:int32
```

### Forms

```text
LINE = 0x5B
```

### Operand stack

`...` → `...`

### Description

`line` is a source line number associated with the following bytecode position.

### Implementation notes

```text
[op_line][line]
```

In non-`DEBUG_PRINT` builds, `LINE` is skipped during decoding and does not appear in the threaded representation.

`<ip, sp, bp>` → `<ip + 2, sp, bp>`

## PATT

### Operation

Apply a pattern predicate.

### Format

```text
PATT<kind>
```

### Forms

```text
PATT_STR_CMP = 0x60
PATT_STRING  = 0x61
PATT_ARRAY   = 0x62
PATT_SEXP    = 0x63
PATT_BOXED   = 0x64
PATT_UNBOXED = 0x65
PATT_CLOSURE = 0x66
```

### Operand stack

`..., x, y` → `..., result` for `PATT_STR_CMP`

`..., value` → `..., result` for all other forms

### Description

Each `PATT_*` instruction applies a runtime predicate used by pattern matching and pushes a boolean(-like) result.

`PATT_STR_CMP` compares two values. The remaining forms test whether a single value matches the corresponding runtime shape.

### Implementation notes

```text
PATT_STR_CMP -> [op_patt_str_cmp]
PATT_STRING  -> [op_patt_string]
PATT_ARRAY   -> [op_patt_array]
PATT_SEXP    -> [op_patt_sexp]
PATT_BOXED   -> [op_patt_boxed]
PATT_UNBOXED -> [op_patt_unboxed]
PATT_CLOSURE -> [op_patt_closure]
```

`PATT_STR_CMP` behaves like a binary operator. All other `PATT_*` forms behave like unary operators.

`<ip, sp, bp>` → `<ip + 1, sp + 1, bp>` for `PATT_STR_CMP`

`<ip, sp, bp>` → `<ip + 1, sp, bp>` for all other forms

## BARRAY

### Operation

Construct an array and push it onto the stack.

### Format

```text
BARRAY n:int32
```

### Forms

```text
BARRAY = 0x74
```

### Operand stack

`..., elem_1, ..., elem_n` → `..., array`

### Description

`n` is the number of array elements consumed from the top of the operand stack.

### Implementation notes

```text
[op_barray][n]
```

`op_barray` consumes `n` stack values, reverses them into array order, allocates a runtime array with `Barray`, and pushes the resulting array value.

`<ip, sp, bp>` → `<ip + 2, sp + n - 1, bp>`

## EOF

### Operation

Mark the end of the bytecode stream.

### Format

```text
EOF
```

### Forms

```text
EOF = 0xFF
```

### Operand stack

`...` → `...`

### Description

`EOF` terminates the bytecode stream. It must appear at the end of the code section and outside any function body.

### Implementation notes

```text
[op_eof]
```

`<ip, sp, bp>` → `⊥`
