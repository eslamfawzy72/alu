# Phase 6: Regression Testing

Phase 6 reruns every existing check after a change, at many seeds, and keeps the evidence of each run: what was tested (commit, RTL tag, spec version, tool, sha256 of every input), the logs, a pass/fail summary, a per-TC test report and a comparison with the previous run. It is the repeatable gate between a change and the next phase.

**Rule:** Phase 6 fixes nothing and changes nothing outside `phase 6/`. Every failure is triaged by Phase 5 (`../phase 5/README.md` step 2) and recorded in `../phase 5/defects.md`. A DUT fix goes through `../phase 2/06_repairs/repair_log.md` and a new RTL tag; a test-program fix goes through `../phase 3/repair_log.md`. Never edit an expected value to make a seed pass.

## Files

| File | Written by | Content |
|---|---|---|
| `regress.sh` | hand | the regression: build gate, smoke, checker self-test, seeds; writes everything below |
| `results/<UTC date-time>_<commit>_<level>/` | `regress.sh` | one folder per run (see "Outputs"); never edited afterwards |
| `history.csv` | `regress.sh` | one row per run, appended; never edited afterwards |
| `regression_report.md` | hand | the runs of record, why each was run, what the comparison shows, and the investigation status of every failure |

## Inputs

Read in place from the other phase folders; nothing is copied into Phase 6 except each run's outputs.

| From | File | Used for |
|---|---|---|
| Phase 1 | `../phase 1/ALU_Golden_Vectors.csv`, `../phase 1/alu_spec.json` | expected values (read by the test program); `spec_version` recorded per run |
| Phase 2 | `../phase 2/04_rtl/` | the DUT; RTL tag `phase2-rtl-v*` recorded per run |
| Phase 2 | `../phase 2/07_smoke/run_smoke.sh` | smoke gate |
| Phase 3 | `../phase 3/run.sh`, `../phase 3/tb/tb_cpu.sv` | the regression, one call per seed |
| Phase 4 | `../phase 4/build.sh` | build gate: lint `-Wall` and build, warnings fatal |
| Phase 5 | `../phase 5/defects.md`, `../phase 5/README.md` step 2 | where failures are triaged and tracked |

## Settings

At the top of `regress.sh`. These are working values chosen by Phase 6, not Phase 1 requirements.

| Setting | Value | Why |
|---|---|---|
| seeds (`full`, `release`) | 1 to 20 | 20 independent random streams on top of the directed tests |
| `RANDOM_N` | 5000 | the Phase 3 default; below about 3000 some shift-amount bins stay empty (Phase 3 README step 5) |
| long run (`release`) | seed 99, `RANDOM_N=100000` | one deep run before signoff |
| smoke pass line | `SUMMARY pass=91 fail=0` | Phase 2 README, `07_smoke` "done when" |

## Commands

Run in Ubuntu (WSL on Windows) with Verilator 5.020 or later, from the repo root:

```bash
bash "phase 6/regress.sh" quick   --note "why"   # build gate, smoke, self-test, seed 1       (~1 min)
bash "phase 6/regress.sh" full    --note "why"   # same, seeds 1 to 20                         (~6 min)
bash "phase 6/regress.sh" release --note "why"   # full, plus seed 99 at RANDOM_N=100000
```

The console ends with `regression_summary.txt`; its first line is `Phase 6 regression: PASS` or `FAIL`. Exit code 0 means PASS. `--note` is stored in `run_config.txt` and `history.csv`; say what changed.

## Which level to run

From the Phase 3 README table "Redoing Phase 3 after a change":

| What changed | Do first | Level |
|---|---|---|
| any commit that touches no input below | nothing | `quick` |
| Phase 3 `tb_cpu.sv` or `run.sh` (new test, new bin, tighter check) | log it in `../phase 3/repair_log.md` | `full` |
| Phase 2 RTL (new tag `phase2-rtl-vN`) | Phase 3 readiness check R10 | `full` |
| Phase 1 golden vectors | nothing | `full` |
| Phase 1 decision or semantics | Phase 3 updates the checks citing that ID | `full` |
| Verilator version | nothing | `full` |
| release candidate for Phase 8 | everything above done and committed | `release` |

## What `regress.sh` does

1. **Records what is under test** in `run_config.txt`: date, level, note, commit, branch, whether any input has uncommitted changes, RTL tag (the newest `phase2-rtl-v*` whose `04_rtl/` equals the files under test, else `none`), `spec_version`, Verilator version, host, seeds, `RANDOM_N`, and the sha256 of every input (RTL files, `files.f`, smoke test and script, `tb_cpu.sv`, `run.sh`, `phase 4/build.sh`, golden vectors, `alu_spec.json`).
2. **Build gate:** `phase 4/build.sh`. A failure stops the run.
3. **Smoke:** `phase 2/07_smoke/run_smoke.sh`, judged from `smoke_log.txt` (the pass line and exactly 2 `%Error` lines, one per invalid code), because `run_smoke.sh` always exits 0. A failure fails the run, but the later steps still run.
4. **Checker self-test:** `phase 3/run.sh +CHECKER_SELFTEST` must catch its corrupted value. If not, the run stops: results from checkers that can't be trusted don't count.
5. **Seeds:** `phase 3/run.sh +SEED=<n> +RANDOM_N=<n>` per seed, then the long run (`release`). A failing seed is rerun once with the same arguments: the same log again is a real `FAIL`; a pass or a different log is `FLAKY`, which also fails the run (the design and test program are deterministic for a given seed, so flakiness is itself a defect).
6. **Reports:** test report, comparison with the previous run in `history.csv`, failures, summary, history row.
7. **Restores** the files the gate scripts rewrite (`phase 2/07_smoke/smoke_log.txt` and `build.log`, `phase 4/build_info.txt`, `lint.log`, `build.log`, `phase 3/results/`), so the evidence of record of the other phases is left as it was.

## Outputs

Per run, in `results/<UTC date-time>_<commit>_<level>/`:

| File | Content |
|---|---|
| `run_config.txt` | what was tested (step 1) |
| `regression_summary.txt` | verdict, RTL tag, spec version, tool, seeds pass/fail/flaky, TCs passed, coverage, one line per step |
| `steps.txt` | one `<step> <status> [detail]` line per step (read by the next run's comparison) |
| `test_report.txt` | every TC over all seed runs: status, runs passed, checks summed; coverage line per seed |
| `comparison.txt` | against the previous run: verdict, config, inputs whose sha256 changed, step status, TC status changes, whether each seed's `sim.log` is identical |
| `failures.txt` | only on FAIL: each failed step, the first `FAIL` line or coverage holes, and the replay command |
| `build/` | `console.log` and Phase 4 `build_info.txt`, `lint.log`, `build.log` |
| `smoke/` | `console.log`, `sim.log` (= `smoke_log.txt`), `build.log` |
| `selftest/`, `seed<N>/`, `long/` | `console.log` and `run.sh`'s `summary.txt`, `sim.log`, `build.log`, `run_info.txt`; a failing seed also has `rerun/` |

`history.csv` columns: `date,commit,dirty,rtl_tag,spec_version,verilator,level,seeds,random_n,seeds_pass,seeds_fail,seeds_flaky,verdict,results_dir,note`.

When no input changed, the same seed gives a byte-identical `sim.log`, so `comparison.txt` should say `identical` for every seed. `differs` with unchanged inputs means non-determinism and must be investigated.

## When a regression fails

1. Read `failures.txt`, then the step's `sim.log`.
2. Replay with the printed command, for example `bash "phase 3/run.sh" +SEED=7 +RANDOM_N=5000`.
3. Triage as in `../phase 5/README.md` step 2 and add a row to `../phase 5/defects.md` before fixing anything.
4. After the fix, run the level from the table above, and record the failure and its status in `regression_report.md`.

## Exit criteria

1. A `full` run passes on the release-candidate RTL tag and the current `spec_version`, with no uncommitted inputs.
2. No `FLAKY` result in that run.
3. Every `FAIL` row in `history.csv` has a matching entry in `regression_report.md` and, if it was a defect, in `../phase 5/defects.md`.
4. A `release` run passes on the exact commit that Phase 8 signs off.

## Status

See `regression_report.md` for the runs of record.
