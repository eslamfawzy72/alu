# Design review request: plan v2

Spec 1.1-proposed, mode class_model. Automatic checks: **pass** (61 spec IDs: 59 owned, 2 explained).
Re-plan requested by S7: Verilator DECLFILENAME: file cpu.svh does not match class CPU; D-014 fixes the file name, so the plan decides.


## Units

| Unit | Kind | File | Extends | Owns |
|---|---|---|---|---|
| cpu_pkg | package | cpu_pkg.sv |  | FR-011, FR-012, IF-013, IF-014, D-001, D-013, D-014 |
| base_alu | class | base_alu.svh |  | FR-001, FR-002, FR-003, FR-004, FR-005, IF-001, IF-002, IF-003, IF-004, IF-005, IF-006, IF-007, IF-008, IF-016, D-007, D-010, D-011 |
| logical_alu | class | logical_alu.svh | base_alu | FR-006, OP-008, OP-009, OP-010, OP-011, OP-012, OP-013, OP-014, D-003, D-004 |
| arithmetic_alu | class | arithmetic_alu.svh | base_alu | FR-007, OP-001, OP-002, OP-003, OP-004, OP-005, OP-006, OP-007, IF-015, D-005, D-006, D-016, D-017 |
| CPU | class | CPU.svh |  | FR-008, FR-009, FR-010, IF-009, IF-010, IF-011, IF-012, D-002, D-008, D-009, D-012, D-018 |

## Please decide

- **Added element** `get_name()` in base_alu (overridden in logical_alu, arithmetic_alu): display() must print the real class name (D-010); a virtual name method gives that without a string property. Approve or reject.
- **Warning**: IF-007 initialize: plan adds 'virtual' (virtual function void initialize()); the call interface is unchanged
- **Deviation from D-014**: spec says `includes ... cpu.svh`, plan does `includes CPU.svh`. Verilator -Wall (DECLFILENAME) requires file name = class name; the class name CPU is fixed by FR-008, so the file follows it. Class name and include order unchanged.
- **Not in RTL** FR-013: the test program is a Phase 3 deliverable; the S8 smoke test is only a build gate
- **Not in RTL** D-015: defines the content of the test program (FR-013), Phase 3

Write the decision into `plan_v2_review.json` (template next to this file).
