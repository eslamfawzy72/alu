# Phase 2 Review Notes

## Result
The complete Phase 2 artifact set has been generated for the ALU class-model assignment.

## Important source-grounded point
The Phase 1 tables leave multiple implementation details unresolved, while the assignment itself says to assume missing information. Phase 2 therefore records each choice explicitly as D-001..D-018 instead of silently changing the requirements.

## Implementation choices
- `alu_op_t` is the single shared enum in `cpu_pkg`.
- `int` is treated as the required 32-bit signed SystemVerilog type.
- `operand_A` is the data operand for shift/rotate; low five bits of `operand_B` are the amount.
- `carry` and `borrow` are internal state of `arithmetic_alu`.
- `initialize()` and `Reset()` use deterministic zero/default values.
- Unsupported opcodes return zero and issue a warning.
- `execute()` is the common virtual dispatch hook.

## Validation limitation
The environment used to generate these artifacts does not contain Verilator, Verible, Surelog, Questa, Icarus, or Yosys. Therefore no fabricated "tool passed" result is included. The S6/S8 reports explicitly record the environment block.

## Final handoff state
The project is verification-ready and contains the requested RTL/testbench/build list and all Phase 2 reports, but a final baseline tag should only be created after real SystemVerilog compilation/lint/smoke execution.
