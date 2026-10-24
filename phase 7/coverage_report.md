# Phase 7 coverage report

**Status: goals G1, G2 and G4 (measured points) met; G3 and G4 (unmeasured lines) wait on 7 proposed exclusions that no reviewer has approved yet. Not a run of record: the Phase 3 repairs it measures are not committed yet.**

| Field | Value |
|---|---|
| Date | 2026-10-24 |
| Phase 6 run analysed | `../phase 6/results/2026-10-24T192925Z_e0fe096_full` (20 seeds, `RANDOM_N=5000`, PASS) |
| Commit | `e0fe096` with uncommitted Phase 3 repairs 4–6 (`dirty inputs: yes` in `run_config.txt`) |
| RTL | tag `phase2-rtl-v1`, unchanged |
| Spec | `spec_version` 1.2 |
| Tool | Verilator 5.020 (Ubuntu 24.04, WSL2) |
| Code coverage run | `results/code_2026-10-24T193414Z_e0fe096` (seed 1, `RANDOM_N=5000`) |

## 1. Results against the goals

| Goal (`coverage_goals.md`) | Measured | Result | Evidence |
|---|---|---|---|
| G1: 44 bins, each hit in every seed run | 44 bins found; 44 hit in 20 of 20 runs | **met** | `results/2026-10-24T192925Z_e0fe096_full/coverage_merged.txt` |
| G2: 28/28 TCs pass in every run, none partial | 28/28 pass in 20/20 runs; 28/28 covered, 0 partial | **met** | `../phase 6/results/2026-10-24T192925Z_e0fe096_full/test_report.txt`; `requirement_summary.txt` |
| G3: every FR, IF, OP, D covered or excluded | FR 13/13, IF 16/16, OP 14/14 covered; D 14/18 covered, D-011, D-014, D-016 partial, D-013 not covered | **not met**: 4 exclusions proposed, none approved | `results/2026-10-24T192925Z_e0fe096_full/requirement_summary.txt`, `requirement_coverage.csv` |
| G4: every RTL coverage point hit | 35/35 points (CPU 5/5, arithmetic_alu 14/14, base_alu 6/6, logical_alu 10/10) | **met** | `results/code_2026-10-24T193414Z_e0fe096/summary.txt`, `rtl_points.txt`, `annotated/` |
| G4: every line Verilator does not measure covered or excluded | 4 `$error` lines: 1 covered functionally, 3 proposed exclusions | **not met**: 3 exclusions proposed, none approved | section 3 |

## 2. Gaps found and how each was handled

Baseline for comparison: `../phase 6/results/2026-10-24T192036Z_e0fe096_full` (before any Phase 7 change). Its trace gave FR 12/13, IF 0/16, D 13/18, TC 27/28.

| # | Gap | Found by | Handled by | Now |
|---|---|---|---|---|
| 1 | Per-bin hit counts were not printed, so coverage could not be merged over seeds | reading `tb_cpu.sv` `cov_report()` | **test change:** Phase 3 repair 4 (`COVERAGE BIN` lines) | closed |
| 2 | TC-005 / D-010 / FR-005 partial: the `carry=<0/1>` field of `display()` was never checked (AGENTS.md known issue 3) | `test_map.csv` "Partly"; trace | **stronger check:** Phase 3 repair 5 (whole-line match, carry set to 1). A copy of the log with `carry=0` or no `carry=` fails the new check and passed the old one | closed |
| 3 | IF-001 to IF-016 not mapped to any test | trace ("not mapped") | **map:** Phase 3 repair 6, one `test_map.csv` row per IF naming the TCs that already exercise it | closed |
| 4 | D-013 not covered (no `extern`) | trace | **exclusion proposed** (`exclusions.md` D-013): source-style rule; evidence by `grep` and lint | open (needs review) |
| 5 | D-014 partial (include order and file names) | trace | **exclusion proposed** (D-014): covered by Phase 4 `elab_report.md` section 3 | open (needs review) |
| 6 | D-016 partial ("no overflow flag") | trace | **exclusion proposed** (D-016): absent member; evidence by `grep` | open (needs review) |
| 7 | D-011 partial (exact signatures) | trace | **exclusion proposed** (D-011): signatures in `base_alu.svh`, lint `-Wall` clean | open (needs review) |
| 8 | 4 RTL `$error` lines get no Verilator coverage point | `code_coverage.sh` "Not measured" | `CPU.svh:29`: **covered functionally** by TC-027 (both invalid codes return 0, leave the state unchanged, print one `%Error` each, 20/20 seeds). `arithmetic_alu.svh:65`, `logical_alu.svh:26`, `base_alu.svh:45`: **exclusions proposed** (RTL-1 to RTL-3): unreachable through `CPU.Calc` and not specified by Phase 1, so a test would invent behaviour | 1 closed, 3 open (need review) |

The proposed exclusions are proposals, not decisions. A reviewer may instead ask for a test (for example a compile-must-fail check for D-016), or ask Phase 1 to specify the `default` branch behaviour, which would turn RTL-1 to RTL-3 into tests.

## 3. Observations (goal met, worth knowing)

- **Thin shift-amount bins.** The bins where `B[31:5] = 0` get 4 to 8 hits per seed (for example `OP_ROL B[4:0]=31`: min 4), against about 300 for `B[31:5]!=0`. Three in four random operands are uniform 32-bit values (`verification_plan.md` section 5), whose upper 27 bits are almost never all zero, so in-range amounts come mainly from the corner values and the golden vectors. Every bin is still hit in every seed, so G1 holds. A Phase 3 option, not required: draw some B operands from 0..31.
- **Invalid codes** are hit exactly once per seed (`opcode 1110`, `opcode 1111`), by the directed TC-027 only, as planned (`verification_plan.md` section 5).
- **Reproducibility.** The baseline's seed 1 `sim.log` is byte-identical to the committed `../phase 3/results/sim.log` from 2026-10-20. After repairs 4 and 5, the only `sim.log` differences in all 20 seeds are the new `COVERAGE BIN` lines, the TC-005 `carry=1` line and the `$finish` line number, and the per-TC check counts are identical, so the stimulus did not change.

## 4. What is left for exit

1. A reviewer decides the 7 proposed exclusions in `exclusions.md` (approve with name and date, reject, or ask for a test).
2. Commit Phase 3 repairs 4–6 and the Phase 6–8 folders; then a Phase 6 `full` run with `dirty inputs: no`, and the three Phase 7 scripts on it, to make these results a run of record.
