# Questions for Phase 1

Phase 2 cannot start: 74 blocking findings. Please answer each question below and send the updated files (same IDs).

## IN-07

1. Q-001: What is the exact SystemVerilog enum type name and where should it be declared? Please give the agreed answer, who approved it and the date.
2. Q-002: For each operation, which input operand(s) are used and in what order? Please give the agreed answer, who approved it and the date.
3. Q-003: For shift and rotate operations, where does the shift/rotation amount come from? Please give the agreed answer, who approved it and the date.
4. Q-004: What operand width and signedness should apply to shifts, rotations, and arithmetic results? Please give the agreed answer, who approved it and the date.
5. Q-005: How is carry-in supplied for ADD with CARRY, and how should carry-out be represented? Please give the agreed answer, who approved it and the date.
6. Q-006: How is borrow-in supplied for SUB with BORROW, and how should borrow-out be represented? Please give the agreed answer, who approved it and the date.
7. Q-007: What should initialize() set, and what should the default values of the ALU properties be? Please give the agreed answer, who approved it and the date.
8. Q-008: What exact state should CPU Reset clear or initialize? Please give the agreed answer, who approved it and the date.
9. Q-009: What should happen when an unsupported or unassigned opcode is supplied? Please give the agreed answer, who approved it and the date.
10. Q-010: What exact output and formatting should display() produce? Please give the agreed answer, who approved it and the date.
11. Q-011: What are the exact parameter and return types of load_operand_A(), load_operand_B(), and initialize()? Please give the agreed answer, who approved it and the date.
12. Q-012: What exact signature and dispatch behavior should CPU.Calc use for operation and Result? Please give the agreed answer, who approved it and the date.
13. Q-013: Should the ALU class functions be declared extern, and if so, which functions? Please give the agreed answer, who approved it and the date.
14. Q-014: What exact set of definitions must cpu_pkg contain? Please give the agreed answer, who approved it and the date.
15. Q-015: What minimum test cases or acceptance criteria are required for submission? Please give the agreed answer, who approved it and the date.
16. Q-016: Should arithmetic operations expose overflow, carry, or borrow flags in addition to alu_result? Please give the agreed answer, who approved it and the date.
17. Q-017: For operation 4'b0000, where should selected port-B data be stored or returned? Please give the agreed answer, who approved it and the date.
18. Q-018: What should happen if CPU or an ALU method is called before its objects/state are initialized? Please give the agreed answer, who approved it and the date.

## IN-01 / IN-08

1. FR-001 Define base ALU class: which class or package implements it?
2. FR-002 Load operand A: which class or package implements it?
3. FR-003 Load operand B: which class or package implements it?
4. FR-004 Initialize base ALU: which class or package implements it?
5. FR-005 Display ALU information: which class or package implements it?
6. FR-006 Implement logical ALU operations: which class or package implements it?
7. FR-007 Implement arithmetic ALU operations: which class or package implements it?
8. FR-008 Define CPU class: which class or package implements it?
9. FR-009 Reset CPU: which class or package implements it?
10. FR-010 Calculate selected ALU operation: which class or package implements it?
11. FR-011 Define operation enumeration: which class or package implements it?
12. FR-012 Create CPU package: which class or package implements it?
13. FR-013 Provide a test program: which class or package implements it?

## IN-02

1. IF-001 operand_A: give the exact data type and width in bits.
2. IF-002 operand_B: give the exact data type and width in bits.
3. IF-003: which class or package owns it?
4. IF-004 alu_result: give the exact data type and width in bits.
5. IF-004: which class or package owns it?
6. IF-005 load_operand_A: give the full declaration (return type, every argument with its type).
7. IF-006 load_operand_B: give the full declaration (return type, every argument with its type).
8. IF-007 initialize: give the full declaration (return type, every argument with its type).
9. IF-008 display: give the full declaration (return type, every argument with its type).
10. IF-011 Reset: give the full declaration (return type, every argument with its type).
11. IF-012 Calc: give the full declaration (return type, every argument with its type).
12. IF-014: which class or package owns it?

## IN-04

1. OP-001 Select data on port B (4'b0000): give the exact result, operand order and any flag effects, with boundary values.
2. OP-002 Increment data on port B (4'b0001): give the exact result, operand order and any flag effects, with boundary values.
3. OP-003 Decrement data on port B (4'b0010): give the exact result, operand order and any flag effects, with boundary values.
4. OP-004 ADD without CARRY (4'b0011): give the exact result, operand order and any flag effects, with boundary values.
5. OP-005 ADD with CARRY (4'b0100): give the exact result, operand order and any flag effects, with boundary values.
6. OP-006 SUB without BORROW (4'b0101): give the exact result, operand order and any flag effects, with boundary values.
7. OP-007 SUB with BORROW (4'b0110): give the exact result, operand order and any flag effects, with boundary values.
8. OP-011 Shift left (4'b1010): give the exact result, operand order and any flag effects, with boundary values.
9. OP-012 Shift right (4'b1011): give the exact result, operand order and any flag effects, with boundary values.
10. OP-013 Rotate left (4'b1100): give the exact result, operand order and any flag effects, with boundary values.
11. OP-014 Rotate right (4'b1101): give the exact result, operand order and any flag effects, with boundary values.

## IN-03

1. Give the enum type name, base type, every member with its value, and where it is declared.

## IN-05

1. What must Calc return and report for an unsupported operation code?

## IN-06

1. What value does every property hold after construction, initialize() and CPU.Reset()?

## IN-08

1. Send the architecture as an editable .puml or draw.io file (classes, extends, contains).

## IN-09

1. Is the deliverable synthesizable RTL or a simulation-only class model? Any target device?

## IN-10

1. Give the spec version, approval status, approvers, date and the Git commit of the Phase 1 files.
