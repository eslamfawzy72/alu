# Phase 2: RTL design of the ALU (manual workflow)

Work through the folders in number order.

| Folder | What it holds | Done when |
|---|---|---|
| `../phase 1/` | Phase 1 files, read in place and **read-only** (no copy is kept here) | — |
| `01_spec_check/` | `s1_intake_log.md` (what was received, counts, inconsistencies), `questions_for_phase1.md` | all files read, problems written down |
| `02_requirements/` | `requirements_map.csv`: what each of the 61 IDs means in code and which file owns it | every row filled |
| `03_architecture/` | `design_plan.md`: files, members, datapath, control, reset, ownership, additions, deviations | self-check (section 9) ticked |
| `04_rtl/` | `rtl/*.sv, *.svh`, `files.f` | all 5 files written |
| `05_build_checks/` | `run_checks.sh` → `lint.log`, `checks_log.md` | lint prints nothing |
| `06_repairs/` | `repair_log.md`: every error, fix, and whether the plan had to change | log matches the fixes |
| `07_smoke/` | `run_smoke.sh` → `smoke_log.txt`, `smoke_result.md` | `SUMMARY pass=91 fail=0` |
| `08_release/` | `release_checklist.md`, `phase2_handoff.md`, Git tag | tag created |

## Commands (from this folder, in Ubuntu)

```bash
./05_build_checks/run_checks.sh     # lint
./07_smoke/run_smoke.sh             # golden vectors, reset, invalid codes; ends with SMOKE: PASS (exit 0) or SMOKE: FAIL (exit 1)
```

## Rules

- Names, types and signatures come from `../phase 1/alu_spec.json` and `../phase 1/ALU_Interfaces_and_Signals.csv`. Don't rename anything.
- Every behaviour the assignment doesn't define comes from a decision (D-xxx). If none covers it, ask; don't invent.
- Anything added that isn't in the spec goes into `design_plan.md` → "Added elements".
- If a lint error means the plan was wrong, change the plan first, then the code.
