# Phase 4 elaboration report

**Status: PASS.** Built from a clean clone of commit `5cc1c8b` with one command, `bash "phase 4/build.sh"`. Lint and build both give 0 messages.

## 1. Build

| Field | Value |
|---|---|
| Date | 2026-10-20 18:27 UTC |
| Commit | `5cc1c8b` (clean clone, no local changes) |
| Tool | Verilator 5.020 2024-01-01 rev (Debian 5.020-1), the same version as Phase 2 |
| Host | Ubuntu 24.04.5 LTS on WSL2 (Linux 6.18.54.1-microsoft-standard-WSL2 x86_64) |
| Top | `tb_cpu` (`program`, `../phase 3/tb/tb_cpu.sv`) |
| Package | `cpu_pkg` (`../phase 2/04_rtl/rtl/cpu_pkg.sv`) |
| DUT tag | `phase2-rtl-v1` (commit `22b327d`); RTL unchanged since |
| Spec version | built against `1.1-proposed`; still valid for `1.2` (decisions approved, D-014 file name only, no RTL or test change) |
| Command | `bash build.sh`: lint `--lint-only -Wall`, then `--binary -Wall` with warnings fatal |
| Evidence | `build_info.txt`, `lint.log`, `build.log` |

## 2. Files

| File | sha256 |
|---|---|
| `rtl/cpu_pkg.sv` | `fa0fc1fb54c042218cd913944c8d6f5688b2a3623b7c1195dfbead90b14d2365` |
| `rtl/base_alu.svh` | `69f898bf2326272e12ea0f4df164b1e313cf6d62fc98d36abaca44474e1ff88e` |
| `rtl/logical_alu.svh` | `8bb6c191c3087c5722298fe7c06a9d4b4237139ed459dd63999d3a12d481aae3` |
| `rtl/arithmetic_alu.svh` | `f73ad7d7fa56384219fad8249d53f7c0e6b5f6705a8bbafde5f0b4757e12d2a3` |
| `rtl/CPU.svh` | `1dc5112edb66ff5045f3831e379c9513837e0a4485e662eb9e0e723a8f5c75f5` |
| `files.f` | `c1b7cdabcb9aa6aa3ee9cf7a012e2b4cbbcd18982459eb49e8f7c8cdc87c2b44` |
| `tb_cpu.sv` | `7ddb6e749b80eedddcb32ff5a1466188502ed6f11246d5c5eac2ea930105f19a` |

## 3. Include order

`alu_spec.json` → `package.includes_in_order` against `cpu_pkg.sv`:

| # | Spec | `cpu_pkg.sv` | Match |
|---|---|---|---|
| 1 | `base_alu.svh` | `base_alu.svh` | yes |
| 2 | `logical_alu.svh` | `logical_alu.svh` | yes |
| 3 | `arithmetic_alu.svh` | `arithmetic_alu.svh` | yes |
| 4 | `CPU.svh` | `CPU.svh` | yes (spec 1.2) |

Spec 1.1-proposed listed `cpu.svh` (deviation DV-1). Phase 1 revision 3 (spec 1.2) changed D-014 to `CPU.svh`, so the order and every name now match.

## 4. Messages and their disposition

All were in the test program and were fixed at the source (Phase 3 `repair_log.md`). None is waived, so there is no `waivers.vlt`. The DUT gave no message.

| # | Message | Count | Source | Disposition | Reference |
|---|---|---|---|---|---|
| 1 | `%Error … syntax error, unexpected before` | 3 | `tb_cpu.sv` TC-027 | fixed: `before` is a reserved word, renamed `state_before` | Phase 3 repair 1 |
| 2 | `%Warning-WIDTHEXPAND` (1- and 4-bit values into `check(int, int)`, carry-in in 64-bit sums, `amt`, loop start) | 27 | `tb_cpu.sv` | fixed: `check_bit()`, explicit casts and widths | Phase 3 repair 2 |
| 3 | `%Warning-WIDTHTRUNC` (`if (cov.exists(key))`) | 1 | `tb_cpu.sv` | fixed: `!= 0` | Phase 3 repair 2 |
| 4 | `%Warning-UNUSEDSIGNAL` (`expected_carry(vector_t v)`; `e` in TC-024) | 2 | `tb_cpu.sv` | fixed: pass the 3 fields; walk the enum | Phase 3 repair 2 |
| 5 | `GNU Make cannot build in directories containing spaces` | 1 per script | `phase 2/07_smoke/run_smoke.sh`, `phase 3/run.sh`, `phase 4/build.sh` | fixed: build in a `mktemp -d` folder | Phase 2 repair 1, Phase 3 repair 3 |

Final result: `lint.log` = `LINT: PASS (no messages)`; `build.log` has no `%Warning` or `%Error`.

## 5. Elaborated classes

From `build_info.txt`: `cpu_pkg::base_alu`, `cpu_pkg::logical_alu`, `cpu_pkg::arithmetic_alu`, `cpu_pkg::CPU`.

## 6. Tool gate (`alu_spec.json` → `tool_gate.checks`)

| Check | Result | Evidence |
|---|---|---|
| compiles with no errors | yes | `build.log` |
| lint warnings reviewed | yes, 0 left | section 4, `lint.log` |
| all golden vectors pass | yes (37/37, result and carry) | `../phase 3/results/summary.txt` (Phase 5) |
| each class in its own file (CA-001) | yes | section 2: four `.svh` files, one class each |
| names match IF-001..IF-014 | yes: the test program calls every spec name and compiles | `build.log` |

## 7. Not done

- Second simulator (Questa or VCS): optional in AGENTS.md, not run. It would check `$error` semantics (F1) and `program` handling on another tool.

## 8. Result

| Exit criterion | State |
|---|---|
| zero errors | yes |
| every warning fixed or waived | yes, all 31 fixed, none waived |
| builds from a clean checkout with one command | yes: clean clone of `5cc1c8b`, `bash "phase 4/build.sh"` |

Phase 1 approved D-001..D-018 on 2026-10-20 (spec 1.2), so this result is no longer provisional.
