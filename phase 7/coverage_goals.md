# Phase 7 coverage goals

The goals Phase 7 measures against. A goal is met only by the outputs of a real run (Phase 6 regression plus the Phase 7 scripts), never by assertion.

| # | Metric | Goal | Source of the goal | Measured by |
|---|---|---|---|---|
| G1 | Functional coverage | all 44 bins (16 opcode, 8 carry out, 4 carry in, 16 shift/rotate amount) hit in **every** seed run of a `full` regression | `../phase 3/verification_plan.md` section 7; AGENTS.md Phase 7 | `merge_coverage.sh` → `coverage_merged.txt` |
| G2 | Test coverage | 28 of 28 Phase 1 TCs pass in every seed run, and none is only partly checked | `../phase 1/ALU_Verification_Requirements.csv`; AGENTS.md Phase 7 | Phase 6 `test_report.txt`; `trace_requirements.py` (TC rows) |
| G3 | Requirement coverage | every FR (13), IF (16), OP (14) and D (18) is covered by a passing TC, or has an approved exclusion | AGENTS.md Phase 7 ("every FR traced to at least one passing TC"), extended to IF, OP and D | `trace_requirements.py` → `requirement_summary.txt`, `requirement_coverage.csv` |
| G4 | RTL code coverage | every Verilator coverage point in `../phase 2/04_rtl/rtl/` hit; every RTL line that Verilator does not measure (`$error` branches) covered by a functional check or an approved exclusion | **proposed by Phase 7 (2026-10-24), to be confirmed**; no percentage target was set | `code_coverage.sh` → `summary.txt`, `rtl_points.txt` |

## Status words

Used by `trace_requirements.py` and `coverage_report.md`:

| Status | Meaning |
|---|---|
| covered | every test that cites the ID passed in every seed run, and `test_map.csv` gives no "Partly" or "Not tested" reason |
| partial | the tests pass, but `test_map.csv` says part of the ID is not checked |
| excluded | `exclusions.md` has the ID with status `approved`, a reviewer and a date |
| failing | a test that cites the ID failed in at least one seed run |
| not run | a test that cites the ID has no result in the run |
| not covered | no test checks the ID, or `test_map.csv` says "Not tested" |
| not mapped | the ID has no row in `test_map.csv` and no TC cites it |

## Rules

- A gap is closed by new or stronger stimulus or checks in Phase 3 (logged in `../phase 3/repair_log.md`, followed by a Phase 4 build and a Phase 6 `full` run), or by an exclusion in `exclusions.md` with a reason, evidence, a reviewer and a date.
- A gap is never closed by removing a bin, loosening a check, editing an expected value or lowering a goal.
- A proposed exclusion does not count until it is approved.
