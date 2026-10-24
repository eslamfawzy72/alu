# Phase 7: Coverage Analysis & Closure

Phase 7 measures how complete the verification is, compares it with the goals in `coverage_goals.md`, and closes every gap: either with new or stronger stimulus and checks in Phase 3, or with a written exclusion that a reviewer approves.

**Rule:** Phase 7 measures and reports. Test-program changes are made in Phase 3 and logged in `../phase 3/repair_log.md`; then Phase 4 builds and Phase 6 reruns. A gap is never closed by removing a bin, loosening a check, editing an expected value or lowering a goal, and a proposed exclusion does not count until it is approved.

## Files

| File | Written by | Content |
|---|---|---|
| `coverage_goals.md` | hand | goals G1 to G4, status words, closure rules |
| `merge_coverage.sh` | hand | G1: merges the per-bin hit counts of one Phase 6 run over all its seeds |
| `trace_requirements.py` | hand | G2, G3: status of every FR, IF, OP, D and TC in one Phase 6 run |
| `code_coverage.sh` | hand | G4: RTL line/block/branch coverage with `verilator --coverage` |
| `results/<phase 6 run>/` | the two scripts above | `coverage_merged.txt`, `requirement_coverage.csv`, `requirement_summary.txt` |
| `results/code_<UTC date-time>_<commit>/` | `code_coverage.sh` | `summary.txt`, `rtl_points.txt`, `annotated/`, `coverage.dat`, `sim.log`, `build.log`, `run_info.txt` |
| `coverage_report.md` | hand | each goal against the measured result, the gaps found, how each was closed, what is left and why |
| `exclusions.md` | hand | one row per proposed or approved exclusion, with reason, evidence, reviewer and date |

## Inputs

| From | File | Used for |
|---|---|---|
| Phase 6 | `../phase 6/results/<run>/seed*/sim.log`, `test_report.txt`, `run_config.txt` | per-bin hits, TC results, what was tested |
| Phase 3 | `../phase 3/verification_plan.md` section 7, `../phase 3/test_map.csv` | the 44 bins; which TC checks each OP, D and IF, and what is only partly checked |
| Phase 3 | `../phase 3/tb/tb_cpu.sv` | prints `COVERAGE BIN <name> <hits>` per bin (Phase 3 repair 4) |
| Phase 2 | `../phase 2/04_rtl/rtl/`, `../phase 2/02_requirements/requirements_map.csv` | code coverage; `// @ID` tags and owner file per ID |
| Phase 1 | `ALU_Functional_Requirements.csv`, `ALU_Interfaces_and_Signals.csv`, `ALU_Operation_Behavior_Table.csv`, `ALU_Design_Decisions.csv`, `ALU_Verification_Requirements.csv` | every ID to trace; TC → FR links |

## Steps

Run in Ubuntu (WSL on Windows) with Verilator 5.020 or later and `python3`, from the repo root.

1. Run a Phase 6 `full` regression on the commit to analyse: `bash "phase 6/regress.sh" full --note "..."`.
2. Measure, giving that run's folder:
   ```bash
   R="phase 6/results/<run>"
   bash "phase 7/merge_coverage.sh" "$R"          # G1  -> phase 7/results/<run>/coverage_merged.txt
   python3 "phase 7/trace_requirements.py" "$R"   # G2, G3 -> requirement_summary.txt, requirement_coverage.csv
   bash "phase 7/code_coverage.sh"                # G4  -> phase 7/results/code_<date>_<commit>/summary.txt
   ```
   Each script exits 0 only when its goal is met.
3. For every gap, decide how to close it, in this order of preference:
   - **test it:** a new directed test, a stronger check or a new bin in `../phase 3/tb/tb_cpu.sv` or `run.sh`, logged in `../phase 3/repair_log.md` and mapped in `../phase 3/test_map.csv`; then Phase 4 `build.sh` and a Phase 6 `full` run, and back to step 2;
   - **map it:** if a passing test already checks the ID but `test_map.csv` doesn't say so, add the row (no regression needed, but rerun `trace_requirements.py`);
   - **exclude it:** if it can't be checked by simulation, add a row to `exclusions.md` with the reason and the evidence that covers it elsewhere, and get it reviewed.
4. Write `coverage_report.md`: the Phase 6 run and commit analysed, each goal with its measured result and a link to the output file, every gap with its closure or its open status.
5. Commit `results/`, `coverage_report.md`, `exclusions.md` and the Phase 3 changes.

## Exit criteria

1. G1: `coverage_merged.txt` says the goal is MET on the release-candidate `full` run.
2. G2, G3: `requirement_summary.txt` lists no ID under "Not covered yet".
3. G4: `code_coverage.sh` summary shows every RTL point hit, and every "not measured" line is closed in `coverage_report.md`.
4. Every row in `exclusions.md` has status `approved`, a reviewer and a date.

## Redoing Phase 7 after a change

Any change to `../phase 2/04_rtl/`, `../phase 3/tb/tb_cpu.sv`, `../phase 3/run.sh`, `../phase 3/test_map.csv` or the Phase 1 files: run Phase 6 `full`, then step 2 again on the new run, and update `coverage_report.md`.
