# Phase 3 verification plan: ALU class model

**Status:** ready with conditions (section 3). **Not run yet:** `tb/tb_cpu.sv` has not been compiled or simulated, so there are no results.

## 1. Scope

Phase 3 verifies the `cpu_pkg` class model from Phase 2 (`base_alu`, `logical_alu`, `arithmetic_alu`, `CPU`, `alu_op_t`) through its public API. It covers all 28 Phase 1 verification tests (TC-001 to TC-028), the 14 operations (OP-001 to OP-014) and the two invalid codes.

Phase 1 defines what is correct and Phase 3 defines how it is tested. Every expected value below cites the Phase 1 ID it comes from.

## 2. Inputs used

| Need | Source | IDs |
|---|---|---|
| Pass criterion for each test | `phase 1/ALU_Verification_Requirements.csv` | TC-001 to TC-028 |
| Exact expected values | `phase 1/ALU_Golden_Vectors.csv` (read by the program at run time) | vectors 1 to 37, cited as GV-01 to GV-37 |
| Operation semantics for the reference model | `phase 1/alu_spec.json` → `operations`, `data_semantics` | OP-001 to OP-014, D-002 to D-006, D-017 |
| API: classes, methods, enum | `phase 1/alu_spec.json` → `classes`, `types` | D-001, D-011, D-012, D-016 |
| State after `new()`, `initialize()`, `Reset()` | `phase 1/ALU_Design_Decisions.csv` | D-007, D-008, D-018 |
| Invalid codes | same | D-009 |
| `display()` format | same | D-010 |
| Content and exit criterion of the test program | same | D-015 |
| Design under test and its filelist | `phase 2/S10_handoff/phase2_handoff.json` → `dut` | `S5_rtl/files.f` |
| Known DUT behaviour the tests must handle | `phase 2/S10_handoff/review_notes.md` | F1: Verilator stops on `$error`; F2: `carry` is state |

## 3. Readiness result

Checked against Phase 1 revision 2 (`spec_version` 1.1-proposed) and the Phase 2 baseline `phase2-baseline-s1.1-proposed-p2`.

- **No blocking gaps.** Every TC has a pass criterion, either in its own row or through a D-ID or the golden vectors. Every operation has semantics and at least one golden vector. All 18 questions have an answer.
- **C1 (condition on sign-off):** D-001 to D-003 and D-005 to D-018 are "Proposed" with no approver. Results are provisional until Phase 1 records approval (`questions_for_phase1.md` #1).
- **C2, C3 (requests, no effect on the tests):** stale criteria wording in 13 TC rows; golden vectors have no ID column (`questions_for_phase1.md` #2 and #3).

## 4. Test map

All tests are in `tb/tb_cpu.sv` and are named after the TC they cover. Each check is counted under its TC, and the run prints one PASS/FAIL line per TC.

| TC | What is checked | Test | Expected values from |
|---|---|---|---|
| TC-001 | `operand_A`, `operand_B`, `alu_result` are 32-bit signed; `alu_op` is 4-bit | `tc001_properties` | TC-001, D-001, D-004 |
| TC-002 | `load_operand_A` stores 17, −4, 0 and the int limits | `tc002_tc003_load` | TC-002, D-011 |
| TC-003 | `load_operand_B`, same values | `tc002_tc003_load` | TC-003, D-011 |
| TC-004 | `new()` and `initialize()` give the D-007 state in all three classes; `carry` = 0 | `tc004_initialize` | TC-004, D-007, D-018 |
| TC-005 | `display()` prints class, op, A, B and result | `tc005_display` + log check in `run.sh` | TC-005, D-010 |
| TC-006 to TC-012 | AND, OR, XOR, SHL, SHR, ROL, ROR (in that order) | `golden_vectors`, `random_test` | golden vectors of the operation; model from `alu_spec.json` |
| TC-013 to TC-019 | SEL_B, INC_B, DEC_B, ADD, ADDC, SUB, SUBB (in that order), including `carry` | `golden_vectors`, `random_test` | same, plus D-005, D-006 |
| TC-020 | `CPU.new()` builds `l_alu` (`logical_alu`) and `a_alu` (`arithmetic_alu`) | `tc020_members` | TC-020, D-018 |
| TC-021 | `Reset()` gives D-007 in both ALUs with `carry` = 0 and keeps the objects | `tc021_reset` | TC-021, D-007, D-008 |
| TC-022 | `Calc(7, 5, ADD)` = 12; codes 4'b0000 to 4'b0110 load and run `a_alu` only | `tc022_tc023_dispatch` | TC-022, D-012 |
| TC-023 | `Calc(12, 10, AND)` = 8; codes 4'b0111 to 4'b1101 load and run `l_alu` only | `tc022_tc023_dispatch` | TC-023, D-012 |
| TC-024 | `alu_op_t` has 14 members; each code has the name Phase 1 uses | `tc024_enum`, `load_vectors` | TC-024, D-001, golden vectors (Operation, Code) |
| TC-025 | each class and `alu_op_t` resolve through `cpu_pkg::` | `tc025_package` | TC-025, D-014 |
| TC-026 | the program compiles, imports `cpu_pkg` and runs every section | end of the `initial` block | TC-026, D-015 |
| TC-027 | 4'b1110 and 4'b1111: `Calc` returns 0, no ALU state changes, one `$error` each | `tc027_invalid` + log check in `run.sh` | TC-027, D-009 |
| TC-028 | `initialize()` clears earlier loads; later loads stick | `tc028_load_then_initialize` | TC-028, D-007 |

D-015 requires every opcode, the boundary vectors, Reset and an invalid opcode. These are covered by TC-006 to TC-019, the golden vectors, TC-021 and TC-027.

## 5. Stimulus

- **Directed:** every row of `ALU_Golden_Vectors.csv` goes through `CPU.Calc`, with `carry` first set to the vector's "Carry in" (review flag F2). The TC-specific tests in section 4 use the Phase 1 example inputs where a TC gives them (17 and −4 for the loads, `Calc(7, 5, ADD)`, `Calc(12, 10, AND)`).
- **Random:** 5000 calls by default (`+RANDOM_N`), seed 1 (`+SEED`). The opcode is uniform over the 14 valid codes. One operand in four is a corner value (0, 1, −1, 31, 32, `INT_MAX`, `INT_MIN`), the rest are uniform 32-bit values. `carry` is never reset between calls, so carry chains across calls are tested. Invalid codes are directed only (TC-027), because each one prints an `$error`.

## 6. Checking

- **Scoreboard:** each check compares the DUT value with the expected value and prints `FAIL TC-xxx <what>: got …, expected …` on a mismatch.
- **Reference model** (random test): written in `tb_cpu.sv` from the `alu_spec.json` semantics, independently of the Phase 2 code. It must reproduce all golden vectors before any DUT test runs; otherwise the run stops.
- **Log checks** in `run.sh`, for output the program cannot read itself: TC-005 (`display()` text) and TC-027 (exactly two `%Error` lines, one naming each invalid code).
- **Checker self-test:** `bash run.sh +CHECKER_SELFTEST` corrupts the first checked value. The run must report it as FAIL, which shows that mismatches are caught.

## 7. Coverage

Each bin counts checked `Calc` calls (directed and random). The goal is all 44 bins.

| Group | Bins | Count |
|---|---|---|
| Opcode through `CPU.Calc` | every code 4'b0000 to 4'b1111 (14 valid, 2 invalid) | 16 |
| Carry/borrow out | ADD, ADDC, SUB, SUBB × {0, 1} | 8 |
| Carry/borrow in | ADDC, SUBB × {0, 1} | 4 |
| Shift/rotate amount (D-003) | SHL, SHR, ROL, ROR × {B[4:0] = 0, 1 to 30, 31, B[31:5] ≠ 0} | 16 |

## 8. Exit criteria

1. `results/summary.txt` says PASS: no failed check in any TC, every TC checked, both log checks pass, 44/44 coverage bins.
2. `results/checker_selftest/summary.txt` says the corrupted value was caught.
3. Phase 1 has approved the decisions (C1). Until then a PASS is provisional.
4. Every mismatch found on the way was resolved by Phase 2 (DUT bug) or Phase 1 (spec answer). No expected value was edited to match the DUT.

## 9. Status

| Item | State |
|---|---|
| Readiness | ready with conditions C1 to C3 |
| Plan | complete for TC-001 to TC-028 |
| Test program | written; **not compiled yet** |
| Regression | **not run**: no simulator was available where this plan was written |
| Sign-off | not achieved (needs exit criteria 1 to 3) |
