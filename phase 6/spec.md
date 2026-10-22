# Phase 6 spec: Regression Testing

Status: agreed behaviour, not implemented yet. Build `regress.sh` and this folder's `README.md` from this file.

## 1. Purpose

Phase 6 reruns the Phase 3 regression after a change, at many seeds, and keeps a history of the results. It is the repeatable gate after every change. It never fixes anything: it reports, and hands each failure to Phase 5 for triage.

Phase 6 is run **by hand**: `bash "phase 6/regress.sh" <level>`. There is no CI for now.

## 2. Inputs

Phase 6 reads these in place and keeps no copies (ground rule 3 in `AGENTS.md`).

| Input | Where | Use |
|---|---|---|
| Design under test | `phase 2/04_rtl/` (`files.f`, `rtl/`) | the code under test, at the checked-out commit |
| Test program and log checks | `phase 3/tb/tb_cpu.sv`, `phase 3/run.sh` | each seed is one `run.sh` call |
| Expected values | `phase 1/ALU_Golden_Vectors.csv`, `spec_version` in `phase 1/alu_spec.json` | read by the test program at run time; `spec_version` is recorded |
| Smoke test | `phase 2/07_smoke/run_smoke.sh` | part of every level |
| Build gate | `phase 4/build.sh` | must print `LINT: PASS (no messages)` and `BUILD: PASS` before any seed runs |
| Settings | `regress.sh` (seed lists, `RANDOM_N`) | the only thing Phase 6 owns |
| Previous results | `phase 6/history.csv` | baseline for the change check (section 5) |

## 3. Levels

| Level | Steps (in order) | Use for |
|---|---|---|
| `quick` | build gate, smoke test, checker self-test, seed 1 | any commit that touches `phase 2/04_rtl/` |
| `full` | build gate, smoke test, checker self-test, seeds 1 to 20 at `RANDOM_N=5000` | a new RTL tag, any change to Phase 1 or Phase 3 inputs, a Verilator upgrade |
| `release` | `full`, plus one long run (seed 99, `RANDOM_N=100000`) | the release candidate before Phase 8 signoff |

Rules for every level:
- Stop with FAIL if the build gate or the checker self-test fails. Results from checkers that can't be trusted don't count.
- `RANDOM_N` is never below 3000. Below that, some coverage bins stay empty.
- Seed 1 runs last, so `phase 3/results/` ends up holding the seed-1 run as the regression of record (same rule as Phase 5).
- Paths contain spaces. Build only through `run.sh` and `build.sh`, which already use temp folders.

## 4. When to run

| What changed | Do first | Level |
|---|---|---|
| Phase 2: design commit | (nothing) | `quick` |
| Phase 2: new RTL tag (`phase2-rtl-vN`) | Phase 3 readiness check R10 | `full` |
| Phase 3: `tb_cpu.sv` or `run.sh` | (nothing; the self-test runs in every level) | `full` |
| Phase 1: golden vectors | (nothing) | `full` |
| Phase 1: a decision or the semantics | Phase 3 updates the checks that cite that ID | `full` |
| Verilator version | (nothing) | `full` |
| Release candidate | all of the above | `release` |

The Phase 1 and Phase 3 rows follow `phase 3/README.md`, "Redoing Phase 3 after a change".

## 5. Change check (fingerprint)

Before running, `regress.sh` computes a fingerprint of its inputs:
- sha256 of each file in `phase 2/04_rtl/rtl/` and of `files.f`;
- sha256 of `phase 3/tb/tb_cpu.sv`, `phase 3/run.sh` and `phase 1/ALU_Golden_Vectors.csv`;
- `spec_version` and `verilator --version`.

The git commit is recorded but is not part of the fingerprint, because a commit that only changes docs is not a reason to rerun.

Then it compares the fingerprint with the last PASS row in `history.csv`:
- **Same fingerprint, and that row's level is the same or higher:** print `inputs unchanged since <commit> (<level> PASS on <date>)` and exit 0 without running. `--force` runs anyway.
- **Otherwise:** print which inputs changed. If section 4 asks for a higher level than the one requested, print a warning naming the required level, then run the requested level.

## 6. Outputs

All outputs are written under `phase 6/`.

| Output | Content |
|---|---|
| `results/<UTC date>_<commit>_<level>/` | one subfolder per step (`smoke/`, `selftest/`, `seed<N>/`, `long/`), each holding the files that step's script wrote (`summary.txt`, `sim.log`, `build.log`, `run_info.txt`) |
| `results/<...>/regression_summary.txt` | first line `Phase 6 regression: PASS` or `FAIL`; then the level, commit, RTL tag (or `none`), `spec_version`, Verilator version, fingerprint, `RANDOM_N`, and one line per step with its verdict |
| `results/<...>/failures.txt` | only on FAIL: for each failing seed, the seed number, the TC and the first `FAIL` line of its `sim.log` |
| `history.csv` | one row added per regression (section 7) |
| console | the content of `regression_summary.txt` |

Exit code: 0 for PASS or a skip (section 5), 1 otherwise. This matches `run.sh` and `simulate.sh`.

## 7. `history.csv`

One row per regression, never edited afterwards:

`date,commit,rtl_tag,spec_version,verilator,level,seeds,random_n,pass,fail,verdict,fingerprint,results_dir`

`seeds` lists the seeds run (e.g. `1-20`, `1-20+99`). `pass` and `fail` count seeds. A skipped run adds no row.

## 8. Failures and flaky results

- A failing seed is rerun once with the same arguments.
- If the rerun's `sim.log` is identical: the failure is real. The verdict is FAIL and the seed goes to `failures.txt`.
- If the rerun's `sim.log` differs: mark it `FLAKY`. That also counts as FAIL, because Phase 5 showed that runs are reproducible.
- Triage follows Phase 5: replay the seed with `bash "phase 3/run.sh" +SEED=<n> +RANDOM_N=<n>` and record it in `phase 5/defects.md`. A design fix goes through `phase 2/06_repairs/repair_log.md` and a new RTL tag. A checker fix goes through `phase 3/repair_log.md`. Then run Phase 6 again (section 4).
- Never edit an expected value to make a seed pass (ground rule 4).

## 9. Exit criteria

1. A `full` regression passes on the release-candidate RTL tag and the current `spec_version`.
2. No `FLAKY` result in that regression.
3. A `release` regression passes on the exact commit that Phase 8 signs off.
4. Every FAIL in `history.csv` has a matching entry in `phase 5/defects.md`.

## 10. Not decided yet

- **Seed count and long-run size** (20 seeds, seed 99 at 100000): working values. Change them if the course or Siemens asks for specific numbers.
- **One build per seed:** `run.sh` rebuilds for every seed (21 builds in `full`). This is accepted for now because it needs no Phase 3 change. Revisit if `full` takes too long.
- **Coverage for Phase 7:** `tb_cpu.sv` prints only empty bins and the total. Merging coverage across seeds needs one `COVERAGE BIN <name> <count>` line per bin, which is a Phase 3 change (logged in `phase 3/repair_log.md`). Once that change is in, Phase 6 keeps the lines in each `seed<N>/sim.log` and Phase 7 reads them from there.
- **CI (GitHub Actions):** out of scope for now. Phase 6 is run by hand.
