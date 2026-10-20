# Phase 1 revision 3: decisions approved

`spec_version` 1.1-proposed → **1.2** (2026-10-20). Approved by Adam.

## What changed

| # | Change | Files | Answers |
|---|---|---|---|
| 1 | D-001..D-018 approved as written: Status "Approved", Approved by "Adam", Date 2026-10-20. D-004 was "Resolved (language rule)" and is now approved like the others. | `ALU_Design_Decisions.csv` | Phase 2 Q4, Phase 3 #1 |
| 2 | Q-001..Q-018 Status "Proposed" → "Resolved" (Q-004 stays "Resolved (language rule)"). | `ALU_Open_Questions.csv` | — |
| 3 | D-014: the CPU class file is `CPU.svh`, not `cpu.svh` (file name = class name, so Verilator `-Wall` gives no `DECLFILENAME`). This accepts Phase 2 deviation DV-1. | `ALU_Design_Decisions.csv`, `ALU_Open_Questions.csv` (Q-014 answer), `alu_spec.json` (`package.includes_in_order`, class `CPU` → `file`), `ALU_Architecture_Corrected.svg` | Phase 2 Q2, AGENTS.md known issue 1 |
| 4 | Operation table: "(proposed, D-…)" → "(D-…)" now that the decisions are approved. Text otherwise unchanged. | `ALU_Operation_Behavior_Table.csv` | — |

## What did not change

- No operation semantics changed, so the golden vectors are not regenerated (`ALU_Golden_Vectors.csv`, sha256 unchanged).
- The RTL already used `CPU.svh` and all the approved behaviour, so Phase 2 needs no change and keeps tag `phase2-rtl-v1`. The Phase 4 build and Phase 5 regression (commit `5cc1c8b`) still apply.
- Still open: Phase 2 Q1 (IF IDs for `get_carry`/`set_carry`), Q3 (`virtual initialize()`, DV-2), Q5 (FR priorities), Q6 (coding rules); Phase 3 #2 (TC acceptance wording), #3 (GV-nn ID column); traceability evidence check against the PDF.
- `ALU_Architecture_Corrected.png` still shows `cpu.svh`. Regenerate it from the `.svg` when a renderer is available (for example `rsvg-convert -o ALU_Architecture_Corrected.png ALU_Architecture_Corrected.svg` after `sudo apt install librsvg2-bin`).
