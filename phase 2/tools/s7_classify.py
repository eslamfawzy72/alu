"""S7 · Repair, step 1: classify each failing message (rules first, no LLM).

usage: python3 s7_classify.py <gate_report.json> <design_plan_approved.json> <handoff> <out.json>
A message is LOCAL when its fix stays inside the reported lines and changes no name fixed by the
spec; STRUCTURAL when the fix would change the plan or contradict a spec decision; anything the
table does not know goes to a human (where the LLM would be asked in the automated agent).
"""
import json, re, sys
from pathlib import Path

gate = json.loads(Path(sys.argv[1]).read_text())
plan = json.loads(Path(sys.argv[2]).read_text())
h = json.loads(Path(sys.argv[3]).read_text())

LOCAL = {"WIDTHEXPAND": "add an explicit cast or size", "WIDTHTRUNC": "take the needed bits explicitly",
         "UNUSEDSIGNAL": "remove or use the variable", "CASEINCOMPLETE": "add a default branch",
         "DECLFILENAME": "rename the file to the unit name", "line-length": "wrap the line",
         "no-trailing-spaces": "delete trailing spaces", "no-tabs": "replace tabs with spaces"}
STRUCTURAL = {"IFACE": "the code does not match the planned interface"}

# names the spec fixes: interface names, unit names, and file names written into a decision
fixed = {i["name"] for i in h["interfaces"]} | {u["name"] for u in plan["units"]}
fixed_files = {}
for d in h["decisions"]:
    for f in re.findall(r"\b\w+\.svh?\b", d["text"]):
        fixed_files[f] = d["id"]

out = []
for m in gate["messages"]:
    r = {"message": m}
    if m["rule"] == "ERROR" and "syntax error" in m["text"]:
        r.update(cls="local", fix="correct the syntax on or just before the reported line", route="S6 after patch")
    elif m["rule"] in STRUCTURAL:
        r.update(cls="structural", why=STRUCTURAL[m["rule"]], route="S3")
    elif m["rule"] in LOCAL:
        r.update(cls="local", fix=LOCAL[m["rule"]], route="S6 after patch")
        f = Path(m["file"]).name
        if m["rule"] == "DECLFILENAME" and f in fixed_files:
            r.update(cls="structural", route="S3",
                     why=f"the fix renames {f}, a file name fixed by {fixed_files[f]}; "
                         "a repair may not change a name the spec fixed, so the plan must decide")
    else:
        r.update(cls="unknown", route="human")
    out.append(r)
res = {"round": int(re.search(r"round(\d+)", sys.argv[1]).group(1)), "classified": out,
       "next": "S3" if any(x["cls"] == "structural" for x in out) else
               ("human" if any(x["cls"] == "unknown" for x in out) else "patch")}
Path(sys.argv[4]).parent.mkdir(parents=True, exist_ok=True)
Path(sys.argv[4]).write_text(json.dumps(res, indent=1))
print(res["next"], [(x["message"]["rule"], x["cls"]) for x in out])
