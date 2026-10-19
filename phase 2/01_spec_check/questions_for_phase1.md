# Questions for Phase 1

None of these block Phase 2; it continues with the stated assumption. Please answer by updating your files (same IDs) and bumping `spec_version`.

| # | ID / file | Question | Phase 2 assumes until answered | Answer (Phase 1 fills) |
|---|---|---|---|---|
| Q1 | `ALU_Interfaces_and_Signals.csv`, D-016 | `get_carry()` and `set_carry()` are in `alu_spec.json` but have no IF ID. Please add them (e.g. IF-017 `function bit get_carry()`, IF-018 `function void set_carry(bit c)`). | traced to D-016 and D-005 | |
| Q2 | D-014 | D-014 names the file `cpu.svh`, but the class is `CPU` and Verilator `-Wall` requires the file name to equal the class name. Can D-014 say `CPU.svh`? | file is `CPU.svh` (deviation DV-1) | |
| Q3 | IF-007 | `arithmetic_alu` overrides `initialize()` (to clear carry). Can IF-007 read `virtual function void initialize()`? | declared `virtual` (deviation DV-2) | |
| Q4 | `ALU_Design_Decisions.csv` | D-001..D-018 have no approver or date. Please approve each (or change it) and fill both columns. | all used as written | |
| Q5 | `ALU_Functional_Requirements.csv` | Priority is "Not specified" for all 13. Are they all Must? | all Must | |
| Q6 | (new) | No coding rules were given. Is SystemVerilog-2017, one class per file, file name = class name acceptable? | as stated | |
