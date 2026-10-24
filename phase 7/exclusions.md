# Coverage exclusions

One row per gap that simulation can't close. An exclusion counts only when **Status** is `approved` and **Reviewer** and **Date** are filled in (`trace_requirements.py` and `../phase 8/signoff_check.py` read this table). Phase 7 proposes; a reviewer who did not write the row approves, rejects or asks for a test instead.

**None is approved yet.** Every row below is a proposal.

| ID | Item | Metric | Reason | Evidence | Proposed by | Reviewer | Date | Status |
|---|---|---|---|---|---|---|---|---|
| D-013 | "extern is not used; methods are defined inside each class" | G3 | a source-style rule: a running program can't see whether a method was declared `extern` | `grep -n extern "phase 2/04_rtl/rtl/"*` finds only the `// @D-013` comment in `cpu_pkg.sv:25`; Phase 2 lint `-Wall` clean | Phase 7, 2026-10-24 | | | proposed |
| D-014 | include order and file names of `cpu_pkg` (the part TC-025 does not check) | G3 | file names and include order are compile-time facts, not simulation behaviour | Phase 4 `elab_report.md` section 3: all four includes match `alu_spec.json` `package.includes_in_order` (spec 1.2); `cpu_pkg.sv:26-29` | Phase 7, 2026-10-24 | | | proposed |
| D-016 | "no overflow flag" (the part TC-016 to TC-019 do not check) | G3 | an absent member can only be shown by a compile that is meant to fail, which the single-binary regression can't express | `grep -ni overflow "phase 2/04_rtl/rtl/"*` finds nothing; the only flag is `carry` (`arithmetic_alu.svh`, `get_carry()` at line 21) | Phase 7, 2026-10-24 | | | proposed |
| D-011 | exact signatures of `load_operand_A/B`, `initialize()`, `display()` (TC-002 to TC-005 only show that the calls compile) | G3 | a wrong return type would compile with a warning, not fail a check | `base_alu.svh:17, 21, 26, 38` declare exactly the D-011 signatures; Phase 4 lint `-Wall` of DUT + test program gives 0 messages (`elab_report.md` section 4) | Phase 7, 2026-10-24 | | | proposed |
| RTL-1 | `arithmetic_alu.svh:65` `default: $error(...)` | G4 | unreachable through the specified API: `CPU.Calc` sends only codes 4'b0000–4'b0110 to `a_alu` (D-012); Phase 1 specifies no behaviour for a direct call with another code, so a test would invent one | `CPU.svh:24-31`; Verilator gives `$error` branches no coverage point (`code_coverage.sh` summary, "Not measured") | Phase 7, 2026-10-24 | | | proposed |
| RTL-2 | `logical_alu.svh:26` `default: $error(...)` | G4 | as RTL-1: `CPU.Calc` sends only 4'b0111–4'b1101 to `l_alu` (D-012) | `CPU.svh:24-31`; as RTL-1 | Phase 7, 2026-10-24 | | | proposed |
| RTL-3 | `base_alu.svh:45` `execute()` `$error(...)` | G4 | `CPU` never holds a plain `base_alu`; `CPU.Calc` calls `execute()` only on `l_alu` or `a_alu` (IF-009, IF-010, D-018); Phase 1 specifies no behaviour for `base_alu.execute()` | `CPU.svh` members and `Calc`; as RTL-1 | Phase 7, 2026-10-24 | | | proposed |

Not an exclusion: `CPU.svh:28-30` (the invalid-code `$error` branch) has no Verilator coverage point either, but it is covered functionally by TC-027 (both codes return 0, leave the state unchanged, and print exactly one `%Error` each; `run.sh` log check). See `coverage_report.md`.
