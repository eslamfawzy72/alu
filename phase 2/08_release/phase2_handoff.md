# Phase 2 handoff: ALU RTL

| Field | Value |
|---|---|
| Git tag | `phase2-rtl-v1` |
| Spec version used | 1.1-proposed (Phase 1 revision 2) |
| Plan version | 1 (`03_architecture/design_plan.md`) |
| Design kind | SystemVerilog class model, simulation only |
| Top / package | `cpu_pkg` |
| Build list | `04_rtl/files.f` (run from `04_rtl`) |
| Compile line | `verilator --binary -f files.f <testbench.sv> --top-module <tb>`; any simulator with SV class support |
| Files (lines) | cpu_pkg.sv (31), base_alu.svh (48), logical_alu.svh (30), arithmetic_alu.svh (69), CPU.svh (40) |
| Lint result | Verilator 5.020 `-Wall`: 0 messages |
| Smoke result | `SUMMARY pass=91 fail=0`; 2 expected `$error` lines. Since repair #2, `07_smoke/run_smoke.sh` checks both and exits 1 (`SMOKE: FAIL`) otherwise |
| Added elements | AE-1 `get_name()` |
| Deviations from spec | DV-1 file `CPU.svh` (D-014); DV-2 `virtual initialize()` (IF-007) |
| Open items | spec 1.2 (2026-10-20) approved D-001..D-018 and accepted DV-1 (Q2, Q4 answered); still open: Q1 (IF IDs for get_carry/set_carry), Q3 (DV-2, `virtual initialize()`), Q5, Q6 (`01_spec_check/questions_for_phase1.md`) |

Notes for Phase 3 (testing):
- F1: `$error` in Verilator also calls `$stop`: run invalid-code tests with `+verilator+error+limit+N` (Questa/VCS only count the error).
- F2: `carry` is state: its value carries from one `Calc` to the next, so set it with `set_carry()` before ADDC/SUBB, or order the calls on purpose.
- Each line that implements a spec ID ends with a `// @ID` comment, so you can find the code for any requirement with `grep -n "@OP-005" 04_rtl/rtl/*`.

Who uses what:
- Phase 3 (verification): `04_rtl/`, `02_requirements/requirements_map.csv`, `07_smoke/smoke_tb.sv` as a starting point
- Phase 4 (integration): `04_rtl/files.f` and the compile line
