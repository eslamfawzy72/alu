"""S10 · Handoff manifest (deterministic).

usage: python3 s10_manifest.py <workspace>   (run from the Git repository root)
writes: S10_handoff/phase2_handoff.json, the single file Phase 3, Phase 4 and Milestone 1 read
"""
import hashlib, json, subprocess, sys
from pathlib import Path

ws = Path(sys.argv[1])
j = lambda p: json.loads((ws / p).read_text())
plan, gate, smoke, conf = (j("S4_review/design_plan_approved.json"), j("S6_gate/round2/gate_report.json"),
                           j("S8_smoke/smoke_result.json"), j("S9_trace/conformance_report.json"))
ready = j("S2_readiness/run2_answered/readiness_report.json")
git = lambda *a: subprocess.run(["git", *a], cwd=ws, capture_output=True, text=True).stdout.strip()
rtl = sorted((ws / "S5_rtl/rtl").iterdir())
tag = f"phase2-baseline-s{plan['spec_version']}-p{plan['plan_version']}"
m = {
    "project": "ALU class hierarchy and CPU integration",
    "status": "baseline_provisional",
    "why_provisional": "Phase 1 decisions D-001..D-018 and both design reviews are approved provisionally",
    "spec_version": plan["spec_version"], "plan_version": plan["plan_version"], "design_kind": plan["mode"],
    "git": {"tag": tag, "baseline_commit": "see `git rev-list -n1 " + tag + "`"},
    "dut": {"top": plan["top"], "filelist": "S5_rtl/files.f", "include_dirs": ["S5_rtl/rtl"],
            "files": [{"file": f"S5_rtl/rtl/{f.name}", "unit": next(u["name"] for u in plan["units"] if u["file"] == f.name),
                       "lines": len(f.read_text().splitlines()),
                       "sha256": hashlib.sha256(f.read_bytes()).hexdigest()[:16]} for f in rtl],
            "compile": "verilator --binary -f files.f <tb.sv> (run from S5_rtl); any simulator with SV class support"},
    "gates": {"S6": {"rounds": 2, "round1": "fail: 1 message (DECLFILENAME rtl/cpu.svh), escalated to S3",
                     "round2": gate["checks"], "tools": gate["tools"]},
              "S8": {"result": smoke["result"], "summary": smoke["summary"],
                     "expected_errors": smoke["errors_reported"], "cases": len(smoke["per_case"])},
              "S9": {"conforms": conf["conforms"], "ids_total": conf["ids_total"], "implemented": conf["implemented"],
                     "explained": conf["explained"], "missing": conf["missing"]}},
    "trace": {"id_to_lines": "S9_trace/rtl_trace.json", "table": "S9_trace/traceability.csv",
              "graph": ["S9_trace/design_graph.graphml", "S9_trace/design_graph.json"], "graph_size": conf["graph"]},
    "plan": {"approved": "S4_review/design_plan_approved.json", "history": ["S3_plan/design_plan_v1.json",
             "S3_plan/design_plan_v2.json"]},
    "added_elements": plan["added_elements"], "deviations": plan.get("deviations", []),
    "not_in_rtl": plan["not_in_rtl"],
    "review": "S10_handoff/review_notes.md",
    "open_items": [f["item"] + ": " + f["finding"] for f in ready["findings"] if f["severity"] == "condition"]
                  + ["design reviews v1, v2: reviewer name pending", "FR-001..FR-013: priority not given",
                     "D-014 wording to amend (file CPU.svh)"],
    "consumers": {"phase3": "dut + trace + smoke vectors as a starting point",
                  "phase4": "dut.filelist and compile line",
                  "milestone1": "design_graph.json + rtl_trace.json + git tag = baseline for change impact"},
}
(ws / "S10_handoff/phase2_handoff.json").write_text(json.dumps(m, indent=1))
print(tag, len(m["open_items"]), "open items")
