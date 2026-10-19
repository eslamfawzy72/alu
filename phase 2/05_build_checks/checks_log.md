# Build checks log

One row per run of `run_checks.sh`. Tool: Verilator 5.020, `--lint-only -Wall -f files.f --top-module cpu_pkg`.

| Run | Date | Files changed | Lint result | Messages | Next |
|---|---|---|---|---|---|
| 1 | 2026-10-19 | all 5 (first version, written from plan v1) | PASS | 0 | smoke (08) |

Why it passed first time: the two known lint traps were handled in the plan, before coding.
- `cpu.svh` vs class `CPU` (DECLFILENAME) → file named `CPU.svh` (DV-1).
- width warnings → every mixed-width expression has an explicit cast or size (`int'(...)`, `{27'b0, operand_B[4:0]}`, 33-bit `logic [32:0]` operands).

Interface check (by hand, against design_plan.md section 2): every planned property and method exists with the planned type? **yes**.
Checked: base_alu 4 properties + 7 methods; logical_alu 2 overrides; arithmetic_alu `carry` + 6 methods; CPU 2 handles + 3 methods.
