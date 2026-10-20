# S1 intake log

What Phase 2 received from Phase 1, how much of it, and what did not fit. Phase 1 files are read
in place from `../phase 1/`; Phase 2 keeps no copy.

Source of this log: the S1 parse of Phase 1 revision 2 (`S1_intake/run2_answered/s1_parse_log.json`,
removed from the tree in `22b327d`, kept in git history: `git show 22b327d^:"phase 2/S1_intake/run2_answered/s1_parse_log.json"`).

## Received

Phase 1 revision 2, `alu_spec.json` `spec_version` 1.1-proposed.

| File | Rows | sha256 (first 12) | Status |
|---|---|---|---|
| `alu_spec.json` | — | — | read |
| `ALU_Functional_Requirements.csv` | 13 | `9cda00528b13` | read |
| `ALU_Interfaces_and_Signals.csv` | 16 | `c8db6c26f6e7` | read |
| `ALU_Operation_Behavior_Table.csv` | 14 | `52c09880a3a1` | read |
| `ALU_Constraints_and_Assumptions.csv` | 18 | `4545cea31a4b` | read |
| `ALU_Verification_Requirements.csv` | 28 | `a77caf02dc1c` | read |
| `ALU_Open_Questions.csv` | 18 | `fa5d91fca391` | read |
| `ALU_Design_Decisions.csv` | 18 | `e1fb391a3b94` | read |
| `ALU_Golden_Vectors.csv` | 37 | `afffa535d31a` | read |

The hashes are of the committed files. A Windows checkout with `core.autocrlf=true` converts
line endings, so hash `git show HEAD:"phase 1/<file>"` rather than the working copy.

## Counts loaded

| Item | Count |
|---|---|
| Functional requirements (FR) | 13 |
| Interfaces (IF) | 16 |
| Types (`alu_op_t`) | 1 |
| Operations (OP) | 14 |
| Constraints and assumptions (CA) | 18 |
| Open questions (Q) | 18 |
| Decisions (D) | 18 |
| Classes | 4 |
| Verification tests (TC) | 28 |
| Golden vectors | 37 |
| Existing RTL files | 0 |

## Parse problems

None: every file was read and every row parsed.

## Inconsistencies found

None of these block Phase 2. Each is a question in `questions_for_phase1.md`.

| # | Inconsistency | Question | Handled by |
|---|---|---|---|
| 1 | `get_carry()` and `set_carry()` are in `alu_spec.json` but have no IF ID. | Q1 | traced to D-016 and D-005 |
| 2 | D-014 names the file `cpu.svh`, but the class is `CPU`. Verilator `-Wall` would report `DECLFILENAME`. | Q2 | deviation DV-1 (file `CPU.svh`) in `03_architecture/design_plan.md` |
| 3 | `arithmetic_alu` must clear `carry` in `initialize()`, but IF-007 declares it non-virtual. | Q3 | deviation DV-2 (`virtual initialize()`) |
| 4 | D-001..D-018 have no approver or date. | Q4 | all used as written |
| 5 | Priority is "Not specified" for all 13 FRs. | Q5 | all treated as Must |
| 6 | No coding rules were given. | Q6 | SystemVerilog-2017, one class per file, file name = class name |
