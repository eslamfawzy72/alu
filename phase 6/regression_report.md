# Phase 6 regression report

The runs of record and what each one shows. Every number below comes from the run's own files in `results/`; `history.csv` has one row per run.

## Runs

| # | Run (`results/…`) | Level | Commit | Inputs | Why | Verdict |
|---|---|---|---|---|---|---|
| 1 | `2026-10-24T192036Z_e0fe096_full` | full | `e0fe096` | committed | **baseline** on spec 1.2: the Phase 4/5 evidence was from `5cc1c8b`, and `tb_cpu.sv` (comment) and `alu_spec.json` (1.1 → 1.2) changed since | **PASS** |
| 2 | `2026-10-24T192925Z_e0fe096_full` | full | `e0fe096` | **uncommitted** Phase 3 repairs 4–5 | after a change: per-bin coverage lines (T4) and the whole-line TC-005 check (C1) | **PASS** (not a run of record until committed) |

Before run 1, three script tests (one `quick` PASS, two deliberate `quick` FAILs with `RANDOM_N=100` to exercise the failure path, the FAIL-vs-FLAKY rerun, `failures.txt` and the comparison) were run and then deleted with their history rows; they tested `regress.sh`, not the design.

## Run 1: baseline

- Build gate PASS (lint 0 messages), smoke PASS (`SUMMARY pass=91 fail=0`, 2 `%Error`), checker self-test OK.
- Seeds 1–20 at `RANDOM_N=5000`: 20 PASS, 0 FAIL, 0 FLAKY. 28/28 TCs pass in every seed; `COVERAGE 44/44` in every seed (`test_report.txt`).
- Seed 1 `sim.log` is byte-identical to the committed `../phase 3/results/sim.log` of 2026-10-20 (commit `5cc1c8b`, other machine): the result reproduces across machines and commits.
- 6 min 48 s.

## Run 2: after Phase 3 repairs 4–5

`comparison.txt` against run 1:

| Item | Result |
|---|---|
| Inputs changed | `phase 3/run.sh`, `phase 3/tb/tb_cpu.sv` (nothing else: RTL, golden vectors, spec unchanged) |
| Verdict | PASS → PASS |
| Steps | build, smoke, self-test, seeds 1–20: all PASS → PASS |
| TC status changes | none; per-TC check counts identical (`test_report.txt` identical) |
| Seed logs | all 20 differ, as expected when an input changed. Checked line by line: the only differences are the 44 new `COVERAGE BIN` lines, the TC-005 arithmetic display line (`carry=1`, was `carry=0` and unchecked) and the `$finish` line number (the file grew by 6 lines). The stimulus did not change. |

The stricter TC-005 check was also shown to fail when it should: on a copy of the seed-1 log with the display line changed to `carry=0`, or with `carry=` removed, the new check finds 2 of 3 lines (FAIL); the old substring check found 3 of 3 (PASS).

## Failures and investigation status

| Run | Failure | Investigation | Status |
|---|---|---|---|
| — | none in runs 1 and 2 | — | — |

No defect was found; `../phase 5/defects.md` is unchanged.

## Next runs

1. After the Phase 3 repairs and the Phase 6–8 folders are committed: `full`, so run 2's result becomes a run of record (`dirty inputs: no`).
2. Release candidate for Phase 8: `release` (seeds 1–20 plus seed 99 at `RANDOM_N=100000`) on the frozen commit.
