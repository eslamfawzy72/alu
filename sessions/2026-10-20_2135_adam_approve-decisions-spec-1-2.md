# Approve decisions (spec 1.2) and propagate

| Field | Value |
|---|---|
| When | 2026-10-20 ~21:35–21:50 +03:00 |
| Who | Adam, with Claude Code in VS Code |
| Branch | `phase-4-5` |
| Git | `dda7f9b`..HEAD; commits: `c3ad293` Phase 3 test map (from the earlier test-map session), `6d7701a` Phase 1 revision 3, plus the follow-up commit with this entry; tags: none |
| Phases | 1, 2, 3, 4, 5 |
| Keywords | approval, D-001..D-018, spec 1.2, REVISION_3, D-014, CPU.svh, DV-1, known issues |

## Asked
Commit the pending Phase 3 test-map work and update the stale "never compiled" status; skip the
optional second simulator; settle DV-1 as `CPU.svh`; approve the design decisions.

## Done
- Test-map work committed unchanged as `c3ad293` (its own session log is
  `2026-10-20_2100_adam_phase3-test-map.md`).
- Phase 1 revision 3 (`6d7701a`): D-001..D-018 Approved by Adam, 2026-10-20; Q-001..Q-018
  Resolved; D-014, `alu_spec.json` and the SVG say `CPU.svh`; `spec_version` 1.2;
  `REVISION_3.md`. Golden vectors unchanged (no semantics changed).
- Answers recorded: Phase 2 Q2 and Q4, Phase 3 #1. DV-1 marked accepted in the Phase 2 design
  plan and requirements map; Phase 3 plan, test map, README; Phase 4 report and Phase 5 README
  no longer say "provisional" or "DV-1 open".
- AGENTS.md: phase table, rule 8, tools (WSL, LF, temp build folders), Phase 4/5 commands,
  repo map, recent changes, known issues, phase sections.

## Decisions
- D-001..D-018 approved as written by Adam; D-014 uses `CPU.svh` (file name = class name).
- Second simulator (Questa/VCS) skipped (Adam).
- No regression rerun: RTL, test program and golden vectors are unchanged, so the `5cc1c8b`
  results stand for spec 1.2.

## Not done / follow-ups
- `phase 1/ALU_Architecture_Corrected.png` still shows `cpu.svh`: needs `librsvg2-bin` (sudo)
  to re-render from the SVG.
- Still open for Phase 1: Phase 2 Q1, Q3 (DV-2), Q5, Q6; Phase 3 #2, #3.
- Branch `phase-4-5` not pushed or merged.

## Notes for later
none
