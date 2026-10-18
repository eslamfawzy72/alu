# Testbench

`alu_tb_pkg.sv`: transaction, source-based oracle, scoreboard, per-op coverage counters. `alu_test.sv`: 42 planned operation scenarios, 42 extra edge scenarios, 2 invalid-code probes, and random stimulation of all 14 opcodes. `alu_dut_adapter.sv`: the only Phase 2 integration point (intentionally fails until connected).

The test runner **does not mark undefined behavior as verified**. For OP codes 0–6, 10–13 and invalid codes 14–15, the scenario is recorded BLOCKED unless an approved Phase 1 update defines a reference result. When the requirement is resolved, implement its oracle case and add its Phase 1 citation; don't just enable a test without an independent expected result.

Current executable comparisons: bitwise AND (`7`), OR (`8`), XOR (`9`). No actual DUT has been tested. See `integration_checks.md` for source/API tests.

Run, after connecting Phase 2 and compiling the sources with a class-capable SystemVerilog simulator: `alu_test +RANDOM_N=300`. Expected `PASS` applies only to enabled checks. Record evidence in `../results/verification_results.csv`.
