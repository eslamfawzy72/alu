# Open issues and waivers

Every issue that is unresolved at signoff time, and every waiver. An issue is closed only with evidence (a commit, a Phase 1 answer with approver and date, or a run). **Blocks signoff** = signoff can't be given while it is open (Phase 8 checklist, `README.md`).

Last updated: 2026-10-24, branch `phase-6-8`, after commit `2deaa9f` and the run of record `2026-10-24T201629Z_2deaa9f_full`.

## Open issues

| # | Issue | Evidence | Owner | Closed by | Blocks signoff |
|---|---|---|---|---|---|
| OI-1 | Phase 2 Q1: `get_carry()` and `set_carry()` have no IF ID | `../phase 2/01_spec_check/questions_for_phase1.md` Q1 (answer empty) | Phase 1 | Phase 1 adds the IF IDs (spec bump) or answers "no" | yes (checklist 1) |
| OI-2 | Phase 2 Q3: IF-007 `virtual initialize()`, deviation DV-2 not accepted | same file, Q3 (answer empty) | Phase 1 | Phase 1 updates IF-007 or rejects DV-2 | yes (checklist 1, 2) |
| OI-3 | Phase 2 Q5: FR priorities "Not specified" | same file, Q5 | Phase 1 | answer in the FR table | yes (checklist 1) |
| OI-4 | Phase 2 Q6: no coding rules given | same file, Q6 | Phase 1 | answer | yes (checklist 1) |
| OI-5 | Phase 3 #2: TC acceptance wording still says "proposed" / "not specified" | `../phase 3/questions_for_phase1.md` #2 | Phase 1 | `ALU_Verification_Requirements.csv` updated | yes (checklist 1) |
| OI-6 | Phase 3 #3: golden vectors have no stable `GV-nn` ID column | `../phase 3/questions_for_phase1.md` #3 | Phase 1 | column added, golden vectors regenerated, Phase 6 `full` rerun | yes (checklist 1) |
| OI-7 | AGENTS.md known issue 2 says the PNG is stale, but `45a4cbd` deleted `phase 1/ALU_Architecture_Corrected.png` while `phase 1/REVISION_2.md` still lists it | `git show --stat 45a4cbd`; `REVISION_2.md` rows 7 and the file list | Phase 1 | re-render the PNG from the `.svg`, or record the removal and update AGENTS.md | yes (checklist 6) |
| OI-8 | `../phase 2/08_release/phase2_handoff.md` still says spec "1.1-proposed" and "decisions still Proposed" | that file, "Spec version used" and "Open items" | Phase 2 | handoff updated to spec 1.2 | yes (evidence must be consistent) |
| OI-9 | `../phase 2/07_smoke/run_smoke.sh` exits 0 even when the smoke test fails | its last line is an `echo` | Phase 2 | optional script fix; Phase 6 judges smoke from `smoke_log.txt`, so no result depends on it | no |
| OI-10 | Coverage gaps from Phase 7 (D-011, D-013, D-014, D-016 partial or not covered; RTL `$error` branches not measured by Verilator) | `../phase 7/coverage_report.md` | Phase 7 / Phase 3 | test, map, or approved exclusion per gap | yes (checklist 5) |
## Closed since the last signoff attempt

| Issue | Closed by |
|---|---|
| AGENTS.md known issue 3: TC-005 checks only part of D-010 (`carry=` field) | Phase 3 repair 5 (whole-line check, carry set to 1), committed in `c544fef`. Proven to catch a wrong or missing `carry=` field (`../phase 6/regression_report.md`); PASS in the run of record. |
| OI-11: Phase 3 repairs 4–6 and the Phase 6–8 folders not committed | committed in `c544fef` and `2deaa9f` (pushed to `origin/phase-6-8`); run of record `../phase 6/results/2026-10-24T201629Z_2deaa9f_full` (`dirty inputs: no`), PASS |

## Waivers

None. No waiver or exclusion has been approved. Proposed exclusions are listed in `../phase 7/exclusions.md` and do not count until a reviewer approves them.
