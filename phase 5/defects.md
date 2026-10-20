# Defects

One row per defect found by a Phase 5 run. **Owner:** Phase 2 (DUT), Phase 3 (test program or reference model) or Phase 1 (spec gap). **Status:** open, fixed (fix commit given, rerun not yet passed), closed (rerun passed), deferred (reason and approver in Notes).

The first Phase 5 run (clean clone of `5cc1c8b`, 2026-10-20, Verilator 5.020) found **no DUT or reference-model defect**. The reference model reproduced all 37 golden vectors, and every DUT check passed at seeds 1 and 7 (`runs/summary.txt`).

Test-program and script problems found before the first run (Phase 4) are in `../phase 3/repair_log.md` and `../phase 2/06_repairs/repair_log.md`. They are not DUT defects, so they are not listed here.

| ID | TC | Seed | Inputs (op, A, B, carry in) | Got | Expected (Phase 1 source) | Root cause | Owner | Fix commit | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| — | — | 1, 7 | — | — | — | none found | — | — | — | — |
