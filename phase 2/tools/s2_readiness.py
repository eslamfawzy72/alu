"""S2 · Readiness check (deterministic rules, no LLM).

Stops the run before any design work if the spec has gaps that would force a guess.

usage: python3 s2_readiness.py <phase1_handoff.json> <out_dir> [--approvals approvals.json]
writes: <out_dir>/readiness_report.json   ready / ready_with_conditions / blocked, findings per rule
        <out_dir>/questions_for_phase1.md one question per blocking finding (only when blocked)

--approvals: the team's approval record for the decisions (IN-07). An entry with
"provisional": true lets the run continue, but every such decision is carried to S10 as an open item.
"""
import json, sys
from pathlib import Path

h = json.loads(Path(sys.argv[1]).read_text())
out = Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
appr = {}
if "--approvals" in sys.argv:
    appr = {a["id"]: a for a in json.loads(Path(sys.argv[sys.argv.index("--approvals") + 1]).read_text())}

F = []   # findings


def add(rule, sev, item, msg, ask=None, inp=None):
    F.append({"rule": rule, "severity": sev, "item": item, "finding": msg, "question": ask, "input": inp})


hw = bool(h["design"]["kind"]) and "synthes" in h["design"]["kind"].lower() and "not synthes" not in h["design"]["kind"].lower()
answered = {d["resolves"] for d in h["decisions"]}

# R01 every open question has an answer
for q in h["open_questions"]:
    if q["id"] not in answered and q["status"].lower() == "open":
        add("R01", "block", q["id"], f"open question with no answer: {q['question']}",
            f"{q['id']}: {q['question']} Please give the agreed answer, who approved it and the date.", "IN-07")

# R02 every decision approved
for d in h["decisions"]:
    a = appr.get(d["id"])
    if d["status"].lower().startswith("resolved (language"):
        continue
    if d["approved_by"]:
        continue
    if a and a.get("provisional"):
        add("R02", "condition", d["id"], f"decision '{d['status']}', accepted provisionally for this run "
            f"({a['note']})", None, "IN-07")
    elif not (a and a.get("approved_by")):
        add("R02", "block", d["id"], f"decision not approved (status '{d['status']}')",
            f"{d['id']} ({d['text'][:80]}...): approve or change it, with approver and date.", "IN-07")

# R03 every requirement has an owner component
for r in h["requirements"]:
    if not r["owner"]:
        add("R03", "block", r["id"], "no owning component", f"{r['id']} {r['title']}: which class or "
            "package implements it?", "IN-01 / IN-08")
    if not r["priority"]:
        add("R03", "warn", r["id"], "priority not given", None, "IN-01")

# R04 properties have a type and width, methods a full signature
for i in h["interfaces"]:
    if i["kind"] == "property" and i["type"] not in ("logical_alu", "arithmetic_alu") and not i["width"]:
        add("R04", "block", i["id"], f"{i['name']}: no width",
            f"{i['id']} {i['name']}: give the exact data type and width in bits.", "IN-02")
    if i["kind"] == "method" and not i["signature"]:
        add("R04", "block", i["id"], f"{i['name']}: no full signature",
            f"{i['id']} {i['name']}: give the full declaration (return type, every argument with its type).", "IN-02")
    if not i["owner"]:
        add("R04", "block", i["id"], f"{i['name']}: no owner", f"{i['id']}: which class or package owns it?", "IN-02")

# R05 every operation has defined semantics and an owning unit
for o in h["operations"]:
    if not o["defined"]:
        add("R05", "block", o["id"], f"{o['name']}: result not defined",
            f"{o['id']} {o['name']} ({o['code']}): give the exact result, operand order and any flag effects, "
            "with boundary values.", "IN-04")
    if not o["unit"]:
        add("R05", "block", o["id"], f"{o['name']}: no owning unit", None, "IN-04")

# R06 enum / type definitions exist
if not h["types"]:
    add("R06", "block", "alu_op", "no type definition for the operation enum",
        "Give the enum type name, base type, every member with its value, and where it is declared.", "IN-03")

# R07 error behaviour defined (invalid opcode)
if not any("invalid" in d["text"].lower() for d in h["decisions"]):
    add("R07", "block", "invalid opcode", "behaviour for codes 4'b1110 / 4'b1111 not defined",
        "What must Calc return and report for an unsupported operation code?", "IN-05")

# R08 initial and reset state defined
if not any("initialize" in d["text"] and "=" in d["text"] for d in h["decisions"]):
    add("R08", "block", "initialize / Reset", "values after initialize() and Reset() not defined",
        "What value does every property hold after construction, initialize() and CPU.Reset()?", "IN-06")

# R09 architecture readable and consistent with requirement owners
comps = {c["name"] for c in h["architecture"]["components"]}
if not comps:
    add("R09", "block", "architecture", "no editable architecture (only " +
        ", ".join(h["architecture"]["images"]) + ")",
        "Send the architecture as an editable .puml or draw.io file (classes, extends, contains).", "IN-08")
else:
    for r in h["requirements"]:
        if r["owner"] and r["owner"] not in comps and r["owner"] != "test_program":
            add("R09", "block", r["id"], f"owner {r['owner']} is not in the architecture", None, "IN-08")
    if not h["architecture"]["editable_source"]:
        add("R09", "warn", "architecture", "no .puml/.drawio; structure read from alu_spec.json instead", None, "IN-08")

# R10 design kind and baseline
if not h["design"]["kind"]:
    add("R10", "block", "design kind", "not stated whether this is synthesizable hardware or a simulation model",
        "Is the deliverable synthesizable RTL or a simulation-only class model? Any target device?", "IN-09")
if not h["baseline"]["spec_version"]:
    add("R10", "block", "baseline", "no spec version or approval record",
        "Give the spec version, approval status, approvers, date and the Git commit of the Phase 1 files.", "IN-10")
elif not h["baseline"]["approved_by"]:
    add("R10", "condition", "baseline", f"spec version {h['baseline']['spec_version']} has no approver yet", None, "IN-10")

# R11 hardware-only inputs
if hw:
    add("R11", "block", "clock/reset", "hardware design needs clock, reset and timing (IN-11..IN-14)", None, "IN-11")

# R12 smoke vectors, coding rules
if not h["golden_vectors"]:
    add("R12", "warn", "smoke vectors", "no vectors with exact expected values; S8 cannot check results", None, "IN-16")
if not h["coding_rules"]:
    add("R12", "warn", "coding rules", "no project coding rules; S5/S6 use the assignment constraints "
        "(CA-001 one class per file, CA-008 extern optional) and Verilator/Verible defaults", None, "IN-15")

n = {s: sum(f["severity"] == s for f in F) for s in ("block", "condition", "warn")}
status = "blocked" if n["block"] else ("ready_with_conditions" if n["condition"] else "ready")
rep = {"status": status, "counts": n, "findings": F}
(out / "readiness_report.json").write_text(json.dumps(rep, indent=1, ensure_ascii=False))
if status == "blocked":
    lines = ["# Questions for Phase 1", "",
             f"Phase 2 cannot start: {n['block']} blocking findings. Please answer each question below and "
             "send the updated files (same IDs).", ""]
    by_input = {}
    for f in F:
        if f["severity"] == "block" and f["question"]:
            by_input.setdefault(f["input"], []).append(f["question"])
    for k, qs in by_input.items():
        lines += [f"## {k}", ""] + [f"{i}. {q}" for i, q in enumerate(qs, 1)] + [""]
    (out / "questions_for_phase1.md").write_text("\n".join(lines))
print(status, n)
