# Phase 4: Compilation & Elaboration

Phase 4 builds the Phase 2 DUT and the Phase 3 test program into one simulation binary. It proves that the two phases fit together before Phase 5 runs anything.

**Rule:** Phase 4 fixes nothing itself. A testbench error is fixed in Phase 3 and logged in `../phase 3/repair_log.md`. A DUT error is fixed in Phase 2, logged in `../phase 2/06_repairs/repair_log.md` and released under a new tag (`phase2-rtl-v2`, …). A warning is fixed at its source or waived in `waivers.vlt` with a reason in `elab_report.md`.

## Files

| File | Content |
|---|---|
| `build.sh` | lints DUT + test program with `-Wall`, then builds `build/obj/tb_cpu` with warnings fatal |
| `build_info.txt` | written by `build.sh`: date, commit, Verilator version, host, top, sha256 of every input, elaborated classes |
| `lint.log`, `build.log` | written by `build.sh` |
| `elab_report.md` | tool, top, files, include order, every warning and its disposition, tool-gate checks, result |
| `waivers.vlt` | Verilator waivers, one per warning waived in `elab_report.md` (created only if needed) |
| `build/` | copies and generated files; ignored by git |

## Inputs

Read from the other phase folders as they are.

| From | File | Used for |
|---|---|---|
| Phase 1 | `../phase 1/alu_spec.json` → `package.includes_in_order`, `tool_gate` | include order to confirm; checks to tick |
| Phase 2 | `../phase 2/08_release/phase2_handoff.md` | tag, filelist `04_rtl/files.f`, compile line |
| Phase 2 | `../phase 2/04_rtl/` | the DUT |
| Phase 3 | `../phase 3/tb/tb_cpu.sv` | the test program (top `tb_cpu`) |

## Steps

Run in Ubuntu (WSL on Windows) with Verilator 5.020 or later. The repo checks out every text file with LF (`.gitattributes`), so the scripts also run from `/mnt/c/...`.

1. `bash build.sh`
2. For each error: find the owner (Phase 2 or Phase 3), fix it there, log it, rerun.
3. For each warning in `lint.log`: fix it at its source, or add a waiver to `waivers.vlt` and a row to `elab_report.md` section 4 with the reason. Never waive a warning in DUT code without Phase 2 agreeing.
4. Fill in `elab_report.md` from `build_info.txt` and the logs.
5. Clean-checkout check: `git clone <repo> /tmp/alu && bash "/tmp/alu/phase 4/build.sh"` must pass.
6. Commit `build_info.txt`, `lint.log`, `build.log`, `elab_report.md` and `waivers.vlt` (if any).

## Exit criteria

- zero errors;
- every warning fixed or waived with a reason;
- the binary builds from a clean checkout with one command (`bash build.sh`).

## Redoing Phase 4 after a change

Rerun `build.sh` whenever `../phase 2/04_rtl/` or `../phase 3/tb/tb_cpu.sv` changes. Then update `elab_report.md` and go to Phase 5.
