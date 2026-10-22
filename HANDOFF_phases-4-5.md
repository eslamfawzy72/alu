# Handoff: Phases 4–5 and spec approval session (2026-10-20)

For an AI agent picking up this repository. It summarises one long working session between Adam
(the repo owner) and Claude Code: what was asked, what was done, what was decided and why, the
traps found, and what is still open. The repo is the source of truth. Check every claim here
against `git log` and the files before acting on it.

Read `AGENTS.md` first; it was updated at the end of this session. This file adds the context
that AGENTS.md and the commit messages don't carry.

---

## 1. State in one paragraph

Branch `phase-4-5` (pushed to `origin/phase-4-5`, HEAD `45a4cbd`, not merged into `main` or
`main-fixed`). Phases 1–5 are done. Phase 1 is at revision 3, `spec_version` 1.2, with
D-001..D-018 approved by Adam on 2026-10-20. The Phase 2 RTL (tag `phase2-rtl-v1`) is unchanged.
The Phase 3 test program `tb_cpu.sv` now compiles with **0 Verilator `-Wall` messages**. The
regression **passes** at seeds 1 and 7 (44/44 coverage bins, every counted TC passes, checker
self-test OK, seed 1 reproducible). No DUT defects were found. **Next job: Phase 6** (multi-seed
regression), as defined in AGENTS.md.

---

## 2. Environment facts (verified in this session)

| Item | Value |
|---|---|
| Host | Windows 11, repo at `C:\Users\Adam\Documents\GitHub\alu` |
| Linux | WSL2, Ubuntu 24.04.5 LTS, installed during this session |
| Simulator | Verilator 5.020 (Debian 5.020-1), the same version Phase 2 used |
| Other tools in WSL | git 2.43, g++ 13.3, make 4.3, python3 (no `cairosvg`), no verible, no SVG renderer |
| sudo in WSL | needs Adam's password; agents can't install packages |
| Git in WSL | `safe.directory` is set for `/mnt/c/Users/Adam/Documents/GitHub/alu` |
| Python on Windows | only the Microsoft Store stub: use WSL `python3` instead |
| Docker | not installed |

**Running WSL commands from the agent's shells:**
- PowerShell strips nested double quotes, so `wsl.exe -e bash -lc '... "phase 4/build.sh" ...'`
  breaks on the space. Either use `wsl.exe --cd "C:\...\alu\phase 4" -e bash -lc 'bash build.sh'`,
  or write a script into the scratchpad and run `wsl.exe -e bash /mnt/c/.../script.sh`.
- `wsl.exe` output from PowerShell can contain NUL bytes; strip them with `-replace "`0",""`.

**Two repo-wide traps, both fixed; don't reintroduce them:**
1. **CRLF.** `core.autocrlf=true` on this host gave CRLF checkouts, and bash scripts then fail in
   WSL. The root `.gitattributes` (`* text=auto eol=lf`) forces LF for every text file,
   including the CSVs, so the golden-vector sha256 in `run_info.txt` is the same on every machine.
2. **Spaces in paths.** GNU Make refuses to build in a directory whose path contains a space
   (`phase 2/`, `phase 3/`, …). Every build script now compiles in `mktemp -d`, removed on
   exit by `trap`. Copying into `phase N/build/` is not enough: that path still has the space.

---

## 3. Timeline of the session

1. **"Start Phase 4, discuss first."** Adam pasted a different Phase 4 definition
   (integration + compile + elaborate + simulate + analysis). In plan mode, a read-only readiness
   check found no simulator, CRLF checkouts, and a never-compiled testbench. Adam then said
   **AGENTS.md's phase definitions are authoritative**: Phase 4 = Compilation & Elaboration,
   Phase 5 = Simulation & Debugging, and both should be done.
2. **Readiness verdict:** Phases 2 and 3 were wired correctly (paths, API names, golden-vector CSV
   format, RTL identical to the pre-reorganisation `S5_rtl/` apart from whitespace). They were
   blocked only by the environment.
3. **Scaffolding without a simulator:** `.gitattributes`; `phase 4/` (`build.sh`, README,
   `elab_report.md`); `phase 5/` (`simulate.sh`, README, `defects.md`);
   `phase 3/repair_log.md`.
4. **WSL setup.** WSL itself was present but had no distro. Adam ran
   `wsl --install -d Ubuntu-24.04` and `apt install verilator git make g++`.
5. **Toolchain sanity check:** the Phase 2 lint passed, but the smoke build failed (GNU Make and
   spaces). After the fix, the smoke test gave `SUMMARY pass=91 fail=0`, and `smoke_log.txt` was
   byte-identical to the release run.
6. **First compile of `tb_cpu.sv`:** 3 errors (`before` is a SystemVerilog reserved word), then
   31 `-Wall` warnings. Adam chose to **fix all of them at source, with no waivers**.
7. **Phase 4 PASS** (0 messages) and **Phase 5 PASS**, both run from a **clean clone** inside WSL
   (`/tmp/alu-clean`). The clean clone was used because another session had uncommitted Phase 3
   edits in the working tree.
8. **Adam's follow-up instructions:** (1) commit the other session's pending Phase 3 test-map
   work and update the stale status text; (2) skip the optional second simulator; (3) DV-1
   becomes `CPU.svh`; (4) approve D-001..D-018. All four were done in Phase 1 revision 3 and
   propagated to Phases 2–5 and AGENTS.md.
9. **After the session,** Adam deleted `phase 1/ALU_Architecture_Corrected.png` (`45a4cbd`) and
   pushed the branch.

---

## 4. Decisions (all by Adam unless noted)

| Decision | Reason |
|---|---|
| AGENTS.md defines the phases (not the pasted alternative) | stated by Adam |
| Fix the 31 testbench lint warnings at source; no `waivers.vlt` | keeps the test program at 0 messages like the RTL; a file-wide waiver would hide future real width bugs |
| Skip the optional second simulator (Questa/VCS) | stated by Adam |
| D-014 / DV-1: the CPU file is `CPU.svh` | file name = class name (Verilator `DECLFILENAME`); the RTL already used it |
| Approve D-001..D-018 as written; "Approved by" = Adam, Date = 2026-10-20 | stated by Adam; `spec_version` 1.1-proposed → 1.2 |
| LF for every text file, CSVs included (agent) | identical sha256 evidence across machines; the plan first said to leave CSVs alone, which was wrong |
| Evidence comes from a clean clone, not the working tree (agent) | the working tree had another session's uncommitted edits |
| No regression rerun after spec 1.2 (agent) | RTL, testbench and golden vectors unchanged; only decision status and the D-014 file name changed |
| Phase 2 smoke-script fix doesn't need a new RTL tag (agent) | script-only change, RTL untouched |

---

## 5. Commits on `phase-4-5` (oldest first)

| Commit | What |
|---|---|
| `80627e5` | `.gitattributes`: LF checkout for all text files |
| `00f5f02` | Phase 4/5 scaffolding, `phase 3/repair_log.md` |
| `2ad4077` | Phase 2 `run_smoke.sh` builds in `mktemp -d`; Phase 2 repair log #1 |
| `7b4014f` | Phase 3: `before` → `state_before`; 31 warnings fixed; `run.sh` builds in `mktemp -d`; repair log #1–#3 |
| `5cc1c8b` | Phase 4 `build.sh` in `mktemp -d`; flags uncommitted inputs in `build_info.txt` |
| `d3bcb29` | Phase 4 evidence: `build_info.txt`, `lint.log`, `build.log`, `elab_report.md` |
| `7e5a8e7` | Phase 5 evidence `runs/`, `defects.md`; `phase 3/results/` |
| `dda7f9b` | Phase 2 `smoke_result.md` run 2; session log |
| `c3ad293` | Phase 3 `test_map.csv` (from another session, committed as-is with its session log) |
| `6d7701a` | Phase 1 revision 3 / spec 1.2: approvals, `CPU.svh`, `REVISION_3.md` |
| `1aad731` | spec 1.2 propagated to Phases 2–5 and AGENTS.md; session log |
| `45a4cbd` | (Adam) deleted the PNG diagram |

Session logs from this work: `sessions/2026-10-20_2100_adam_phase4-5-first-build-and-run.md`
and `sessions/2026-10-20_2135_adam_approve-decisions-spec-1-2.md`.

---

## 6. Technical details worth knowing

**Testbench changes (`phase 3/tb/tb_cpu.sv`, logged in `phase 3/repair_log.md`):**
- New `check_bit(int tc, string what, bit got, bit expected)`: use it for every 1-bit check
  (carry, comparisons, `!= null`). Use `int'()` casts when an enum goes into `check()`.
- The reference model uses `uc = {63'b0, carry_in}` in its 64-bit sums, and
  `amt = {27'b0, b[4:0]}`.
- `expected_carry(carry_given, carry, carry_in)` takes the three fields, not the whole struct
  (otherwise `UNUSEDSIGNAL`).
- TC-024 counts enum members by walking `first()`/`next()`. In Verilator 5.020, `e.num()` folds
  to a constant and leaves `e` flagged as unused.
- None of these changed an expected value, a check or a coverage bin. Seed-1 per-TC pass counts
  were identical before and after.

**Seed behaviour:** `+SEED` does change the stimulus. The per-TC pass counts differ between
seeds (seed 1 TC-006 pass=740, seed 7 pass=714), so no extra stimulus checksum was needed.

**Scripts:**
- `phase 4/build.sh`: copies the DUT and testbench into `mktemp -d`; lint `--lint-only -Wall`,
  then `--binary -Wall` with warnings fatal. Writes `build_info.txt` (commit, tool, host, sha256
  of each input, elaborated classes), `lint.log` and `build.log`. Picks up `waivers.vlt` if one
  is ever added.
- `phase 5/simulate.sh`: runs `phase 3/run.sh` four times (self-test, `+SEED=7`, seed 1 twice),
  copies each `results/` into `phase 5/runs/<name>/`, and checks REPRODUCIBLE (seed-1 logs
  identical) and SEED-CHECK (seed 1 vs seed 7 logs differ). It ends with seed 1, so
  `phase 3/results/` holds the regression of record.
- `phase 3/run.sh`: still compiles with `-Wno-fatal` (without `-Wall`). Lint strictness is
  Phase 4's job.

**Key numbers (clean clone of `5cc1c8b`):** TC-001..TC-028 except TC-005 are counted in the
log; TC-005 is checked by a log check. 10,296 checks at seed 1, 0 failures, `COVERAGE 44/44 bins
hit`. The TC-005 log check found 3 of 3 display lines. The TC-027 log check found exactly 2
`%Error` lines (4'b1110 and 4'b1111).

---

## 7. Open items

| # | Item | Owner / notes |
|---|---|---|
| 1 | **The PNG was deleted (`45a4cbd`), but three docs still reference it:** AGENTS.md known issue 2 ("Stale PNG"), the `phase 1/README.md` deliverable 9 row (`.svg`, `.png`), and the last bullet of `phase 1/REVISION_3.md`. Update them to say the SVG is the only diagram, unless Adam wants the PNG re-rendered. | ask Adam which |
| 2 | Open Phase 1 questions: Phase 2 Q1 (IF IDs for `get_carry`/`set_carry`), Q3 (`virtual initialize()`, deviation DV-2), Q5 (FR priorities), Q6 (coding rules); Phase 3 #2 (TC acceptance wording), #3 (`GV-nn` ID column) | Phase 1 / Adam; none blocks testing; all block Phase 8 signoff |
| 3 | TC-005 checks only part of D-010: `run.sh` matches the expected `display()` text as a substring, so arithmetic_alu's `carry=<0/1>` field is never checked | Phase 3 change |
| 4 | TC-027: Phase 1 lists FR-001/006/007, but the testbench comment cites FR-010 | possible Phase 1 question (from the test-map session) |
| 5 | Phase 3 "Remaining": immediate assertions for state invariants | optional |
| 6 | Branch `phase-4-5` is pushed but not merged; no PR exists | ask Adam before merging or opening a PR |
| 7 | Phase 6 not started: `phase 6/regress.sh`, seeds 1..20 at `RANDOM_N` ≥ 5000 plus one long run, triggers table, history table | next phase (see AGENTS.md) |

---

## 8. How Adam likes to work (observed)

- When Adam says "discuss first", plan and report; don't edit until approved.
- AGENTS.md is authoritative for phase scope; ask before using another definition.
- Ask when a choice is genuinely Adam's to make (for example waive vs fix); give a
  recommendation.
- More than one session may work in the same checkout at once. Before committing, run
  `git status`, **stage only your own changes**, and never commit or edit another session's
  uncommitted work without asking. To stage part of a file, write the intended index version
  and use `git hash-object -w` + `git update-index --cacheinfo`; `git add -p` is not available.
- Don't push, merge or tag without asking.
- Commit messages end with the attribution line given in the agent's system instructions. In
  this session that was `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- At the end of a session that changed the repo, add a new file in `sessions/` (template in
  `sessions/README.md`). Never edit someone else's entry, and never paste the conversation.

---

## 9. Quick verification commands (in WSL, from the repo root)

```bash
git log --oneline -12                       # expect HEAD 45a4cbd (or later)
grep spec_version "phase 1/alu_spec.json"   # "1.2"
bash "phase 4/build.sh"                     # LINT: PASS (no messages) / BUILD: PASS
bash "phase 5/simulate.sh"                  # Phase 5 simulation: PASS (4 builds + runs)
cd "phase 2" && ./07_smoke/run_smoke.sh     # SUMMARY pass=91 fail=0, 2 %Error lines
```

Running these rewrites committed evidence files (`phase 4/*.log`, `build_info.txt`,
`phase 5/runs/`, `phase 3/results/`, `phase 2/07_smoke/*`). Commit them only when the run is
meant to be new evidence; otherwise restore them with `git checkout -- <paths>`.
