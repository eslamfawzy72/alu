# Phase 2 output: ALU class model

This folder is what the Phase 2 agent hands over for the ALU assignment. I went through the ten stages by hand on the Phase 1 output, and **no LLM was called**:
- The judgement work (the plan in S3, the RTL in S5, the repair decision in S7, the review in S10) I did myself.
- Every check was done by a tool: the scripts in `tools/`, Verilator 5.020 and Verible.

The full explanation of every file is in `Phase2_ALU_Output_Explained.docx`.

## What happened in this run

```
S1 → S2  original Phase 1 output .............. BLOCKED (74 blocking findings, 18 open questions)
S1 → S2  Phase 1 answers (D-001..D-018) ........ ready with conditions (decisions approved provisionally)
S3 plan v1 → S4 review v1 → S5 RTL → S6 round 1 FAIL (Verilator DECLFILENAME: cpu.svh vs class CPU)
S7 classifies it as structural: the fix renames a file that D-014 fixes → escalate to S3
S3 plan v2 (CPU.svh, deviation from D-014) → S4 review v2 → S5 regenerates 2 files → S6 round 2 PASS
S8 smoke 91/91 checks pass → S9 conforms: 59 IDs implemented, 2 explained, 0 missing
S10 review: 5 flags, 21 open items → manifest → Git tag phase2-baseline-s1.1-proposed-p2
```

## Folder map

| Folder | Stage | Made by |
|---|---|---|
| `inputs/` | Phase 1 output (original), Phase 1 answers, the provisional approval record | Phase 1 / team |
| `S1_intake/` | normalized handoff + parse log, for both inputs | `tools/s1_normalize.py` |
| `S2_readiness/` | readiness reports; questions for Phase 1 | `tools/s2_readiness.py` |
| `S3_plan/` | design plans v1 and v2, their rule checks, class diagrams | plan by hand, checks by `tools/check_plan.py` |
| `S4_review/` | review requests, review records, the frozen plan, per-unit slices | `tools/s4_review.py` + review file |
| `S5_rtl/` | the RTL (5 files), `files.f`, generation record | RTL by hand |
| `S6_gate/` | lint and interface results, round 1 (fail) and round 2 (pass) | `tools/s6_gate.py` |
| `S7_repair/` | classification and escalation for round 1 | `tools/s7_classify.py` + escalation record |
| `S8_smoke/` | generated smoke test, build log, run log, result | `tools/s8_smoke.py` |
| `S9_trace/` | ID-to-line trace, design graph, conformance report, traceability table | `tools/s9_trace.py` |
| `S10_handoff/` | review notes, sign-off, `phase2_handoff.json` | review by hand, `tools/s10_manifest.py` |

`./run_all.sh` regenerates every tool output from the inputs and the hand-made files.

## Before this baseline is final

The 18 Phase 1 decisions and both design reviews are approved **provisionally**. The team must approve them, or change them and re-run. `S10_handoff/review_notes.md` lists everything still open.
