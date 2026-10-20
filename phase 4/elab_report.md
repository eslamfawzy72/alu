# Phase 4 elaboration report

**Status: not run yet.** No simulator was available on the machine where Phase 4 was set up (2026-10-20). Fill in every "pending" from `build_info.txt`, `lint.log` and `build.log` after the first `bash build.sh`.

## 1. Build

| Field | Value |
|---|---|
| Date | pending |
| Commit | pending |
| Tool | pending (needs Verilator ≥ 5.020; Phase 2 used 5.020) |
| Host | pending |
| Top | `tb_cpu` (`program`, `../phase 3/tb/tb_cpu.sv`) |
| Package | `cpu_pkg` (`../phase 2/04_rtl/rtl/cpu_pkg.sv`) |
| DUT tag | `phase2-rtl-v1` (commit `22b327d`) |
| Spec version | `1.1-proposed` (`../phase 1/alu_spec.json`) |
| Command | `bash build.sh` (lint `--lint-only -Wall`, then `--binary -Wall`, warnings fatal) |

## 2. Files

sha256 from `build_info.txt`.

| File | sha256 |
|---|---|
| `rtl/cpu_pkg.sv` | pending |
| `rtl/base_alu.svh` | pending |
| `rtl/logical_alu.svh` | pending |
| `rtl/arithmetic_alu.svh` | pending |
| `rtl/CPU.svh` | pending |
| `files.f` | pending |
| `tb_cpu.sv` | pending |

## 3. Include order

`alu_spec.json` → `package.includes_in_order` against `cpu_pkg.sv`:

| # | Spec | `cpu_pkg.sv` | Match |
|---|---|---|---|
| 1 | `base_alu.svh` | `base_alu.svh` | yes |
| 2 | `logical_alu.svh` | `logical_alu.svh` | yes |
| 3 | `arithmetic_alu.svh` | `arithmetic_alu.svh` | yes |
| 4 | `cpu.svh` | `CPU.svh` | name differs: deviation DV-1, Phase 2 question Q2, still open (AGENTS.md known issue 1) |

Phase 4 builds `CPU.svh` as delivered. Renaming it is a Phase 1 decision (D-014), not a Phase 4 one.

## 4. Warnings and their disposition

| # | Message (file:line, rule, text) | Source | Disposition | Reason / fix reference |
|---|---|---|---|---|
| — | pending first run | — | — | — |

## 5. Elaborated classes

From `build_info.txt`: pending (expected `base_alu`, `logical_alu`, `arithmetic_alu`, `CPU`).

## 6. Tool gate (`alu_spec.json` → `tool_gate.checks`)

| Check | Result | Evidence |
|---|---|---|
| compiles with no errors | pending | `build.log` |
| lint warnings reviewed | pending | section 4 |
| all golden vectors pass | Phase 5 | `../phase 3/results/summary.txt` |
| each class in its own file (CA-001) | yes | section 2: four `.svh` files, one class each |
| names match IF-001..IF-014 | pending (compiles only if the test program's names resolve) | `build.log` |

## 7. Result

| Exit criterion | State |
|---|---|
| zero errors | pending |
| every warning fixed or waived | pending |
| builds from a clean checkout with one command | pending |

Results are provisional until Phase 1 approves D-001..D-018.
