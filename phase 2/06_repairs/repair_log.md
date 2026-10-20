# Repair log

**Local** = fix inside the reported lines, no spec name changes.
**Structural** = the fix changes the plan or a name fixed by the spec → update design_plan.md (new version) first, then the code.

| # | Round | Tool message (file:line, rule, text) | Local / structural | Fix applied (or plan change) | Lines changed | Re-check result |
|---|---|---|---|---|---|---|
| — | — | no failures: lint run 1 passed, smoke run 1 passed | — | — | — | — |
| 1 | after release (Phase 4, 2026-10-20) | `07_smoke/run_smoke.sh`: `verilated.mk:66: *** Unsupported: GNU Make cannot build in directories containing spaces` (repo path `phase 2/`; the release run used a path without spaces) | local (script only; RTL unchanged, so no new tag) | `-Mdir` moved to a `mktemp -d` folder, removed on exit | `run_smoke.sh` 3–8 | smoke rerun on Verilator 5.020 (WSL): `SUMMARY pass=91 fail=0`, 2 `%Error` lines, `smoke_log.txt` byte-identical to the release run |

Problems prevented in the plan instead of repaired here (found in S1, see `01_spec_check/s1_intake_log.md`):

| Would-be message | Class | Handled by |
|---|---|---|
| `%Warning-DECLFILENAME: rtl/cpu.svh:3: Filename 'cpu' does not match CLASS name: 'CPU'` | structural (renames a file fixed by D-014) | deviation DV-1 in plan v1 |
