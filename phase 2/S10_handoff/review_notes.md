# S10 review notes: ALU class model, plan v2

Reviewer: Claude, acting as the S10 reviewer (no LLM call). I read each spec ID beside the lines that implement it (`S9_trace/traceability.csv`, `S9_trace/rtl_trace.json`). Reviewer findings are flags for a human; the reviewer changes no code.

## Result

- 61 spec IDs: 59 implemented and tagged in their owning unit, 2 explained (FR-013 and D-015 belong to the Phase 3 test program), 0 missing.
- Gates: S6 round 2 is clean (Verilator -Wall, Verible, interface check). S8 smoke passed all 91 checks, with the 2 expected `$error` lines.
- I found no line that contradicts its requirement.

## Flags for a human (none blocks the baseline)

| # | Item | What I saw | Who decides |
|---|---|---|---|
| F1 | D-009 / E (invalid code) | `CPU.Calc` reports an invalid code with `$error`. In Verilator, `$error` also calls `$stop`, so a test run halts on the first invalid code unless it is started with `+verilator+error+limit+N` (S8 ran with this). Questa and VCS only count the error. | Phase 3: run negative tests with an error limit, or count `$error` as expected |
| F2 | D-005 / D-006 | `carry` is state. Its value carries from one `Calc` to the next, so ADDC and SUBB results depend on the previous arithmetic call. This follows D-005, but tests must set it (`set_carry`) or order the calls on purpose. | Phase 3 test writers |
| F3 | FR-001 | `base_alu` is a normal class, so it can be constructed. Its `execute()` reports `$error`. A `virtual class` would forbid construction, but D-010 and the test plan display a base object, so I left it as it is. | Design lead: confirm |
| F4 | D-014 | The file is `CPU.svh`, not `cpu.svh` as D-014 says. Plan v2 changed it after S6 round 1 (Verilator DECLFILENAME), and the S4 v2 review approved the change. | Phase 1: amend the wording of D-014 |
| F5 | IF-007 | `initialize()` is `virtual` (the spec lists `function void initialize()`), so `CPU.Reset()` also clears `carry`. The call interface is the same. | Design lead: confirm (accepted in the S4 review) |

## Open items carried into the handoff

1. D-001 to D-018 (except D-004) are still "Proposed" in Phase 1. This run used them as written, with provisional approval. The team must approve them, or this baseline must be redone.
2. The spec baseline (version 1.1-proposed) has no approver or Phase 1 commit (IN-10).
3. All 13 requirements have priority "Not specified" (IN-01).
4. Phase 1 sent no editable architecture file (IN-08). Structure was read from `alu_spec.json`.
5. Both design reviews (plan v1 and v2) are recorded as provisional and need a design lead's name.
