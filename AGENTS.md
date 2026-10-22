# AGENTS.md

Guidance for AI agents and engineers working in this repository. Read this first, then the
`README.md` of the phase folder you are working in.

## What this repo is

A SystemVerilog **class model** of an ALU (`base_alu`, `logical_alu`, `arithmetic_alu`) and a
`CPU` class that uses them, all in package `cpu_pkg`. It is simulation-only and object-oriented,
not synthesizable RTL: there is no synthesis, timing or gate-level step. The project is built
in eight phases. Phases 1 to 5 have folders in the repo. Phases 6 to 8 are upcoming.

| Phase | Name | Folder | State |
|---|---|---|---|
| 1 | Requirements & Architecture | `phase 1/` | revision 3, `spec_version` 1.2: D-001..D-018 approved (Adam, 2026-10-20) |
| 2 | RTL Design | `phase 2/` | RTL written, lint clean, smoke 91/91 (`phase2-rtl-v1`) |
| 3 | Verification Development | `phase 3/` | plan, test map and testbench; lint `-Wall` clean; regression PASS |
| 4 | Compilation & Elaboration | `phase 4/` | done: clean-clone build, 0 lint messages, no waivers |
| 5 | Simulation & Debugging | `phase 5/` | done: self-test OK, PASS at seeds 1 and 7, no defects |
| 6 | Regression Testing | `phase 6/` | `regress.sh` written from `spec.md` and checked with a stub; **first real run pending** (needs Verilator) |
| 7 | Coverage Analysis & Closure | `phase 7/` (to create) | not started |
| 8 | Signoff | `phase 8/` (to create) | not started |

Folder names contain a space (`phase 1/`), so always quote paths in shell commands.

## Ground rules (all phases)

1. **Phase 1 owns correctness.** Every expected value, name, type, signature and pass criterion
   comes from a Phase 1 file and is cited by its ID (`FR-`, `IF-`, `OP-`, `CA-`, `TC-`, `Q-`,
   `D-`, `TR-`, or golden vector `GV-nn`). `phase 1/alu_spec.json` is the machine-readable
   source; the CSVs are the human-readable view of the same content. Read the JSON first.
2. **Never invent behaviour.** If the spec and the approved decisions do not cover something,
   write a numbered question to `questions_for_phase1.md` in your own phase folder. Use the
   existing table format (see `phase 2/01_spec_check/questions_for_phase1.md`). Don't fill the
   gap yourself.
3. **Read, don't copy.** A phase reads earlier phases' folders in place. It keeps no copies of
   their files.
4. **Never edit an expected value to make a test pass.** A failing check is either a DUT bug
   (report to Phase 2), a reference-model bug (fix in Phase 3), or a spec gap (ask Phase 1).
5. **Phase 1 answers by editing in place.** Keep existing IDs, add new IDs for new items, and
   bump `spec_version` in `alu_spec.json`. Regenerate the golden vectors whenever a decision
   changes semantics.
6. **Trace code to requirements.** Each RTL line that implements a spec ID ends with
   `// @ID` (for example `grep -n "@OP-005" "phase 2/04_rtl/rtl/"*`). Each testbench check is
   counted under a `TC-` and cites the `D-`/`OP-` ID it uses. Keep doing both.
7. **Don't rename spec names.** Class, method, property and enum names come from
   `alu_spec.json` and `ALU_Interfaces_and_Signals.csv`. Record every addition in
   `phase 2/03_architecture/design_plan.md` → "Added elements" and every deviation as a `DV-n`.
8. **Results depend on approved decisions.** D-001..D-018 were approved on 2026-10-20
   (spec 1.2). A result that depends on a new or changed decision is provisional until Phase 1
   records an approver and date for it.

## Tools and environment

- **Simulator:** Verilator 5.020 or later (`--binary`, `--lint-only -Wall`). The spec's
  `tool_gate` also accepts Questa or VCS (for example on EDA Playground).
- **Shell:** the scripts are bash and run on Ubuntu. On Windows, use WSL (Adam's host has
  Ubuntu 24.04 with Verilator 5.020). `.gitattributes` checks out every text file with LF, so
  the scripts also run from `/mnt/c/...`.
- **Paths with spaces:** GNU Make cannot build in a directory whose path contains a space
  (`phase N/`), so every build script compiles in a `mktemp -d` folder. Keep it that way.
- **Optional:** `verible-verilog-lint` (style lint, used by `run_checks.sh` when present).
- **Generated and ignored files:** `build/`, `obj_dir/`, `*.docx` (root `.gitignore`).
  `phase 3/results/` is written by `run.sh` and should be committed after a real run.

## Key commands

```bash
# Phase 2: lint and smoke test (from "phase 2/")
./05_build_checks/run_checks.sh      # expect "LINT: PASS (no messages)"
./07_smoke/run_smoke.sh              # expect "SMOKE: PASS" (SUMMARY pass=91 fail=0, 2 expected %Error lines); exit 1 otherwise

# Phase 3: checker self-test, then regression (from "phase 3/")
bash run.sh +CHECKER_SELFTEST        # must end with "checker self-test OK"
bash run.sh                          # must end with "Phase 3 regression: PASS"
bash run.sh +SEED=7 +RANDOM_N=10000  # different seed / more random calls (keep RANDOM_N >= 3000)

# Phase 4: lint (-Wall) and build DUT + test program, warnings fatal
bash "phase 4/build.sh"              # expect "LINT: PASS (no messages)" and "BUILD: PASS"

# Phase 6: multi-seed regression with history (from the repo root); levels quick|full|release
bash "phase 6/regress.sh" full       # expect "Phase 6 regression: PASS"; skips if inputs unchanged (--force)

# Phase 5: self-test, seed 7, seed 1 twice; reproducibility and seed checks
bash "phase 5/simulate.sh"           # expect "Phase 5 simulation: PASS"
```

Two DUT behaviours every test must handle:
- `CPU.Calc` reports invalid opcodes (4'b1110, 4'b1111) with `$error`. In Verilator `$error` also
  calls `$stop`, so run with `+verilator+error+limit+N`.
- `carry` in `arithmetic_alu` is state. It carries from one `Calc` to the next, so set it with
  `set_carry()` before ADDC/SUBB, or order the calls on purpose.

## Repository map

```
phase 1/   requirements: FR/IF/OP/CA/TC/Q/TR/D tables, golden vectors (37), alu_spec.json,
           corrected architecture diagram, REVISION_2.md / REVISION_3.md (what changed and why)
phase 2/   01_spec_check (s1_intake_log.md, questions) -> 02_requirements -> 03_architecture
           -> 04_rtl (rtl/*.sv, *.svh, files.f) -> 05_build_checks -> 06_repairs -> 07_smoke
           -> 08_release (phase2_handoff.md, release_checklist.md; tag phase2-rtl-v1)
phase 3/   verification_plan.md, test_map.csv (where each TC/OP/D-ID is checked),
           tb/tb_cpu.sv (self-checking program, reference model, 44 coverage bins), run.sh,
           questions_for_phase1.md, repair_log.md, results/ (last regression of record)
phase 4/   build.sh -> build_info.txt, lint.log, build.log; elab_report.md
phase 5/   simulate.sh -> runs/<name>/ and runs/summary.txt; defects.md
phase 6/   spec.md, regress.sh -> results/<date>_<commit>_<level>/, history.csv
sessions/  shared session logs, one file per session (see below)
```

## Session logs

Chat history stays on each person's machine, so `sessions/` holds a short shared record of each
working session: what was asked, what was done, decisions with reasons, follow-ups and the git
range to check.

- **Reading:** don't load `sessions/` by default. Open it only when asked about earlier work, or
  when the code, phase READMEs and `git log` don't explain a change. Find entries with
  `ls sessions/` or `grep -ril "<keyword>" sessions/`, read only the matches, and check them
  against git.
- **Writing:** at the end of any session that changed the repo or a decision, add one new file
  using the template in `sessions/README.md`. Never edit another person's entry, and never paste
  the conversation.

## Recent changes (last 24 hours, as of 2026-10-20)

| Commit | Author | Date | Change |
|---|---|---|---|
| `863ca28` | Adam | 10-19 21:09 | Expanded Phase 3 scaffolding: driver/monitor split, configurable oracle rules, scoreboard and coverage accounting, `PLAN_ONLY` mode, offline audit scripts, mock self-test adapter. |
| `e8235f6` | Adam | 10-19 21:10 | Merged `main` from `origin`. |
| `2c04357` | Adam | 10-19 22:02 | Reorganized the repo and removed duplicates. Phase 1 files moved to the top of `phase 1/` (`README_phase1.md` → `README.md`). Phase 2's `inputs/phase1_original` and `phase1_answered` copies were deleted. The `863ca28` Phase 3 environment (`planning/`, `scripts/`, multi-file `tb/`, `results/`) was replaced by a single `tb/tb_cpu.sv`, `run.sh`, `verification_plan.md` and `questions_for_phase1.md`. `.docx` files were removed and are now ignored. |
| `819d7f0` | Adam | 10-19 22:03 | Phase 3 default random count raised from 2000 to 5000 (`tb_cpu.sv`, README, plan). Below about 3000, some shift-amount coverage bins stay empty. |
| `22b327d` | Mohamed Wael | 10-20 00:07 | Replaced Phase 2 with the numbered `00_inputs` … `08_release` layout. RTL moved from `S5_rtl/` to `04_rtl/`. The JSON handoff (`S10_handoff/*.json`) became `08_release/phase2_handoff.md`. Phase 3 and the root README now point at the new paths. |
| `d4e4cb2` | Adam | 10-20 14:04 | Phase 1 README now numbers and describes deliverables 10 to 12 (design decisions, golden vectors, `alu_spec.json`) and states that the JSON is the source for the human-readable files. |
| `80627e5`..`dda7f9b` | Adam | 10-20 21:09–21:31 | Branch `phase-4-5`. `.gitattributes` (LF everywhere). Phase 4 and 5 created and run in WSL. First compile of `tb_cpu.sv` fixed (`before` is reserved; 31 `-Wall` warnings fixed at source). All build scripts moved to temp folders (GNU Make vs spaces). Phase 3 results committed. |
| `c3ad293` | Adam | 10-20 | Phase 3 `test_map.csv`: where each TC, OP and D-ID is checked. |
| `6d7701a` | Adam | 10-20 | Phase 1 revision 3, spec 1.2: D-001..D-018 approved; D-014 names `CPU.svh` (closes DV-1). |

Net effect: Phases 1 to 5 are done. The design passes the full Phase 3 regression on approved
decisions, so the next job is Phase 6 (multi-seed regression).

## Known issues

1. **Open Phase 1 questions** (none blocks testing): Phase 2 Q1 (IF IDs for
   `get_carry`/`set_carry`), Q3 (`virtual initialize()`, DV-2), Q5 (FR priorities), Q6 (coding
   rules); Phase 3 #2 (TC acceptance wording), #3 (`GV-nn` ID column).
2. **Stale PNG.** `phase 1/ALU_Architecture_Corrected.png` still says `cpu.svh`; re-render it
   from the `.svg` (`phase 1/REVISION_3.md` has the command).
3. **TC-005 checks part of D-010.** `run.sh` matches the expected `display()` text as a
   substring, so arithmetic_alu's `carry=<0/1>` field is not checked (`phase 3/test_map.csv`).

Phase 2's handoff notes are labelled F1 (Verilator stops on `$error`) and F2 (`carry` is
state); Phase 3 files cite them by those labels.

---

## Upcoming phases

Each new phase gets a `phase N/` folder with a `README.md` (inputs, steps, commands, exit
criteria) and, when needed, a `questions_for_phase1.md` (or a defect list for Phase 2). It
follows the ground rules above. The deliverables listed below are proposals; adjust them in the
phase README when the phase starts.

### Phase 1 — Requirements & Architecture (done, revision 3, spec 1.2)

**Goal:** understand what must be built and how it should behave.
Converts the assignment PDF into traceable records, one decision per open question,
37 golden vectors from a reference model, and `alu_spec.json`. D-001..D-018 approved by Adam on
2026-10-20; D-014 names `CPU.svh` (`REVISION_3.md`).
**Remaining:** answer the open Phase 2 and Phase 3 questions (known issue 1); add a `GV-nn` ID
column to the golden vectors; re-render the PNG diagram; check the traceability evidence
against the PDF.

### Phase 2 — RTL Design (done)

**Goal:** implement the hardware in SystemVerilog.
Five files in `04_rtl/rtl/` (`cpu_pkg.sv` including `base_alu.svh`, `logical_alu.svh`,
`arithmetic_alu.svh`, `CPU.svh`). Lint with Verilator `-Wall` gives 0 messages, and the smoke
test passes 91/91. Every fix after release goes through `06_repairs/repair_log.md` and gets a
new tag (`phase2-rtl-v2`, …).

### Phase 3 — Verification Development (done, regression PASS)

**Goal:** create tests, checkers, assertions and coverage models.
`tb/tb_cpu.sv` has one task per TC (TC-001..TC-028). It reads the golden vectors at run time,
uses a reference model that must reproduce every golden vector before any DUT check runs, runs
5000 constrained-random calls with corner values, and counts 44 functional coverage bins.
`run.sh` adds log checks for TC-005 (`display()` text) and TC-027 (exactly two `%Error` lines).
`test_map.csv` shows where each TC, OP and D-ID is checked; `repair_log.md` lists the fixes
later phases asked for.
**Remaining:** consider adding immediate assertions for state invariants
(for example, invalid codes leave the ALU state unchanged); check the `carry=` field in TC-005
(known issue 3).

### Phase 4 — Compilation & Elaboration (done)

**Goal:** resolve the source code into a usable design representation.
`bash "phase 4/build.sh"` lints DUT + test program with `-Wall` and builds the binary with
warnings fatal (Verilator 5.020). The first compile found 3 errors and 31 warnings, all in the
test program and all fixed at source (no waivers). A clean clone builds with one command.
`elab_report.md` has the tool, files with sha256, include order (matches spec 1.2) and every
message's disposition. Not done: optional second simulator (Questa/VCS), skipped by decision.
Rerun after any change to `phase 2/04_rtl/` or `phase 3/tb/tb_cpu.sv`.

### Phase 5 — Simulation & Debugging (done)

**Goal:** execute tests, identify failures and fix defects.
`bash "phase 5/simulate.sh"` runs the checker self-test (stop if not OK), then `phase 3/run.sh`
at seed 7 and twice at seed 1, and checks reproducibility and that the seed changes the
stimulus. First run (clean clone of `5cc1c8b`): all PASS, no defects. Triage any future FAIL
with Phase 3 README step 6 and record it in `defects.md`; a DUT fix goes through Phase 2
`repair_log.md` and a new RTL tag.

### Phase 6 — Regression Testing

**Goal:** rerun selected tests or the full suite after changes.

**State:** implemented from `phase 6/spec.md` (`regress.sh`, `README.md`); the first real run on
Verilator is still to do. The list below was the original proposal; `spec.md` replaces it.

- **Work:**
  - Script a multi-seed regression (for example seeds 1..20 at `RANDOM_N` ≥ 5000, plus one long
    run). Collect each run's `summary.txt` and `run_info.txt` (commit, tool, golden-vector and
    DUT sha256).
  - Define the triggers, using the Phase 3 README table "Redoing Phase 3 after a change":
    - golden vectors changed: run only;
    - decision or semantics changed: update the checks citing that ID, then run;
    - TC added or removed: plan, test and run that TC;
    - new DUT tag: readiness check R10, then run.
  - Keep a quick subset (smoke plus golden vectors) for every commit and the full multi-seed set
    for every tag.
- **Deliverables:** `phase 6/regress.sh`, `phase 6/results/<date>_<commit>/`, and a pass/fail
  history table.
- **Exit criteria:** all seeds pass on the release-candidate DUT tag and Phase 1 `spec_version`,
  with no unexplained flaky results.

### Phase 7 — Coverage Analysis & Closure

**Goal:** measure verification completeness and close coverage gaps.

- **Metrics:**
  - functional coverage: all 44 bins in `verification_plan.md` section 7 (16 opcode, 8 carry
    out, 4 carry in, 16 shift/rotate amount);
  - TC coverage: 28 of 28 checked with no failures;
  - requirement coverage: every FR traced to at least one passing TC (through
    `ALU_Traceability.csv`, `phase 2/02_requirements/requirements_map.csv` and
    `phase 3/test_map.csv`);
  - optional code coverage of the RTL from `verilator --coverage` and `verilator_coverage`
    (line, toggle).
- **Closure:** close a gap by adding directed stimulus or adjusting random weights in Phase 3, or
  by a written exclusion with a reason and a reviewer. Never close a gap by removing a bin or
  loosening a check.
- **Deliverables:** `phase 7/coverage_report.md` (merged across the Phase 6 seeds) and an
  exclusion list.
- **Exit criteria:** 44/44 bins, 28/28 TCs, every FR covered, every exclusion approved.

### Phase 8 — Signoff

**Goal:** confirm the release criteria and the required evidence.

- **Checklist:**
  - Phase 1: D-001..D-018 approved, no open questions, `spec_version` final (no `-proposed`).
  - Phase 2: release tag exists on `origin`; lint clean; smoke passes; deviations DV-1 and
    DV-2 accepted by Phase 1.
  - Phase 3–5: checker self-test OK; regression PASS; all defects closed.
  - Phase 6: multi-seed regression PASS on the exact tagged commit.
  - Phase 7: coverage closed with approved exclusions only.
  - All "Known issues" above resolved.
- **Deliverables:** `phase 8/signoff.md` listing the commit, tags, tool versions, `spec_version`,
  links to every evidence file, approvers and date; plus a final git tag (for example
  `alu-signoff-v1`).
- **Exit criteria:** every checklist item ticked with evidence. Without approved Phase 1
  decisions, a PASS is provisional and signoff can't be given.
