# Phase 3 test map

| Field | Value |
|---|---|
| When | 2026-10-20 21:00–21:15 +0300 |
| Who | Adam, with Claude Code in VS Code |
| Branch | main-fixed |
| Git | `cbcde43`..(uncommitted); commits: none yet; tags: none |
| Phases | 1, 3, 7 |
| Keywords | test_map.csv, traceability, ALU_Verification_Requirements, TC-005, TC-027, D-010 |

## Asked
Which phase owns `ALU_Verification_Requirements.csv`, and whether Phase 3 should keep a
"where is each requirement tested" map like Phase 2's `requirements_map.csv`.

## Done
- Added `phase 3/test_map.csv`: one row per TC (28), OP (14) and D-ID (18), with where and how
  each is checked in `tb/tb_cpu.sv` / `run.sh`, the expected-value sources and coverage bins.
  The 44 bins listed on the TC rows match `verification_plan.md` section 7.
- Replaced the TC table in `verification_plan.md` section 4 with a description of the CSV.
  Updated `phase 3/README.md` (files table, step 3), the `tb_cpu.sv` header and `AGENTS.md`
  (repository map, Phase 7 traceability inputs) to point at it.

## Decisions
- `ALU_Verification_Requirements.csv` stays a Phase 1 file. It defines what passes; Phase 3
  defines how that is tested (ground rules 1 and 4).
- The map has no pass/fail column. Results come from `results/summary.txt`, and Phase 7 joins them.
- Only one copy of the map is kept: the plan describes the CSV instead of repeating it.

## Not done / follow-ups
- TC-005 / D-010: `run.sh` matches the expected display text as a substring, so the
  `carry=<0/1>` field that arithmetic_alu adds is never checked. Marked "Partly" in the map.
  Fixing it needs a Phase 3 change.
- TC-027: Phase 1 lists FR-001, FR-006, FR-007, but the testbench comment cites FR-010 (Calc).
  The map follows Phase 1. This could be a question for Phase 1.
- D-013, the include-order part of D-014, and the "no overflow flag" part of D-016 are not
  tested by Phase 3 (reasons are in the map).

## Notes for later
Other work (`phase 4/`, `phase 5/`, `phase 3/repair_log.md`, commit `80627e5`) appeared in the
same checkout during this session. It is not part of this entry.
