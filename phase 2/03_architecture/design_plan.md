# Design plan (microarchitecture), version 1

Spec version used: 1.1-proposed · Date: 2026-10-19 · Author: Mohamed Wael

This plan says **how** the ALU is built inside. Every row points to the spec ID or decision it comes from.

## 0. Coding rules (Phase 1 gave none, see Q6)

- SystemVerilog-2017 (IEEE 1800-2017); simulation-only class model (no clock, no synthesis).
- One class per file (CA-001); file name = class name; package file `.sv`, class files `.svh`.
- No `extern` (D-013): methods are defined inside each class.
- Every line that implements a spec ID ends with `// @ID`.
- Lint: `verilator --lint-only -Wall` must print nothing.

## 1. Units, files and build order

| Order | Unit | Kind | File | Extends | Why this order |
|---|---|---|---|---|---|
| 1 | cpu_pkg | package | `cpu_pkg.sv` | — | declares `alu_op_t`, which every class uses; includes the 4 class files |
| 2 | base_alu | class | `base_alu.svh` | — | both ALUs extend it |
| 3 | logical_alu | class | `logical_alu.svh` | base_alu | base must be known first |
| 4 | arithmetic_alu | class | `arithmetic_alu.svh` | base_alu | base must be known first |
| 5 | CPU | class | `CPU.svh` (DV-1) | — | holds handles of both derived classes, so it comes last |

`files.f` lists only `cpu_pkg.sv` plus `+incdir+rtl`; the classes are reached through `` `include ``.

## 2. Members of each unit

### cpu_pkg

| Member | Kind | Type / declaration | Spec IDs |
|---|---|---|---|
| alu_op_t | enum type | `typedef enum logic [3:0] {OP_SEL_B=4'b0000 … OP_ROR=4'b1101} alu_op_t;` (14 members, values from `alu_spec.json`) | FR-011, IF-014, D-001 |
| includes | — | `base_alu.svh`, `logical_alu.svh`, `arithmetic_alu.svh`, `CPU.svh` | FR-012, IF-013, D-014 |

### base_alu

| Member | Property / method | Type or full signature | Value after initialize() | What it does | Spec IDs |
|---|---|---|---|---|---|
| operand_A | property | `int` (32-bit signed) | 0 | first operand | IF-001 |
| operand_B | property | `int` | 0 | second operand / shift amount source | IF-002 |
| alu_op | property | `alu_op_t` | OP_SEL_B | selected operation | IF-003 |
| alu_result | property | `int` | 0 | result | IF-004 |
| new | method | `function new()` | — | calls `initialize()` | D-018 |
| load_operand_A | method | `function void load_operand_A(int value)` | — | `operand_A = value` | FR-002, IF-005, D-011 |
| load_operand_B | method | `function void load_operand_B(int value)` | — | `operand_B = value` | FR-003, IF-006, D-011 |
| initialize | method | `virtual function void initialize()` (DV-2) | — | sets the four values above | FR-004, IF-007, D-007 |
| get_name | method | `virtual function string get_name()` (added, AE-1) | — | returns `"base_alu"` | — |
| display | method | `virtual function void display()` | — | `$display("[%s] op=%s A=%0d B=%0d result=%0d", get_name(), alu_op.name(), …)` | FR-005, IF-008, D-010 |
| execute | method | `virtual function void execute()` | — | base has no ops: `$error` | IF-016, D-012 |

### logical_alu (extends base_alu)

| Member | Property / method | Signature | What it does | Spec IDs |
|---|---|---|---|---|
| get_name | override | `virtual function string get_name()` | returns `"logical_alu"` | — |
| execute | override | `virtual function void execute()` | `case (alu_op)` over OP-008..OP-014; default `$error` | FR-006 |

### arithmetic_alu (extends base_alu)

| Member | Property / method | Signature | Value after initialize() | What it does | Spec IDs |
|---|---|---|---|---|---|
| carry | property | `bit` | 0 | carry for adds, borrow for subtracts | IF-015, D-005, D-006 |
| get_name | override | `virtual function string get_name()` | — | `"arithmetic_alu"` | — |
| initialize | override | `virtual function void initialize()` | — | `super.initialize(); carry = 0;` | D-007 |
| get_carry | method | `function bit get_carry()` | — | returns carry | D-016 (no IF ID, Q1) |
| set_carry | method | `function void set_carry(bit c)` | — | `carry = c` (tests set carry-in) | D-005 (no IF ID, Q1) |
| display | override | `virtual function void display()` | — | base line + `carry=%0b` | D-010 |
| execute | override | `virtual function void execute()` | — | `case (alu_op)` over OP-001..OP-007; default `$error` | FR-007 |

### CPU

| Member | Property / method | Signature | What it does | Spec IDs |
|---|---|---|---|---|
| l_alu | property | `logical_alu` | logical ALU object | FR-008, IF-009 |
| a_alu | property | `arithmetic_alu` | arithmetic ALU object | FR-008, IF-010 |
| new | method | `function new()` | `l_alu = new(); a_alu = new();` | D-018 |
| Reset | method | `function void Reset()` | `l_alu.initialize(); a_alu.initialize();` objects kept | FR-009, IF-011, D-008 |
| Calc | method | `function int Calc(int in1, int in2, alu_op_t operation)` | see section 4 | FR-010, IF-012, D-002, D-009, D-012 |

## 3. Datapath: how each operation is computed

| OP ID | Enum | Unit | How it is computed | Carry effect | Must pass (golden vector #) |
|---|---|---|---|---|---|
| OP-001 | OP_SEL_B | arithmetic | `alu_result = operand_B` (D-017) | unchanged | 1 |
| OP-002 | OP_INC_B | arithmetic | `alu_result = operand_B + 1` (32-bit wrap) | unchanged | 2, 3, 4 |
| OP-003 | OP_DEC_B | arithmetic | `alu_result = operand_B - 1` (32-bit wrap) | unchanged | 5, 6 |
| OP-004 | OP_ADD | arithmetic | `wide = a + b; alu_result = wide[31:0]` | `carry = wide[32]` | 7–10 |
| OP-005 | OP_ADDC | arithmetic | `wide = a + b + cin; alu_result = wide[31:0]` | `carry = wide[32]` | 11–13 |
| OP-006 | OP_SUB | arithmetic | `wide = a - b; alu_result = wide[31:0]` | `carry = wide[32]` (borrow) | 14–16 |
| OP-007 | OP_SUBB | arithmetic | `wide = a - b - cin; alu_result = wide[31:0]` | `carry = wide[32]` (borrow) | 17–19 |
| OP-008 | OP_AND | logical | `operand_A & operand_B` | — | 20, 21 |
| OP-009 | OP_OR | logical | `operand_A \| operand_B` | — | 22 |
| OP-010 | OP_XOR | logical | `operand_A ^ operand_B` | — | 23, 24 |
| OP-011 | OP_SHL | logical | `a << amt` | — | 25–28 |
| OP-012 | OP_SHR | logical | `a >> amt` (logical: `a` is unsigned, zeros fill) | — | 29–31 |
| OP-013 | OP_ROL | logical | `(a << amt) \| (a >> (32 - amt))`; amt 0 → second term is `a >> 32` = 0 | — | 32–34 |
| OP-014 | OP_ROR | logical | `(a >> amt) \| (a << (32 - amt))` | — | 35–37 |

Why 33 bits for add/sub: `{1'b0, A} + {1'b0, B}` cannot overflow 33 bits, so bit 32 is exactly the unsigned carry out. For subtraction, `{1'b0, A} - {1'b0, B}` wraps in 33 bits when A < B (unsigned), which sets bit 32: that is the borrow. Example: 4 − 9 → bit 32 = 1, low 32 bits = −5 (vector 15).

Internal values (not visible outside):

| Name | Unit | Type / width | Value | Why |
|---|---|---|---|---|
| a | logical_alu.execute | `int unsigned` | `operand_A` as a 32-bit pattern | `>>` on unsigned is logical (D-004); rotates need plain bits |
| amt | logical_alu.execute | `int unsigned` | `{27'b0, operand_B[4:0]}`, 0..31 | shift amount (D-003); B = 32 gives 0 (vector 27) |
| a, b | arithmetic_alu.execute | `logic [32:0]` | `{1'b0, operand_A}`, `{1'b0, operand_B}` | carry/borrow in bit 32 (D-005, D-006) |
| cin | arithmetic_alu.execute | `logic [32:0]` | `{32'b0, carry}` | carry-in / borrow-in |
| wide | arithmetic_alu.execute | `logic [32:0]` | 33-bit result | result + carry together |
| alu | CPU.Calc | `base_alu` handle | `a_alu` or `l_alu` | one load/execute path for both ALUs (D-012) |

## 4. Control: how Calc picks the ALU

| Condition | Action | Decision |
|---|---|---|
| `operation inside {[OP_SEL_B : OP_SUBB]}` (0000–0110) | `alu = a_alu` | D-012 |
| `operation inside {[OP_AND : OP_ROR]}` (0111–1101) | `alu = l_alu` | D-012 |
| anything else (1110, 1111, X/Z) | `$error("invalid operation code …")`; `return 0`; nothing loaded, no ALU state changes | D-009 |
| then (valid code) | `alu.load_operand_A(in1); alu.load_operand_B(in2); alu.alu_op = operation; alu.execute(); return alu.alu_result;` | D-002, D-012 |

Because `execute()` is virtual, `alu.execute()` on a `base_alu` handle runs the subclass's version.

## 5. Reset and initial state (your step 7)

No clock in this class model. "Reset" means:

| What | Values afterwards | Decision |
|---|---|---|
| `new()` of any ALU | A = 0, B = 0, alu_op = OP_SEL_B, result = 0 (+ carry = 0) | D-018, D-007 |
| `initialize()` | same values | D-007 |
| `CPU.new()` | both ALUs created, each in the state above | D-018 |
| `CPU.Reset()` | `initialize()` on both ALUs; objects are kept, not re-created | D-008 |

## 6. Ownership

Full table: `02_requirements/requirements_map.csv` (Owner file column).

| Unit | Owns these IDs |
|---|---|
| cpu_pkg.sv | FR-011, FR-012, IF-013, IF-014, D-001, D-013, D-014 |
| base_alu.svh | FR-001..FR-005, IF-001..IF-008, IF-016, D-007, D-010, D-011 |
| logical_alu.svh | FR-006, OP-008..OP-014, D-003, D-004 |
| arithmetic_alu.svh | FR-007, OP-001..OP-007, IF-015, D-005, D-006, D-016, D-017 |
| CPU.svh | FR-008..FR-010, IF-009..IF-012, D-002, D-008, D-009, D-012, D-018 |

Total: 59 owned + 2 not in RTL = 61.

**Not in RTL:**

| ID | Reason |
|---|---|
| FR-013 | test program is a Phase 3 deliverable (CA-003) |
| D-015 | content of that test program |

## 7. Added elements (not in the spec)

| # | Element | Unit | Why it is needed |
|---|---|---|---|
| AE-1 | `virtual function string get_name()` | base_alu, overridden in both ALUs | D-010 prints `[<class>]`; a virtual method gives the real class name without an extra property |

(`execute`, `carry`, `get_carry`, `set_carry` are not additions: they come from Phase 1's IF-016, IF-015, D-016, D-005.)

## 8. Deviations from the spec (Phase 1 must update its files)

| # | Spec ID | Spec says | Plan does | Why |
|---|---|---|---|---|
| DV-1 | D-014 | file `cpu.svh` | file `CPU.svh` | Verilator `-Wall` DECLFILENAME: file name must equal class name; class name `CPU` is fixed by FR-008 |
| DV-2 | IF-007 | `function void initialize()` | `virtual function void initialize()` | `arithmetic_alu` overrides it; virtual makes the override run through any handle. Call interface unchanged |

## 9. Self-check before coding

- [x] every ID in `requirements_map.csv` has one owner or a not-in-RTL reason (59 + 2)
- [x] every interface IF-001..IF-016 appears in its unit with the same name and type (IF-007 + `virtual`, DV-2)
- [x] every operation OP-001..OP-014 has a datapath row
- [x] all 16 opcode values handled (7 arithmetic + 7 logical + invalid branch)
- [x] every property has a value after initialize()
- [x] the only addition is listed in section 7
