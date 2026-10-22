# ALU class hierarchy and CPU integration

A SystemVerilog class model of an ALU (`base_alu`, `logical_alu`, `arithmetic_alu`) and a `CPU` that uses them, all in package `cpu_pkg`. The model is simulation-only and object-oriented, not synthesizable RTL. The project has eight phases. Phases 1 to 5 are done and phases 6 to 8 have not started.

| Phase | Name | Folder | Reads | Produces | State |
|---|---|---|---|---|---|
| 1 | Requirements & Architecture | `phase 1/` | the assignment specification | requirements, interfaces, operations, verification requirements, decisions, golden vectors, `alu_spec.json` | revision 3, `spec_version` 1.2, D-001..D-018 approved |
| 2 | RTL Design | `phase 2/` | `phase 1/` | the `cpu_pkg` class model (`04_rtl/`) and its handoff (`08_release/`) | lint clean, smoke 91/91, tag `phase2-rtl-v1` |
| 3 | Verification Development | `phase 3/` | `phase 1/` (expected behaviour), `phase 2/` (design) | verification plan, test map, test program (`tb/tb_cpu.sv`), regression results | regression PASS |
| 4 | Compilation & Elaboration | `phase 4/` | `phase 2/`, `phase 3/` | clean-clone build, lint log, `elab_report.md` | 0 lint messages, no waivers |
| 5 | Simulation & Debugging | `phase 5/` | `phase 3/`, `phase 4/` | seeded runs (`runs/`), `defects.md` | PASS at seeds 1 and 7, no defects |
| 6 | Regression Testing | `phase 6/` | `phase 2/`, `phase 3/`, `phase 4/` | `regress.sh` (quick/full/release), `results/`, `history.csv` | script written; first real run pending |
| 7 | Coverage Analysis & Closure | `phase 7/` (to create) | | | not started |
| 8 | Signoff | `phase 8/` (to create) | | | not started |

## Quick start

You need Verilator 5.020 or later and bash. On Windows, use WSL. Folder names contain a space (`phase 1/`), so quote paths in shell commands.

```bash
# Phase 2: lint and smoke test (from "phase 2/")
./05_build_checks/run_checks.sh      # expect "LINT: PASS (no messages)"
./07_smoke/run_smoke.sh              # expect "SMOKE: PASS" (SUMMARY pass=91 fail=0)

# Phase 3: checker self-test, then regression (from "phase 3/")
bash run.sh +CHECKER_SELFTEST        # must end with "checker self-test OK"
bash run.sh                          # summary starts with "Phase 3 regression: PASS"

# Phase 4: lint and build the design and test program (from the repo root)
bash "phase 4/build.sh"              # expect "LINT: PASS (no messages)" and "BUILD: PASS"

# Phase 5: self-test plus seeded runs (from the repo root)
bash "phase 5/simulate.sh"           # expect "Phase 5 simulation: PASS"

# Phase 6: multi-seed regression (from the repo root)
bash "phase 6/regress.sh" full       # expect "Phase 6 regression: PASS"
```

## How the phases work together

Phase 1 owns correctness. Every expected value, name and pass criterion comes from a Phase 1 file and is cited by its ID (`FR-`, `IF-`, `OP-`, `TC-`, `D-`, …). `phase 1/alu_spec.json` is the machine-readable source and the CSVs are the human-readable view.

Each phase reads the earlier phases' folders directly and never keeps a copy of their files. When a phase needs something an earlier phase has not provided, it writes the question to a `questions_for_phase1.md` in its own folder. Phase 1 answers by updating its files with the same IDs.

## Repository layout

```
phase 1/    requirements tables, golden vectors, alu_spec.json, architecture diagram, revision notes
phase 2/    01_spec_check -> ... -> 04_rtl (the design) -> ... -> 08_release (handoff)
phase 3/    verification_plan.md, test_map.csv, tb/tb_cpu.sv, run.sh, results/
phase 4/    build.sh, build and lint logs, elab_report.md
phase 5/    simulate.sh, runs/, defects.md
sessions/   shared logs of working sessions
AGENTS.md   ground rules, tools, known issues and plans for phases 6 to 8
```

## More documentation

- Each phase folder's `README.md` covers that phase's inputs, steps and commands.
- [AGENTS.md](AGENTS.md) has the ground rules for all phases, the tool setup, known issues, recent changes and the plans for phases 6 to 8.
- [sessions/README.md](sessions/README.md) explains how session logs are written.
