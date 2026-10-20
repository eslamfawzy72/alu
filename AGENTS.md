# AGENTS.md

Guidance for AI agents and engineers working in this repository. Read this first, then the
`README.md` of the phase folder you are working in.

## What this repo is

A SystemVerilog **class model** of an ALU (`base_alu`, `logical_alu`, `arithmetic_alu`) and a
`CPU` class that uses them, all in package `cpu_pkg`. It is simulation-only and object-oriented,
not synthesizable RTL: there is no synthesis, timing or gate-level step. The project is built
in eight phases. Phases 1 to 3 have folders in the repo. Phases 4 to 8 are upcoming.

| Phase | Name | Folder | State |
|---|---|---|---|
| 1 | Requirements & Architecture | `phase 1/` | revision 2 done; decisions not yet approved |
| 2 | RTL Design | `phase 2/` | RTL written, lint clean, smoke 91/91 (`phase2-rtl-v1`) |
| 3 | Verification Development | `phase 3/` | plan and testbench written; **never compiled or run** |
| 4 | Compilation & Elaboration | `phase 4/` (to create) | not started |
| 5 | Simulation & Debugging | `phase 5/` (to create) | not started |
| 6 | Regression Testing | `phase 6/` (to create) | not started |
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
8. **Results are provisional** until Phase 1 records an approver and date for D-001..D-018.

## Tools and environment

- **Simulator:** Verilator 5.020 or later (`--binary`, `--lint-only -Wall`). The spec's
  `tool_gate` also accepts Questa or VCS (for example on EDA Playground).
- **Shell:** the scripts are bash and were run on Ubuntu. On Windows, use WSL. Verilator is not
  installed on the Windows host.
- **Optional:** `verible-verilog-lint` (style lint, used by `run_checks.sh` when present).
- **Generated and ignored files:** `build/`, `obj_dir/`, `*.docx` (root `.gitignore`).
  `phase 3/results/` is written by `run.sh` and should be committed after a real run.

## Key commands

```bash
# Phase 2: lint and smoke test (from "phase 2/")
./05_build_checks/run_checks.sh      # expect "LINT: PASS (no messages)"
./07_smoke/run_smoke.sh              # expect "SUMMARY pass=91 fail=0" and 2 expected %Error lines

# Phase 3: checker self-test, then regression (from "phase 3/")
bash run.sh +CHECKER_SELFTEST        # must end with "checker self-test OK"
bash run.sh                          # must end with "Phase 3 regression: PASS"
bash run.sh +SEED=7 +RANDOM_N=10000  # different seed / more random calls (keep RANDOM_N >= 3000)
```

Two DUT behaviours every test must handle:
- `CPU.Calc` reports invalid opcodes (4'b1110, 4'b1111) with `$error`. In Verilator `$error` also
  calls `$stop`, so run with `+verilator+error+limit+N`.
- `carry` in `arithmetic_alu` is state. It carries from one `Calc` to the next, so set it with
  `set_carry()` before ADDC/SUBB, or order the calls on purpose.

## Repository map

```
phase 1/   requirements: FR/IF/OP/CA/TC/Q/TR/D tables, golden vectors (37), alu_spec.json,
           corrected architecture diagram, REVISION_2.md (what changed and why)
phase 2/   01_spec_check (s1_intake_log.md, questions) -> 02_requirements -> 03_architecture
           -> 04_rtl (rtl/*.sv, *.svh, files.f) -> 05_build_checks -> 06_repairs -> 07_smoke
           -> 08_release (phase2_handoff.md, release_checklist.md; tag phase2-rtl-v1)
phase 3/   verification_plan.md, tb/tb_cpu.sv (self-checking program, reference model,
           44 coverage bins), run.sh, questions_for_phase1.md
```

## Recent changes (last 24 hours, as of 2026-10-20)

| Commit | Author | Date | Change |
|---|---|---|---|
| `863ca28` | Adam | 10-19 21:09 | Expanded Phase 3 scaffolding: driver/monitor split, configurable oracle rules, scoreboard and coverage accounting, `PLAN_ONLY` mode, offline audit scripts, mock self-test adapter. |
| `e8235f6` | Adam | 10-19 21:10 | Merged `main` from `origin`. |
| `2c04357` | Adam | 10-19 22:02 | Reorganized the repo and removed duplicates. Phase 1 files moved to the top of `phase 1/` (`README_phase1.md` → `README.md`). Phase 2's `inputs/phase1_original` and `phase1_answered` copies were deleted. The `863ca28` Phase 3 environment (`planning/`, `scripts/`, multi-file `tb/`, `results/`) was replaced by a single `tb/tb_cpu.sv`, `run.sh`, `verification_plan.md` and `questions_for_phase1.md`. `.docx` files were removed and are now ignored. |
| `819d7f0` | Adam | 10-19 22:03 | Phase 3 default random count raised from 2000 to 5000 (`tb_cpu.sv`, README, plan). Below about 3000, some shift-amount coverage bins stay empty. |
| `22b327d` | Mohamed Wael | 10-20 00:07 | Replaced Phase 2 with the numbered `00_inputs` … `08_release` layout. RTL moved from `S5_rtl/` to `04_rtl/`. The JSON handoff (`S10_handoff/*.json`) became `08_release/phase2_handoff.md`. Phase 3 and the root README now point at the new paths. |
| `d4e4cb2` | Adam | 10-20 14:04 | Phase 1 README now numbers and describes deliverables 10 to 12 (design decisions, golden vectors, `alu_spec.json`) and states that the JSON is the source for the human-readable files. |

Net effect: Phase 1 and Phase 2 have stable layouts. Phase 3 was simplified to one testbench
that has not been compiled yet, so the first job of Phase 4 is to compile it.

## Known issues

1. **Spec vs RTL file name.** `alu_spec.json` lists `cpu.svh` and the RTL uses `CPU.svh`
   (deviation DV-1, Phase 2 question Q2). This is still open.
2. **Open Phase 1 questions.** Phase 2 Q1 to Q6 and Phase 3 #1 to #3 have not been answered.
   D-001..D-018 have no approver or date.

Phase 2's handoff notes are labelled F1 (Verilator stops on `$error`) and F2 (`carry` is
state); Phase 3 files cite them by those labels.

---

## Upcoming phases

Each new phase gets a `phase N/` folder with a `README.md` (inputs, steps, commands, exit
criteria) and, when needed, a `questions_for_phase1.md` (or a defect list for Phase 2). It
follows the ground rules above. The deliverables listed below are proposals; adjust them in the
phase README when the phase starts.

### Phase 1 — Requirements & Architecture (done, pending approval)

**Goal:** understand what must be built and how it should behave.
Converts the assignment PDF into traceable records, one proposed decision per open question,
37 golden vectors from a reference model, and `alu_spec.json`.
**Remaining:** approve D-001..D-018 (fill "Approved by" and "Date"); answer the Phase 2 and Phase 3
questions; add a `GV-nn` ID column to the golden vectors; check the traceability evidence
against the PDF.

### Phase 2 — RTL Design (done)

**Goal:** implement the hardware in SystemVerilog.
Five files in `04_rtl/rtl/` (`cpu_pkg.sv` including `base_alu.svh`, `logical_alu.svh`,
`arithmetic_alu.svh`, `CPU.svh`). Lint with Verilator `-Wall` gives 0 messages, and the smoke
test passes 91/91. Every fix after release goes through `06_repairs/repair_log.md` and gets a
new tag (`phase2-rtl-v2`, …).

### Phase 3 — Verification Development (written, not run)

**Goal:** create tests, checkers, assertions and coverage models.
`tb/tb_cpu.sv` has one task per TC (TC-001..TC-028). It reads the golden vectors at run time,
uses a reference model that must reproduce every golden vector before any DUT check runs, runs
5000 constrained-random calls with corner values, and counts 44 functional coverage bins.
`run.sh` adds log checks for TC-005 (`display()` text) and TC-027 (exactly two `%Error` lines).
**Remaining:** consider adding immediate assertions for state invariants
(for example, invalid codes leave the ALU state unchanged).

### Phase 4 — Compilation & Elaboration

**Goal:** resolve the source code into a usable design representation.

- **Inputs:** `phase 2/04_rtl/files.f` and the compile line in `phase2_handoff.md`,
  `phase 3/tb/tb_cpu.sv`, `alu_spec.json` → `tool_gate`.
- **Work:**
  - Compile and elaborate DUT and testbench together with Verilator ≥ 5.020
    (`--binary --top-module tb_cpu`). Record the exact tool version.
  - Compile `tb_cpu.sv` for the first time. Fix testbench compile errors in Phase 3 and DUT
    errors in Phase 2, logged in each phase's own repair log.
  - Review every warning. `run.sh` uses `-Wno-fatal`, so warnings don't stop the build; each one
    must be fixed or waived with a reason.
  - Lint the testbench with `-Wall`, as Phase 2 did for the RTL.
  - Optionally compile on a second simulator (Questa or VCS) to catch tool-specific behaviour,
    such as `$error` semantics, class handle defaults and `program` blocks.
  - Confirm the include order matches `alu_spec.json` → `package.includes_in_order`, and settle
    the `cpu.svh`/`CPU.svh` question (known issue 1).
  - Check that paths with spaces are handled. `run.sh` copies the DUT into `build/` for this.
- **Deliverables:** `phase 4/README.md`, a build script, `build.log` and `elab_report.md`
  (tool, version, top, files with sha256, warnings and their disposition).
- **Exit criteria:** zero errors; every warning fixed or waived; the binary builds from a clean
  checkout with one command.

### Phase 5 — Simulation & Debugging

**Goal:** execute tests, identify failures and fix defects.

- **Inputs:** the Phase 4 build, `phase 3/run.sh`.
- **Work:**
  - Run `bash run.sh +CHECKER_SELFTEST` first. If it is not OK, the checkers can't be trusted,
    so stop and fix the testbench.
  - Run `bash run.sh` and triage every `FAIL` using Phase 3 README step 6:
    - "reference model disagrees with golden vector N": the model is wrong; fix it in Phase 3.
    - A DUT check fails and the cited Phase 1 source is clear: DUT bug; file it with the TC,
      inputs, value received, value expected and Phase 1 ID.
    - A DUT check fails and the source is unclear: ask Phase 1.
  - Debug with `$display` traces or waveforms (`--trace`/`--trace-fst`) at a fixed `+SEED`.
- **Deliverables:** `phase 5/defects.md` (ID, TC, seed, inputs, got/expected, root cause, owner,
  fix commit, status); updated Phase 2 `repair_log.md` and a new RTL tag for each fix.
- **Exit criteria:** checker self-test OK; `Phase 3 regression: PASS` at seed 1; every defect
  closed or formally deferred.

### Phase 6 — Regression Testing

**Goal:** rerun selected tests or the full suite after changes.

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
    `ALU_Traceability.csv` and `phase 2/02_requirements/requirements_map.csv`);
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
