"""S4 · Plan validation and design review (rules + a human decision file, no LLM).

usage: python3 s4_review.py <handoff> <design_plan_vN.json> <validation.json> <out_dir> [<review.json>]
 without review.json: writes plan_vN_review_request.md and plan_vN_review.template.json, stops
 with review.json   : if approved, freezes design_plan_approved.json and writes slices/<unit>.json
"""
import json, shutil, sys
from pathlib import Path

h = json.loads(Path(sys.argv[1]).read_text())
plan_p = Path(sys.argv[2]); plan = json.loads(plan_p.read_text())
val = json.loads(Path(sys.argv[3]).read_text())
out = Path(sys.argv[4]); out.mkdir(parents=True, exist_ok=True)
v = plan["plan_version"]
if val["result"] != "pass":
    sys.exit("plan failed validation: back to S3")

text = {}
for k in ("requirements", "operations", "decisions"):
    for x in h[k]:
        text[x["id"]] = x.get("text") or x.get("result") or x.get("title")
for i in h["interfaces"]:
    text[i["id"]] = f"{i['owner']}.{i['name']}: {i['signature'] or i['type']}"

if len(sys.argv) < 6:
    L = [f"# Design review request: plan v{v}", "",
         f"Spec {plan['spec_version']}, mode {plan['mode']}. Automatic checks: **{val['result']}** "
         f"({val['ids_in_spec']} spec IDs: {val['ids_owned']} owned, {val['ids_explained']} explained).", "",
         "## Units", "", "| Unit | Kind | File | Extends | Owns |", "|---|---|---|---|---|"]
    for u in plan["units"]:
        L.append(f"| {u['name']} | {u['kind']} | {u['file']} | {u.get('extends') or ''} | {', '.join(u['owns'])} |")
    L += ["", "## Please decide", ""]
    for a in plan["added_elements"]:
        L.append(f"- **Added element** `{a['name']}` in {a['unit']}: {a['why']}. Approve or reject.")
    for x in val["rules"].values():
        for w in x["warnings"]:
            if not w.startswith("added element"):
                L.append(f"- **Warning**: {w}")
    for d in plan.get("deviations", []):
        L.append(f"- **Deviation from {d['id']}**: spec says `{d['spec_says']}`, plan does `{d['plan_does']}`. {d['why']}")
    if plan.get("replan_reason"):
        L.insert(3, f"Re-plan requested by {plan['replan_reason']['from']}: {plan['replan_reason']['summary']}.\n")
    for e in plan["not_in_rtl"]:
        L.append(f"- **Not in RTL** {e['id']}: {e['reason']}")
    L += ["", "Write the decision into `plan_v%d_review.json` (template next to this file)." % v]
    (out / f"plan_v{v}_review_request.md").write_text("\n".join(L) + "\n")
    tmpl = {"plan_version": v, "decision": "approved | rejected", "reviewer": "", "date": "",
            "comments": [], "added_elements": {a["name"]: "approved | rejected" for a in plan["added_elements"]},
            "deviations": {d["id"]: "approved | rejected" for d in plan.get("deviations", [])}}
    (out / f"plan_v{v}_review.template.json").write_text(json.dumps(tmpl, indent=1))
    print("awaiting_review")
    sys.exit(0)

rev = json.loads(Path(sys.argv[5]).read_text())
devs = rev.get("deviations", {})
if rev["decision"] != "approved" or any(s != "approved" for s in rev["added_elements"].values()) \
        or any(devs.get(d["id"]) != "approved" for d in plan.get("deviations", [])):
    print("rejected: back to S3 with", rev["comments"]); sys.exit(2)
shutil.copy(plan_p, out / "design_plan_approved.json")
rules = {"language": "SystemVerilog-2017 (IEEE 1800-2017)", "one_unit_per_file": "CA-001",
         "extern": "not used (D-013)", "tags": "every line implementing an ID ends with // @ID",
         "only_tag": "IDs in owns or uses of this slice"}
(out / "slices").mkdir(exist_ok=True)
for u in plan["units"]:
    ids = u["owns"] + u["uses"]
    base = next((b for b in plan["units"] if b["name"] == u.get("extends")), None)
    sl = {"unit": u, "spec_text": {i: text[i] for i in ids},
          "base_class": {"name": base["name"], "methods": [m["signature"] for m in base["methods"]],
                         "properties": [f"{p['type']} {p['name']}" for p in base["properties"]]} if base else None,
          "enum": plan["units"][0]["types"][0]["members"] if u["kind"] != "package" else None,
          "coding_rules": rules, "must_tag": u["owns"]}
    (out / "slices" / f"{u['name']}.json").write_text(json.dumps(sl, indent=1, ensure_ascii=False))
print("approved: plan frozen,", len(plan["units"]), "slices written")
