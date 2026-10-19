# Questions for Phase 1

From the Phase 3 readiness check against Phase 1 revision 2 (`alu_spec.json` spec_version 1.1-proposed). Nothing here blocks testing. Item 1 blocks sign-off. Please answer by updating the Phase 1 files and keeping the same IDs.

## Conditions (block sign-off)

1. **D-001 to D-003, D-005 to D-018** (`ALU_Design_Decisions.csv`): every decision is "Proposed", with "Approved by" and "Date" empty. Phase 3 tests against them as written, so its results stay provisional. Please record the approver and date for each decision, or send the changed decision.

## Requests (clean-up, no effect on the tests)

2. **TC-001, TC-003, TC-006 to TC-008, TC-014 to TC-016, TC-018, TC-022 to TC-025** (`ALU_Verification_Requirements.csv`): the "Acceptance criteria" still say "proposed", "confirm operand mapping", "enum details unresolved" or "not specified". D-001, D-002, D-004, D-012 and D-014 now settle these. Phase 3 uses those decisions and the golden vectors as the criteria. Please update the wording, and the "Derivation status" of the TCs that still say "blocked by missing specification".
3. **`ALU_Golden_Vectors.csv`:** please add a stable ID column (GV-01 to GV-37) so tests and results can cite a vector even if rows are added or reordered. Phase 3 now cites them by "Vector #" as GV-01 to GV-37.
