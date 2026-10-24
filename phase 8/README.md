# Phase 8: Verification Signoff

Phase 8 checks every release criterion against evidence on **one frozen commit**, records the accepted RTL revision and the final verification status, and, once the approvers agree, tags that commit.

**Rule:** signoff is given on evidence only. Every checklist item links to a file produced by a real run or to an approval with a name and a date. A result that depends on an unapproved decision, an open question or an unapproved exclusion is provisional, and signoff can't be given while any check fails. Any change to an input after the release run means starting again from Phase 4.

## Files

| File | Written by | Content |
|---|---|---|
| `signoff_check.py` | hand | checks the evidence mechanically; writes `signoff_check.txt` |
| `signoff_check.txt` | `signoff_check.py` | one `PASS`, `FAIL` or `MANUAL` line per checklist item, with its evidence, and the verdict `READY` or `NOT READY` |
| `open_issues.md` | hand | every unresolved issue and every waiver, with owner, what closes it and whether it blocks signoff |
| `signoff.md` | hand | the verification signoff report: accepted RTL revision, tools, spec version, final regression and coverage results, traceability, open issues and waivers, final status, approvers |

## Inputs

| From | File | Used for |
|---|---|---|
| Phase 1 | `alu_spec.json`, `ALU_Design_Decisions.csv`, `ALU_Open_Questions.csv` | final `spec_version`, approved decisions, no open question |
| Phase 2 | tag `phase2-rtl-v*`, `01_spec_check/questions_for_phase1.md`, `08_release/` | accepted RTL revision; DV-1 and DV-2 accepted |
| Phase 3 | `questions_for_phase1.md`, `repair_log.md` | no open question; test-program history |
| Phase 4 | `elab_report.md` | zero errors, every warning dispositioned |
| Phase 5 | `defects.md` | every defect closed or formally deferred |
| Phase 6 | `history.csv`, `results/<release run>/`, `regression_report.md` | release regression PASS on the signoff commit, no FLAKY, every failure explained |
| Phase 7 | `results/<release run>/`, `results/code_*_<commit>/`, `coverage_report.md`, `exclusions.md` | goals G1 to G4 met, exclusions approved |
| root | `AGENTS.md` → "Known issues" | all resolved |

## Steps

Run in Ubuntu (WSL on Windows) from the repo root.

1. **Freeze:** commit everything. From here on, no input changes.
2. Run the release regression and the Phase 7 measurements on that commit:
   ```bash
   bash "phase 6/regress.sh" release --note "release candidate"
   R="phase 6/results/<that run>"
   bash "phase 7/merge_coverage.sh" "$R"
   python3 "phase 7/trace_requirements.py" "$R"
   bash "phase 7/code_coverage.sh"
   ```
   Commit those results (a results-only commit changes no input, so the run still applies; `signoff_check.py` compares against the run's commit).
3. `python3 "phase 8/signoff_check.py"`. Every `FAIL` is a blocker: fix it in its own phase, then go back to step 1.
4. Update `open_issues.md` and confirm each `MANUAL` line in `signoff.md`.
5. Fill in `signoff.md` from the evidence files, then collect the approvers' names and dates.
6. When the status is SIGNED OFF and the approvers agree: commit, then tag the signoff commit `alu-signoff-v1` and push the tag. Tagging and pushing are done by a person or with their explicit go-ahead.

## Checklist

| # | Item | Checked by |
|---|---|---|
| 1 | Phase 1: `spec_version` final (no `-proposed`); D-001..D-018 approved with approver and date; no open Phase 1 question (including the Phase 2 and Phase 3 question files) | `signoff_check.py` |
| 2 | Phase 2: an RTL tag equals `04_rtl/` at the signoff commit and exists on `origin`; lint clean and smoke pass (Phase 6 build and smoke steps); DV-1 and DV-2 accepted | `signoff_check.py` + Phase 6 run |
| 3 | Phases 3 to 5: checker self-test OK, regression PASS (Phase 6 run); every defect closed or deferred | `signoff_check.py` |
| 4 | Phase 6: `release` run PASS on the signoff commit, no uncommitted inputs, no FLAKY; every failing run explained | `signoff_check.py` + MANUAL |
| 5 | Phase 7: G1 to G4 met on the release run; every exclusion approved | `signoff_check.py` |
| 6 | AGENTS.md known issues resolved | MANUAL |

## Exit criteria

- `signoff_check.txt` says `READY` on the signoff commit;
- every `MANUAL` item confirmed in `signoff.md`;
- `signoff.md` has status SIGNED OFF, approvers and date;
- tag `alu-signoff-v1` on the signoff commit, pushed to `origin`.

## Status

See `signoff.md`.
