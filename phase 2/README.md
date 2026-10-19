# Phase 2 — ALU RTL Design Pipeline

This directory contains the complete Phase 2 artifact set for the supplied ALU Phase 1 output.

## Pipeline
S1 Intake -> S2 Readiness -> S3 Microarchitecture Plan -> S4 Review -> S5 RTL -> S6 Static Gate -> S7 Repair -> S8 Smoke -> S9 Trace/Conformance -> S10 Handoff.

## Main deliverables
- `s1_intake/normalized_spec.json`
- `s2_readiness/readiness_report.json`
- `s3_planner/design_plan.json`
- `s4_review/approved_plan.json` and `s4_review/plan_slices/`
- `rtl/*.svh`, `rtl/cpu_pkg.sv`
- `tb/tb_alu.sv`
- `files.f`
- `s6_static_gate/gate_report.json`
- `s7_repair/repair_record.json`
- `s8_smoke/smoke_log.txt`
- `s9_trace/rtl_trace.json`, `design_graph.graphml`, `conformance_report.json`, `traceability.csv`
- `s10_handoff/phase2_handoff.json`

## Run with a simulator
If Verilator is installed:

```text
verilator --binary --timing -Wall -Irtl --top-module tb_alu -f files.f
```

The exact command may need adjustment for the installed tool version.

If Icarus is installed:

```text
iverilog -g2012 -s tb_alu -o simv -f files.f
vvp simv
```

## Note
The current execution environment used for this artifact generation did not have a SystemVerilog simulator/linter/parser installed, so S6 and S8 are explicitly marked environment-blocked/pending rather than falsely marked passed.
