# Phase 4 and 5: first build and run

| Field | Value |
|---|---|
| When | 2026-10-20 ~21:00–21:35 +03:00 (start approximate; first commit 21:09) |
| Who | Adam, with Claude Code in VS Code |
| Branch | `phase-4-5` (from `main-fixed`) |
| Git | `cbcde43`..HEAD; commits: `80627e5` LF checkout, `00f5f02` Phase 4/5 scaffolding, `2ad4077` Phase 2 smoke build path, `7b4014f` Phase 3 compile fixes, `5cc1c8b` Phase 4 build path, `d3bcb29` Phase 4 evidence, `7e5a8e7` Phase 5 evidence, plus this entry; tags: none |
| Phases | 2, 3, 4, 5 |
| Keywords | phase 4, phase 5, WSL, Verilator 5.020, first compile, -Wall, before keyword, GNU Make spaces, CRLF, gitattributes, check_bit |

## Asked
Check whether Phases 2 and 3 were ready for Phases 4 and 5 (AGENTS.md definitions), then run both.

## Done
- Readiness: paths, API, golden-vector format and the RTL behind tag `phase2-rtl-v1` all lined up. Blockers were no simulator (WSL installed this session: Ubuntu 24.04, Verilator 5.020) and CRLF checkout.
- `.gitattributes` forces LF for all text files (`80627e5`).
- Phase 4 (`phase 4/build.sh`, `elab_report.md`): clean clone of `5cc1c8b` builds with one command; lint `-Wall` 0 messages; no waivers.
- First compile of `tb_cpu.sv` found 3 errors (`before` is reserved) and 31 width/unused warnings; all fixed in Phase 3 (`phase 3/repair_log.md`) with no change to any expected value or check count.
- All three build scripts failed under WSL because GNU Make refuses paths with spaces (`phase N/`); they now build in `mktemp -d`.
- Phase 5 (`phase 5/simulate.sh`): checker self-test OK; regression PASS at seeds 1 and 7; 44/44 bins; seed 1 reproducible. No defects.

## Decisions
- Fix the 31 tb warnings at source, not waive (Adam): keeps the test program at 0 lint messages like the RTL.
- LF for every text file, CSVs included: run_info sha256 must match across machines.
- Evidence is taken from a clean clone, not the working tree, because another session had uncommitted Phase 3 edits.

## Not done / follow-ups
- AGENTS.md phase table, known issues and `phase 3/verification_plan.md` §9 still say "never compiled": not updated here because those files had another session's uncommitted edits (Phase 3 test map). Update after that work is committed.
- Phase 3 README "Files" table should list `repair_log.md` (same reason).
- Optional second simulator (Questa/VCS) not run.
- DV-1 (`cpu.svh` vs `CPU.svh`) and D-001..D-018 approval still with Phase 1; all results provisional.

## Notes for later
- In Verilator 5.020, `e.num()` on an enum variable folds to a constant, so `-Wall` reports the variable as unused.
- Run WSL commands from PowerShell through a script file: nested quotes around `"phase N"` paths get stripped.
