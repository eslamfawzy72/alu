# Phase 6: Regression Testing

Phase 6 reruns the Phase 3 regression after a change, at many seeds, and keeps a history of the results. It is the repeatable gate after every change. It never fixes anything: it reports, and hands each failure to Phase 5 for triage. The agreed behaviour is in `spec.md`; the section numbers below refer to it.

It is run **by hand** (no CI for now), in Ubuntu (WSL on Windows) with Verilator 5.020 or later.

## Files

| File | Content |
|---|---|
| `spec.md` | the agreed behaviour of Phase 6 |
| `regress.sh` | the regression: change check, build gate, smoke test, checker self-test, seeds |
| `results/<UTC date-time>_<commit>_<level>/` | written by `regress.sh`, one folder per regression (see "Outputs") |
| `history.csv` | one row per regression, never edited afterwards (section 7) |

## Inputs (read in place, no copies)

| Input | Where |
|---|---|
| Design under test | `../phase 2/04_rtl/` (`files.f`, `rtl/`) |
| Test program and log checks | `../phase 3/tb/tb_cpu.sv`, `../phase 3/run.sh` (one call per seed) |
| Expected values | `../phase 1/ALU_Golden_Vectors.csv`; `spec_version` from `../phase 1/alu_spec.json` is recorded |
| Smoke test | `../phase 2/07_smoke/run_smoke.sh` (exits 1 unless `SMOKE: PASS`) |
| Build gate | `../phase 4/build.sh` (must print `LINT: PASS (no messages)` and `BUILD: PASS`) |
| Settings | top of `regress.sh`: seeds 1–20, `RANDOM_N=5000`, long run seed 99 at `RANDOM_N=100000` |

## Commands (from the repo root)

```bash
bash "phase 6/regress.sh" quick      # build gate, smoke, self-test, seed 1
bash "phase 6/regress.sh" full       # build gate, smoke, self-test, seeds 1 to 20
bash "phase 6/regress.sh" release    # full, plus seed 99 at RANDOM_N=100000
bash "phase 6/regress.sh" full --force   # run even if the inputs are unchanged
```

The console shows `regression_summary.txt`; its first line is `Phase 6 regression: PASS` or `FAIL`. Exit code 0 means PASS or skipped (inputs unchanged), 1 means anything else.

Run times: each seed is one `run.sh` call, and each call builds again, so `full` builds 21 times (section 10).

## Which level to run (section 4)

| What changed | Do first | Level |
|---|---|---|
| Phase 2: design commit | (nothing) | `quick` |
| Phase 2: new RTL tag (`phase2-rtl-vN`) | Phase 3 readiness check R10 | `full` |
| Phase 3: `tb_cpu.sv` or `run.sh` | (nothing) | `full` |
| Phase 1: golden vectors | (nothing) | `full` |
| Phase 1: a decision or the semantics | Phase 3 updates the checks that cite that ID | `full` |
| Verilator version | (nothing) | `full` |
| Release candidate | all of the above | `release` |

## What `regress.sh` does

1. **Change check (section 5).** It computes a fingerprint: the sha256 of each file in `phase 2/04_rtl/rtl/`, `files.f`, `tb_cpu.sv`, `run.sh` and the golden vectors, plus `spec_version` and `verilator --version`. The git commit is recorded but is not part of the fingerprint. If the fingerprint equals the last PASS row in `history.csv` and that row's level is the same or higher, it prints `inputs unchanged since <commit> (<level> PASS on <date>)` and exits 0 without running. Otherwise it lists the changed inputs (from that run's `fingerprint.txt`). If those changes, or a new RTL tag, call for a higher level than requested, it prints a `WARNING` naming the required level, then runs the requested level.
2. **Build gate.** `phase 4/build.sh`. On failure it stops with FAIL.
3. **Smoke test.** `phase 2/07_smoke/run_smoke.sh`. A failure fails the regression, but the seeds still run.
4. **Checker self-test.** `run.sh +CHECKER_SELFTEST`. If it is not OK, it stops with FAIL, because results from checkers that can't be trusted don't count.
5. **Seeds.** Seeds 2–20 (for `full` and `release`), then the long run (`release`), then **seed 1 last**, so `../phase 3/results/` ends up holding the seed-1 run of record. A failing seed is rerun once with the same arguments. If the two `sim.log` files are identical it is a real `FAIL`; if they differ it is `FLAKY`, which also counts as FAIL (section 8).

Side effects: `build.sh`, `run_smoke.sh` and `run.sh` rewrite their own output files in `phase 4/`, `phase 2/07_smoke/` and `phase 3/results/`. Phase 6 copies them into its results folder.

## Outputs (section 6)

| File | Content |
|---|---|
| `results/<...>/build/` | `console.log` and the Phase 4 `build_info.txt`, `lint.log`, `build.log` |
| `results/<...>/smoke/` | `summary.txt` (console), `sim.log` (= `smoke_log.txt`), `build.log` |
| `results/<...>/selftest/`, `seed<N>/`, `long/` | `summary.txt`, `sim.log`, `build.log`, `run_info.txt` from `run.sh`; a failing seed also has `rerun/` |
| `results/<...>/fingerprint.txt` | one `<sha256 or value>  <input>` line per input; used by the next change check |
| `results/<...>/regression_summary.txt` | verdict, level, commit, RTL tag, `spec_version`, Verilator, fingerprint, `RANDOM_N`, one line per step |
| `results/<...>/failures.txt` | on FAIL only: per failing seed (or step), FAIL/FLAKY, the TC and the first `FAIL` line |
| `history.csv` | `date,commit,rtl_tag,spec_version,verilator,level,seeds,random_n,pass,fail,verdict,fingerprint,results_dir` |

`rtl_tag` is the newest `phase2-rtl-v*` tag whose `phase 2/04_rtl/` matches the files under test, or `none`. `pass` and `fail` count seeds. A skipped run adds no row. Commit `history.csv` and the results folder after each real run.

The fingerprint hashes files as they are on disk, so line endings count. The repo's `.gitattributes` checks text files out with LF everywhere. A working copy made before that rule (with CRLF files) gives a different fingerprint until it is checked out again.

## When a regression fails (section 8)

1. Read `failures.txt`, then the step's `sim.log`.
2. Replay at the same seed: `bash "phase 3/run.sh" +SEED=<n> +RANDOM_N=<n>`.
3. Triage as in Phase 5 (`../phase 5/README.md` step 2) and record it in `../phase 5/defects.md`.
4. A design fix goes through `../phase 2/06_repairs/repair_log.md` and a new RTL tag. A checker fix goes through `../phase 3/repair_log.md`. Then run Phase 6 again at the level from the table above.

Never edit an expected value to make a seed pass.

## Exit criteria (section 9)

1. A `full` regression passes on the release-candidate RTL tag and the current `spec_version`.
2. No `FLAKY` result in that regression.
3. A `release` regression passes on the exact commit that Phase 8 signs off.
4. Every FAIL in `history.csv` has a matching entry in `../phase 5/defects.md`.

## Status

| Item | State (2026-10-22) |
|---|---|
| `regress.sh` | written. Its control flow (skip, `--force`, change list and level warning, FAIL vs FLAKY rerun, `failures.txt`, `history.csv`, seed-1-last order) was checked in WSL with a **stub** `verilator` that replays the committed Phase 3 and smoke logs. Those runs were discarded and don't count. |
| First real regression | **not run yet**: Verilator is not installed on the machine where this was written. Next step: `bash "phase 6/regress.sh" full` on a host with Verilator 5.020, then commit `history.csv` and `results/`. |
| Exit criteria | not met |

## Not decided yet (section 10)

- Seed count and long-run size (20 seeds, seed 99 at 100000) are working values.
- One build per seed (21 builds in `full`) is accepted for now.
- Coverage for Phase 7 needs one `COVERAGE BIN <name> <count>` line per bin from `tb_cpu.sv` (a Phase 3 change). Once it is in, each `seed<N>/sim.log` already keeps those lines for Phase 7.
- CI is out of scope.
