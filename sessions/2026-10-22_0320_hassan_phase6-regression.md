# Phase 6 regression script, smoke exit code

| Field | Value |
|---|---|
| When | 2026-10-22 03:20–03:45 +03:00 |
| Who | Hassan, with Claude Code (desktop app) |
| Branch | phase-6-7 |
| Git | `2542134`..(uncommitted at time of writing); tags: none |
| Phases | 2, 6 |
| Keywords | regress.sh, history.csv, fingerprint, FLAKY, run_smoke.sh, SMOKE: PASS |

## Asked
Make any Phase 2 changes Phase 6 needs, then implement `phase 6/spec.md`.

## Done
- Phase 2 RTL reviewed: no change needed (lint clean, regression PASS, matches spec 1.2), so the tag stays `phase2-rtl-v1`.
- `phase 2/07_smoke/run_smoke.sh` now exits 1 unless the log has `SUMMARY pass=91 fail=0` and exactly 2 `%Error` lines (prints `SMOKE: PASS/FAIL`). Logged as Phase 2 repair #2. Handoff "Open items" brought up to spec 1.2.
- `phase 6/regress.sh` and `phase 6/README.md` written from `spec.md`: quick/full/release levels, fingerprint change check with skip and `--force`, build gate, smoke, self-test, seed 1 last, rerun-once FAIL/FLAKY, `regression_summary.txt`, `failures.txt`, `history.csv`.
- AGENTS.md and README.md: Phase 6 row, commands, repo map.

## Decisions
- Results folder name uses date and time (`%Y-%m-%dT%H%M%SZ`), not only the date: two runs on the same day and commit would otherwise overwrite each other.
- `fingerprint.txt` is saved in each results folder, so the next change check can name the inputs that changed.
- `rtl_tag` = newest `phase2-rtl-v*` tag whose `04_rtl/` matches the files under test (a docs-only commit keeps the tag).
- Build-gate and self-test console output is kept (`build/console.log`, `selftest/console.log`).

## Not done / follow-ups
- First real `bash "phase 6/regress.sh" full`: Verilator is not installed on this machine (WSL Ubuntu has none, and installing it needs sudo). Then commit `history.csv` and `results/`.
- `run_smoke.sh` change not rerun on real Verilator; only checked against the committed `smoke_log.txt`.

## Notes for later
- Tested with a stub `verilator` (scratchpad only, not committed) that replays committed logs. Twice, the first run after resetting outputs reported the self-test as NOT OK, and this could not be reproduced. The likely cause is a cold WSL `/mnt/d` mount; the restored committed summary hid it. `selftest/console.log` now captures the cause if it happens again.
- This Windows working copy has CRLF files (checked out before `.gitattributes`), so its fingerprints differ from an LF clone.
