# Testbench self-test (mock only)

`mock_bitwise_adapter.sv` is isolated test equipment, **not the ALU/CPU delivered by Phase 2**.
It implements only the three operations enabled by the default oracle.

With Questa, from `phase 3/`, compile:

```sh
vlog -sv +incdir+tb +define+P3_ADAPTER_CLASS=mock_bitwise_adapter \
 tb/alu_tb_pkg.sv tb/alu_dut_adapter.sv tb/alu_driver.sv tb/alu_monitor.sv \
 tb/selftest/mock_bitwise_adapter.sv tb/alu_test.sv
vsim -c alu_test +RANDOM_N=300 -do 'run -all; quit -f'
```

Then run again with `+INJECT_AND_BUG`; the run **must fail** after the first AND comparison. The clean mock run should report passing comparisons for enabled bitwise operations and BLOCKED checks for the other operations. This tests checker wiring only; it does not verify Phase 2 and has **not been simulated in this environment**.
