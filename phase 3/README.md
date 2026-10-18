# Phase 3 — Verification

Phase 3 provides verification planning and a SystemVerilog test environment for the ALU assignment.

- `planning/` — verification plan (.md and .docx), requirements matrix, 42 directed scenarios, random strategy, coverage/checker plans, traceability and open questions.
- `tb/` — oracle, scoreboard, 14-operation stimulus, DUT adapter and interface/structural review instructions.
- `scripts/` — `validate_plan.py` validates planning IDs; `audit_readiness.py` reports blocked and planned checks.
- `results/` — blank execution-evidence sheet; no simulation results have been claimed.

## Use

1. `python3 scripts/validate_plan.py` then `python3 scripts/audit_readiness.py`.
2. Connect `tb/alu_dut_adapter.sv` to the actual Phase 2 `cpu_pkg` using its exact public interface.
3. Run `alu_test` using a class-capable SystemVerilog simulator and save the results.
4. Resolve Phase 1 open questions before enabling numerical checks for unspecified operations.

**Current status:** all 14 opcodes have directed and random stimulus; only AND/OR/XOR have active numeric oracles. Structural and behavioral checks are documented but need the actual DUT, and ambiguous behavior stays BLOCKED. A test scenario's existence is not proof of verification.
