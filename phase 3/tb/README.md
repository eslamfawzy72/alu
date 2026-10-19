# SystemVerilog verification environment

Components: `alu_tb_pkg.sv` (transaction, oracle, scoreboard, coverage), `alu_driver.sv`, `alu_monitor.sv`, `alu_dut_adapter.sv` (binding contract), and `alu_test.sv` (directed, randomized and API tests). No ALU implementation is included.

The 14 opcode stimulus streams, plus two invalid codes, are generated in both connected runs and `+PLAN_ONLY`. By default only AND/OR/XOR have Phase 1 candidate bitwise comparison oracles; all other operation samples are BLOCKED. The independent oracle is never derived from DUT internals.

**Integration:** implement a subclass of `alu_dut_adapter` in a separate file, instantiate Phase 2 `CPU` there, override `calculate`, `connected`, and observable API methods, and add the file to the compile order after `alu_dut_adapter.sv` but before `alu_test.sv`. Define `P3_ADAPTER_CLASS` as the subclass type. Override an API method only when its signature and observation are available; return `P3_NOT_RUN` for non-observable or spec-blocked behavior, `P3_FAIL` for observed mismatch, `P3_PASS` for observed compliance. Never default to PASS.

**Enable new expected values:** update `alu_rules.svh` only after recording the approved Phase 1 decision. Shift/rotate width/count, subtraction direction, and carry/borrow flags MUST match the decision. The fixed-carry switches are deliberately disabled by default and are not sufficient for stateful carry-chain tests; those require an additional sequence oracle after Q-005/Q-006.

**Compile/run (Questa example):**
```sh
vlog -sv +incdir+tb tb/alu_tb_pkg.sv tb/alu_dut_adapter.sv tb/alu_driver.sv tb/alu_monitor.sv tb/alu_test.sv
vsim -c alu_test +PLAN_ONLY -do 'run -all; quit -f'
```
When Phase 2 is available: compile its package first, then the above files and your subclass before `alu_test.sv`; define `+define+P3_ADAPTER_CLASS=your_adapter_class` for compilation. Remove `+PLAN_ONLY` for an actual regression. Tool arguments vary by simulator.

`+RANDOM_N=300` and `+SEED=12345` control the random stream. A `PLAN_ONLY` execution is not evidence of functionality. No simulation evidence is bundled.
