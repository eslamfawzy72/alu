# DUT integration and structural checks

The simulation-facing adapter is intentionally disconnected until the Phase 2 package is delivered. Do not record blocked scenarios as passed. Complete these checks against delivered source code; record evidence in `results/verification_results.csv`.

| Check | Phase 1 reference | How to check | Status now |
|---|---|---|---|
| `base_alu` has int `operand_A`, `operand_B`, `alu_result`, and enum `alu_op` | FR-001 | Compile/type review | NOT RUN |
| `load_operand_A` stores a value | FR-002 | API/property readback after call | NOT RUN |
| `load_operand_B` stores a value | FR-003 | API/property readback after call | NOT RUN |
| `initialize` post-state | FR-004 / Q-007 | State check to approved reset policy | BLOCKED |
| `display` output | FR-005 / Q-010 | Output capture/review against agreed format | BLOCKED |
| Derived logical/arithmetic classes extend `base_alu` | FR-006, FR-007 | Compile/type review | NOT RUN |
| CPU holds `l_alu` and `a_alu` objects | FR-008 | Inspect members and construction | NOT RUN |
| `Reset` behavior | FR-009 / Q-007 | Repeated reset / post-state | BLOCKED |
| `Calc` accepts two ints and enum, produces int | FR-010 / Q-001 | Call/type check via adapter | NOT RUN |
| `cpu_pkg` contains required classes; separate source files | FR-011, FR-012 | Compile/package and file review | NOT RUN |
| Correct opcode dispatch | OP-001..OP-014 | Run scenarios / review routing | PARTIAL, no DUT |
| Unsupported opcodes | Q open | Negative tests after agreed policy | BLOCKED |

Integration: replace `alu_dut_adapter.calculate()` using actual Phase 2 package, then compile package first, followed by `alu_tb_pkg.sv`, `alu_dut_adapter.sv`, `alu_test.sv`. No replacement implementation belongs in Phase 3.

**Constraints:** No `uvm` dependency; the environment uses plain SystemVerilog classes. The simulator must support SystemVerilog classes and the selected DUT API. No compile or simulation run is claimed here.
