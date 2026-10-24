# Verification signoff report: ALU class model

## Final status: NOT SIGNED OFF

`signoff_check.txt` (2026-10-24, HEAD `55c4e4c`): **NOT READY**, 6 FAIL, 2 MANUAL. The design has passed every regression run so far and no defect is open, but signoff needs open Phase 1 questions answered, exclusions reviewed and a `release` regression on the frozen commit. Each blocker is listed in section 7 and in `open_issues.md`.

This report is filled in from the evidence as it stands. Re-run `python3 "phase 8/signoff_check.py"` and update every section on the signoff commit before anyone approves it.

## 1. Accepted RTL revision (candidate)

| Field | Value | Evidence |
|---|---|---|
| RTL tag | `phase2-rtl-v1` (commit `22b327d`), on `origin` | `signoff_check.txt`; `git ls-remote --tags origin` |
| RTL unchanged since the tag | yes: `phase 2/04_rtl/` at HEAD equals the tag | `signoff_check.txt` |
| Files (sha256) | `CPU.svh` 1dc5112e…, `arithmetic_alu.svh` f73ad7d7…, `base_alu.svh` 69f898bf…, `cpu_pkg.sv` fa0fc1fb…, `logical_alu.svh` 8bb6c191…, `files.f` c1b7cdab… | `../phase 6/results/2026-10-24T201629Z_2deaa9f_full/run_config.txt` |
| Spec | `spec_version` 1.2; D-001..D-018 approved (Adam, 2026-10-20) | `../phase 1/alu_spec.json`, `ALU_Design_Decisions.csv` |
| Tools | Verilator 5.020 2024-01-01 (Debian 5.020-1), Ubuntu 24.04.5 on WSL2; python3 for the trace | `run_config.txt` |
| Signoff commit | not frozen yet; latest run of record on `2deaa9f` (committed, pushed to `origin/phase-6-8`) | `../phase 6/history.csv` |

## 2. Build and lint

Phase 4 build gate in every Phase 6 run: lint `-Wall` of DUT + test program 0 messages, build PASS, warnings fatal, no waivers (`../phase 4/elab_report.md`; `../phase 6/results/*/build/`).

## 3. Final test and regression summary (run of record on `2deaa9f`; not yet the frozen signoff commit)

| Item | Result | Evidence |
|---|---|---|
| Smoke | PASS, `SUMMARY pass=91 fail=0`, 2 expected `%Error` lines | `../phase 6/results/2026-10-24T201629Z_2deaa9f_full/smoke/` |
| Checker self-test | OK (the corrupted value was reported as FAIL) | same run, `selftest/` |
| Regression | `full`, seeds 1–20 at `RANDOM_N=5000`: 20 PASS, 0 FAIL, 0 FLAKY | same run, `regression_summary.txt` |
| Tests | 28/28 TCs pass in 20/20 seeds | same run, `test_report.txt` |
| History | 3 runs, all PASS: baseline, after Phase 3 repairs 4–5 (uncommitted), run of record on `2deaa9f` (20 seed logs byte-identical to the previous run) | `../phase 6/history.csv`, `regression_report.md` |
| Release run (seeds 1–20 + seed 99 at `RANDOM_N=100000`) | **not run yet** | — |
| Defects | none found, none open | `../phase 5/defects.md` |

## 4. Final coverage results (run of record on `2deaa9f`)

| Goal | Result | Evidence |
|---|---|---|
| G1 functional: 44 bins in every seed | met: 44/44 in 20/20 seeds | `../phase 7/results/2026-10-24T201629Z_2deaa9f_full/coverage_merged.txt` |
| G2 tests: 28/28, none partial | met | same folder, `requirement_summary.txt` |
| G3 requirements: FR, IF, OP, D | FR 13/13, IF 16/16, OP 14/14, D 14/18; **4 D-IDs wait on proposed exclusions** | same folder |
| G4 code: RTL points | met: 35/35; **3 unmeasured `$error` lines wait on proposed exclusions** (the 4th is covered by TC-027) | `../phase 7/results/code_2026-10-24T201627Z_2deaa9f/summary.txt` |

Full analysis: `../phase 7/coverage_report.md`.

## 5. Requirements traceability

`../phase 7/results/2026-10-24T201629Z_2deaa9f_full/requirement_coverage.csv` links every Phase 1 ID (13 FR, 16 IF, 14 OP, 18 D, 28 TC) to the RTL that implements it (owner file and `// @ID` lines), the TCs that check it and each TC's result in the 20-seed run. Sources: `ALU_Verification_Requirements.csv` (TC → FR), `../phase 3/test_map.csv` (OP/D/IF → TC), `../phase 2/02_requirements/requirements_map.csv` and the RTL tags.

## 6. Waivers and exclusions

None approved. Seven exclusions are **proposed** and wait for a reviewer (`../phase 7/exclusions.md`): D-011, D-013, D-014, D-016, RTL-1, RTL-2, RTL-3.

## 7. Checklist (from `signoff_check.txt`)

| # | Item | State |
|---|---|---|
| 1 | spec final, decisions approved, Phase 1 open questions | spec 1.2 PASS; 18/18 decisions PASS; Phase 1 table PASS; **Phase 2 Q1, Q3, Q5, Q6 and Phase 3 #2, #3 open (FAIL)** |
| 2 | RTL tag on origin, lint, smoke, DV-1/DV-2 | tag PASS; lint and smoke PASS; **DV-2 not accepted (Q3) (FAIL)** |
| 3 | self-test, regression, defects | PASS |
| 4 | release regression on the signoff commit | **not run (FAIL)**; work committed (`c544fef`, `2deaa9f`), `full` run of record PASS |
| 5 | coverage goals and exclusions | G1, G2, G4 points met on committed code; **7 exclusions pending (FAIL)**; **coverage of a release run not yet possible (FAIL)** |
| 6 | AGENTS.md known issues | MANUAL: issue 3 closed (Phase 3 repair 5, `c544fef`); issues 1, 2, 4 open (`open_issues.md`); issue 5 is not blocking (OI-9) |

## 8. Approvals

| Role | Name | Date | Decision |
|---|---|---|---|
| Phase 1 owner (spec) | | | |
| Verification reviewer | | | |
| Project approver | | | |

Signoff tag `alu-signoff-v1`: **not created**. It is created and pushed only after the status above is SIGNED OFF and the approvers have signed.
