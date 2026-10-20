# Phase 5: Simulation & Debugging

Phase 5 runs the Phase 3 regression on the binary that Phase 4 showed builds. It triages every failure to its owner and tracks each defect until it is closed.

**Rule:** never edit an expected value to make a test pass. A failing check is a DUT bug (Phase 2 fixes it), a test-program or reference-model bug (Phase 3 fixes it), or a spec gap (Phase 1 answers it).

## Files

| File | Content |
|---|---|
| `simulate.sh` | runs the checker self-test, seed 7 and seed 1 twice through `../phase 3/run.sh`; checks reproducibility and that the seed changes the stimulus |
| `runs/<name>/` | written by `simulate.sh`: each run's `summary.txt`, `sim.log`, `build.log`, `run_info.txt` |
| `runs/summary.txt` | one line per check, with the overall verdict |
| `defects.md` | one row per defect, from first FAIL to closure |

## Inputs

| From | File | Used for |
|---|---|---|
| Phase 4 | `../phase 4/elab_report.md` | must show zero errors and every warning dispositioned |
| Phase 3 | `../phase 3/run.sh`, `../phase 3/README.md` step 6 | the regression and the triage rules |
| Phase 2 | `../phase 2/08_release/phase2_handoff.md` | DUT tag; flags F1 (`$error` stops Verilator) and F2 (`carry` is state) |

## Steps

Run in Ubuntu (WSL on Windows) with Verilator 5.020 or later, after Phase 4 passes.

1. `bash simulate.sh`. If the checker self-test is not OK, stop and fix `../phase 3/tb/tb_cpu.sv`.
2. Triage every `FAIL` line in `runs/*/sim.log` and every failed `LOG-CHECK`:
   - **"reference model disagrees with Phase 1 golden vector N":** model bug. Phase 3 fixes the model to follow `alu_spec.json`.
   - **A DUT check fails and its Phase 1 source is clear:** DUT bug. Phase 2 fixes it, logs it in `06_repairs/repair_log.md` and tags a new release.
   - **A DUT check fails and its Phase 1 source is unclear:** add a question to `questions_for_phase1.md` here.

   Write each one into `defects.md` before fixing it.
3. Debug at a fixed `+SEED` with `$display` traces, using `bash "../phase 3/run.sh" +SEED=<n>`. Waveforms add little: the DUT is a class model, and Verilator does not trace class members.
4. After each fix, rerun Phase 4 (`bash "../phase 4/build.sh"`) and then step 1.
5. Commit `runs/`, `defects.md` and `../phase 3/results/`, and update `../phase 3/verification_plan.md` section 9.

## Exit criteria

- checker self-test OK;
- `Phase 3 regression: PASS` at seed 1 (`COVERAGE 44/44 bins hit`, both `LOG-CHECK` lines PASS);
- seed 1 reproducible, and seed 7 drives different stimulus;
- every defect in `defects.md` closed or formally deferred.

Results are provisional until Phase 1 approves D-001..D-018.

## Status

| Item | State (2026-10-20, clean clone of `5cc1c8b`, Verilator 5.020 on WSL2) |
|---|---|
| Checker self-test | OK: the corrupted value was reported as `FAIL TC-001` |
| Regression, seed 1 | PASS: 27 counted TCs pass with 0 failures, `COVERAGE 44/44 bins hit`, TC-005 and TC-027 log checks PASS |
| Regression, seed 7 | PASS, with different per-TC counts from seed 1 |
| Reproducible | yes: two seed-1 runs gave identical logs |
| Defects | none (`defects.md`) |
| Exit criteria | met, provisional |
