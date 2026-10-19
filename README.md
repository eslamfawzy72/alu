# ALU class hierarchy and CPU integration

A SystemVerilog class model of an ALU (`base_alu`, `logical_alu`, `arithmetic_alu`) and a `CPU` that uses them, built in three phases.

| Folder | Phase | Reads | Produces |
|---|---|---|---|
| `phase 1/` | Requirements | the assignment specification | requirements, interfaces, operations, verification requirements, decisions, golden vectors, `alu_spec.json` |
| `phase 2/` | Design | `phase 1/` | the `cpu_pkg` class model (`S5_rtl/`) and its handoff (`S10_handoff/`) |
| `phase 3/` | Verification | `phase 1/` (expected behaviour), `phase 2/` (design) | verification plan, test program, regression results |

Each phase reads the earlier phases' folders directly and never keeps a copy of their files. When a phase needs something an earlier phase has not provided, it writes the question to a `questions_for_phase1.md` in its own folder. Phase 1 answers by updating its files with the same IDs.

Each folder's `README.md` describes how to run that phase.
