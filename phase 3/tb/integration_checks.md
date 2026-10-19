# Phase 2 integration contract

1. Build Phase 2 `cpu_pkg` separately; **do not copy CPU logic into the verification environment**.
2. Confirm the actual `CPU.Calc`, `CPU.Reset`, `base_alu` loading method signatures and opcode enum from the approved Phase 1 interface. Phase 1 intentionally did not specify every signature.
3. Add a subclass `phase2_adapter extends alu_dut_adapter` in a separate file. It owns the actual `CPU` object, maps the opcode to the project's enum, calls `Calc`, and returns the actual result. This file is the **only** integration-specific code.
4. Implement `load_a` and `load_b` against accessible base-class properties (read back and compare). Implement `handles_exist` by checking real logical/arithmetic handles, or use static compile assertions; do not fabricate observations.
5. `initialize_check` and `reset_check` require approved postconditions (Phase 1 Q-007/Q-008). `display_check` requires an agreed display acceptance criterion (Q-010). `routing_check` requires observable routing/instrumentation; results alone cannot prove which child was used.
6. Enable optional oracles in `alu_rules.svh` only after closing relevant Phase 1 questions. Record the choice and source in `planning/decisions.csv`.
7. Compile against the actual class source files, run the regression, capture logs and status reports. A passing enabled subset is not verification sign-off.
8. Review `planning/requirement_execution_map.csv` and update execution evidence per TC.

**Important:** The example `clk/reset/a/b/result` module shown in a generic RTL diagram is not this assignment's class-based CPU interface. Do not add a clock or module DUT without an approved change.
