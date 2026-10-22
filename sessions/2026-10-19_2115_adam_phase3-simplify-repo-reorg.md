# Phase 3 simplification and repo reorganization

| Field | Value |
|---|---|
| When | 2026-10-19 ~21:15–22:05 +03:00 (start approximate; Adam committed at 22:02 and 22:03) |
| Who | Adam, with Claude Code in VS Code |
| Branch | `main` |
| Git | `e8235f6`..`819d7f0`; commits: `2c04357` re-organize repo + delete duplicates, `819d7f0` Increase Phase 3 random coverage; tags: none |
| Phases | 1, 2, 3 |
| Keywords | duplicates, phase1_answered, phase1_original, phase 3 CSVs, tb_cpu, run.sh, questions_for_phase1, golden vectors, reference model, CHECKER_SELFTEST, RANDOM_N, python tools |

## Asked
1. Does Phase 3 duplicate CSVs that Phase 1 already produced? Organize the repo, remove duplicate folders, and make Phase 3 much simpler, with fewer CSVs. Phase 3 must ask Phase 1 for missing inputs instead of inventing them.
2. Follow-up: why are there Python files in the repo?

## Done
- **Diagnosis:** Phase 3 (`863ca28`) had 11 CSVs. It re-listed TC-001..TC-028 in 4 of them, copied Q-001..Q-018 into `open_questions.csv`, and used `traceability.csv` (86 rows) only to rename IDs. It ignored Phase 1's answers (D-001..D-018, 37 golden vectors, `alu_spec.json`), which were then in `phase 2/inputs/phase1_answered/`. As a result it invented semantics switches (`alu_rules.svh`, including a fixed carry-in that contradicts D-005), blocked every op except AND/OR/XOR, and claimed there was no DUT.
- **Duplicates removed (`2c04357`):** the empty root `planning/ results/ scripts/ tb/`; `phase 2/inputs/phase1_original/` (byte-identical to `phase 1/`); the 4 identical files in `phase1_answered/`; and the superseded rev-1 diagram `High-Level ALU Architecture Diagram.png`.
- **Phase 1 (`2c04357`):** `phase1_answered` moved to the top of `phase 1/` as revision 2. `README_phase1.md` became `README.md`, with a file table and an "Answering questions from later phases" section. `README_Phase1_Review.md` became `REVISION_2.md`. Revision 1 stays in git at `1463e78` (on origin).
- **Phase 2 (`2c04357`):** `run_all.sh` read `../phase 1`, and extracted revision 1 for run 1 with `git archive 1463e78`. README `inputs/` row updated.
- **Phase 3 rewritten (`2c04357`, `819d7f0`), 0 CSVs, five files:** `README.md` (7-step procedure with readiness checklist R1–R10), `verification_plan.md` (TC → test map citing IDs), `questions_for_phase1.md` (#1 approvals, #2 stale TC wording, #3 GV ID column), `tb/tb_cpu.sv`, `run.sh`.
- **`tb_cpu.sv`:** one task per TC. It reads `ALU_Golden_Vectors.csv` at run time, and TC-024 checks enum names against it. A reference model written from `alu_spec.json` must reproduce every vector before use (`$fatal` otherwise). The random test does not reset carry between calls, so carry chains are covered. There are 44 coverage bins, and `+CHECKER_SELFTEST` corrupts the first check. `run.sh` adds the log checks for TC-005 (`EXPECT-DISPLAY` substring) and TC-027 (exactly 2 `%Error` lines).
- Root `README.md` written: a three-phase table and the "read, don't copy / ask Phase 1" rule.
- **Python question:** Phase 3 had none left. All 10 `.py` files were Phase 2 `tools/` stage checks called by `run_all.sh`. The exception was `watch.py`, a dev helper that `run_all.sh` didn't call. Recommended keeping the tools; offered to delete or document `watch.py`, and no answer was given.

## Decisions
- Zero CSVs in Phase 3: the TC map lives in the plan, and per-TC results come from the program's summary. A later session added `test_map.csv` anyway (`c3ad293`).
- Golden vectors are read from Phase 1 at run time, never typed into the testbench, so a Phase 1 update needs no Phase 3 edit.
- Phase 3 decides how to test, Phase 1 decides what is correct. Stimulus, corner values and coverage bins are Phase 3's; expected values are not.
- Default `RANDOM_N` raised from 2000 to 5000 (`819d7f0`). At 2000, the SHR/ROR `B[4:0]=0` and ROL/ROR `B[4:0]=31` bins each had about a 0.6% chance per seed of staying empty.
- Did not add any text saying that phases will be run by agents (user instruction for that session). Existing "agent" wording in Phase 1/2 was left alone.

## Superseded since (check before relying on the above)
- `22b327d` replaced Phase 2 with the `01_spec_check` … `08_release` layout. `run_all.sh`, `tools/*.py` and `S5_rtl/` are gone; the repo now has no Python. The DUT is `phase 2/04_rtl/` and the handoff is `08_release/phase2_handoff.md`.
- `7b4014f` fixed the first compile of `tb_cpu.sv`: a variable named `before` (reserved word) plus 31 `-Wall` warnings. `run.sh` now builds in `mktemp -d`, because GNU Make can't handle the space in `phase 3`.
- `6d7701a` approved D-001..D-018 (spec 1.2), which answers question #1.

## Not done / follow-ups
- `questions_for_phase1.md` #2 (TC acceptance wording) and #3 (GV-nn ID column): waiting on Phase 1.
- TC-005 checks the `display()` text as a substring, so arithmetic_alu's `carry=` field is not checked (AGENTS.md known issue 3).

## Notes for later
- No simulator, Python or WSL distro was available on the Windows host during this session. `tb_cpu.sv` was written uncompiled. The model formulas and the CSV parsing were checked only by a PowerShell port against all 37 vectors (0 mismatches); a mutated port (wrong SUB order, wrong ROL direction) was caught.
- Adam committed partway through the session (`2c04357`), so that commit holds work in progress plus his own README/docx moves.
