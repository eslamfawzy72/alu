# Phase 1 review and Phase 2 inputs — ALU class assignment

**Verdict:** the Phase 1 output is well organized and does not invent requirements, but it cannot feed Phase 2 yet. All 18 open questions are still "Open", so the RTL (class) agent would have to guess. This folder adds proposed answers for every question, a machine-readable spec, golden test vectors and a corrected diagram.

**Important:** this assignment is a **SystemVerilog class hierarchy** (simulation-only, object-oriented), not synthesizable RTL. Phase 2 therefore writes classes, and its tool gate is "compile and run in a simulator with class support" (Verilator 5 `--binary`, Questa or VCS on EDA Playground). A Yosys synthesis check does not apply.

## 1. What Phase 2 needs as input

| # | Input | File | Status |
|---|---|---|---|
| 1 | Approved answers to every open question | `ALU_Design_Decisions.csv` (D-001 to D-018) | **Proposed: needs team approval** |
| 2 | One machine-readable spec: enum, classes, properties, exact method signatures, op semantics, file list and include order | `alu_spec.json` | New |
| 3 | Exact expected values, including boundary cases | `ALU_Golden_Vectors.csv` (37 vectors, also inside `alu_spec.json`) | New, computed by a Python reference model |
| 4 | Interface table with real widths and signatures | `ALU_Interfaces_and_Signals.csv` | Updated |
| 5 | Operation table with defined semantics | `ALU_Operation_Behavior_Table.csv` | Updated |
| 6 | Verification requirements with pass criteria (for Phase 3) | `ALU_Verification_Requirements.csv` | Updated (12 blocked tests now have criteria) |
| 7 | A correct architecture picture | `ALU_Architecture_Corrected.png / .svg` | Replaces the old diagram |
| 8 | Tool gate definition | `alu_spec.json` → `tool_gate` | New |

Phase 2 should read `alu_spec.json` first; the CSVs are the human-readable view of the same content.

## 2. Problems found in the Phase 1 output

| # | Problem | Where | Fix in this folder |
|---|---|---|---|
| 1 | All 18 questions open, none with a proposed default. Phase 2 is blocked. | Open Questions | Proposed decision for each (D-001..D-018); Status column filled |
| 2 | **Q-004 is not really open.** The spec says `int`, which SystemVerilog defines as 32-bit, signed, 2-state. Width, signedness and wrap-around follow from that. Width columns said "Not specified". | Open Questions, Interfaces, CA-013 | Marked "Resolved (language rule)"; widths set to 32 |
| 3 | Diagram contradicts the spec: one generic "ALU Class" instead of base/logical/arithmetic; **"Comparison operations" are not in the assignment**; package named `alu_pkg.sv` instead of `cpu_pkg`; CPU drawn twice; Calc()/Reset() shown as ALU methods, but they belong to CPU. | High-Level ALU Architecture Diagram.png | `ALU_Architecture_Corrected.png` |
| 4 | Carry/borrow have nowhere to live: no property, no Calc parameter. ADDC and SUBB cannot be implemented. | FR-007, OP-005, OP-007 | D-005/D-006: a `bit carry` flag in arithmetic_alu, Calc signature unchanged |
| 5 | Nothing says *how* CPU picks an ALU and runs the operation. | FR-010 | D-012 + an added `virtual function void execute()` in base_alu, overridden by each derived class |
| 6 | No machine-readable spec: typed columns contain prose ("Not specified", "Parameter type not specified"), so an agent cannot parse them reliably. | All CSVs | `alu_spec.json` with typed fields and IDs |
| 7 | Traceability "Evidence" is the agent's paraphrase but marked "Directly extracted"; page numbers disagree (display: page 2 in FR-005, page 5 in TR-024); CA-017/CA-018 are process advice cited to page 6 of the assignment. | Traceability | **Not changed:** needs the original PDF to verify. Recheck evidence as exact quotes. |
| 8 | Priority is "Not specified" for every requirement. | Functional Requirements | Not changed; suggest Must for FR-001..FR-013 (all are explicit in the assignment) |
| 9 | `README.md` in the repo is empty. | repo root | Use this file |

## 3. What the team must do before Phase 2 starts

1. Review `ALU_Design_Decisions.csv`. For each row, keep or change the decision, then fill **Approved by** and **Date**. The ones that change behaviour most: D-003 (shift amount from B[4:0]), D-005/D-006 (carry flag), D-009 (invalid opcode).
2. If a decision changes, rerun the generator (or edit `alu_spec.json` and the golden vectors) so all files agree.
3. Check the Traceability evidence against the PDF (problem 7).

## 4. Files in this folder

| File | Changed? |
|---|---|
| `ALU_Design_Decisions.csv` | **New** |
| `alu_spec.json` | **New**: main input for Phase 2 |
| `ALU_Golden_Vectors.csv` | **New**: main input for Phase 3 |
| `ALU_Architecture_Corrected.png`, `.svg` | **New**: replaces the old diagram |
| `ALU_Open_Questions.csv` | Updated: Status and Answer filled |
| `ALU_Interfaces_and_Signals.csv` | Updated: widths, signatures, + IF-015 `carry`, IF-016 `execute` |
| `ALU_Operation_Behavior_Table.csv` | Updated: inputs and expected results defined |
| `ALU_Verification_Requirements.csv` | Updated: TC-004/005/009–013/017/019/021/027/028 now have pass criteria |
| `ALU_Functional_Requirements.csv`, `ALU_Constraints_and_Assumptions.csv`, `ALU_Traceability.csv`, `ALU_Project_Overview_Mapping.md` | Unchanged copies |
