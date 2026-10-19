"""S1 · Intake and normalization (deterministic, no LLM).

Reads a Phase 1 output folder (CSV tables, optional alu_spec.json, decisions, golden vectors,
diagram files) and writes one normalized handoff plus a parse log.

usage: python3 s1_normalize.py <phase1_folder> <out_dir>
writes: <out_dir>/phase1_handoff.json   normalized spec, every item keyed by its Phase 1 ID
        <out_dir>/s1_parse_log.json     files read, rows loaded, problems found while parsing
"""
import csv, hashlib, json, re, sys
from pathlib import Path

src, out = Path(sys.argv[1]), Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
log = {"phase1_folder": src.name, "files": [], "problems": []}
UNSPEC = re.compile(r"not (fully |explicitly )?specified|not detailed|not defined|require[s]? clarification",
                    re.I)


def table(name):
    p = src / name
    if not p.exists():
        log["files"].append({"file": name, "status": "missing"})
        return []
    rows = list(csv.DictReader(p.open(encoding="utf-8-sig")))
    log["files"].append({"file": name, "status": "read", "rows": len(rows),
                         "sha256": hashlib.sha256(p.read_bytes()).hexdigest()[:12]})
    return rows


def val(s):
    """Phase 1 writes 'Not specified' into typed columns; store that as null, keep the text."""
    s = (s or "").strip()
    return None if not s or s.lower().startswith("not specified") or s.lower() == "not applicable" else s


def ids(s):
    return re.findall(r"[A-Z]{1,3}-\d{3}", s or "")


spec = json.loads((src / "alu_spec.json").read_text()) if (src / "alu_spec.json").exists() else None
if spec:
    log["files"].append({"file": "alu_spec.json", "status": "read"})

# IN-01 requirements (+ IN-18 links from the verification table)
tests = table("ALU_Verification_Requirements.csv")
verified = {}
for t in tests:
    for i in ids(t["Related requirement IDs"]):
        verified.setdefault(i, []).append(t["Test ID"])
reqs = []
for r in table("ALU_Functional_Requirements.csv"):
    reqs.append({"id": r["Requirement ID"], "title": r["Requirement title"],
                 "text": r["Requirement description"], "expected": r["Expected behavior"],
                 "priority": val(r["Priority"]), "source": r["Source / status"],
                 "unspecified_parts": bool(UNSPEC.search(r["Expected behavior"] + r["Postconditions"])),
                 "verified_by": verified.get(r["Requirement ID"], [])})

# owners of each requirement, from the machine-readable spec when Phase 1 gave one
owner_of_req, owner_of_if = {}, {}
if spec:
    for c in spec["classes"]:
        for i in c.get("req", []):
            owner_of_req[i] = c["name"]
        for p in c.get("properties", []) + c.get("extra_properties", []):
            if p.get("if"):
                owner_of_if[p["if"]] = c["name"]
        for m in c.get("methods", []):
            for i in ([m["req"]] if isinstance(m.get("req"), str) else m.get("req", [])):
                owner_of_req[i] = c["name"]
    owner_of_req["FR-011"] = owner_of_req["FR-012"] = spec["package"]["name"]
    owner_of_req.setdefault("FR-013", "test_program")
for r in reqs:
    r["owner"] = owner_of_req.get(r["id"])

# IN-02 interfaces
ifs = []
for r in table("ALU_Interfaces_and_Signals.csv"):
    kind = r["Interface type"].lower()
    k = ("method" if "method" in kind else "package" if "package" in kind else
         "type" if "operation-code" in kind else "property")
    dt = r["Data type"]
    sig = re.sub(r"\s+-\s+D-\d+$", "", dt) if dt.strip().startswith(("function", "virtual")) else None
    width = re.search(r"(\d+)", r["Width"] or "")
    owner = owner_of_if.get(r["Interface ID"]) or (spec["package"]["name"] if spec and k == "type" else None)
    if not owner:
        sc = r["Source component"].split("(")[0].strip()
        owner = sc if re.fullmatch(r"[A-Za-z_]\w*", sc) and sc != "Caller" else (
            r["Destination component"].split(";")[0].strip()
            if re.fullmatch(r"[A-Za-z_]\w*", r["Destination component"].split(";")[0].strip()) else None)
    ifs.append({"id": r["Interface ID"], "name": r["Interface name"], "kind": k,
                "type": None if sig else val(re.sub(r"\s+-\s+D-\d+$", "", dt)),
                "signature": sig, "width": int(width.group(1)) if width and k in ("property", "type") else None,
                "owner": owner, "added": "added" in kind,
                "constraints": r["Constraints"]})
    if k == "method" and not sig:
        log["problems"].append(f"{r['Interface ID']} {r['Interface name']}: no method signature ('{dt}')")
    if k == "property" and ifs[-1]["width"] is None and dt not in ("logical_alu", "arithmetic_alu"):
        log["problems"].append(f"{r['Interface ID']} {r['Interface name']}: no width ('{r['Width']}')")

# IN-04 operations
ops = []
unit_of_op = {o["id"]: o["alu"] + "_alu" for o in spec["operations"]} if spec else {}
for r in table("ALU_Operation_Behavior_Table.csv"):
    sem = r["Expected result"]
    ops.append({"id": r["Operation ID"], "name": r["Operation name"], "code": r["Operation code"],
                "inputs": r["Inputs"], "result": re.sub(r"\s*\(proposed[^)]*\)", "", sem),
                "special": r["Special conditions"], "exceptions": r["Exceptions"],
                "unit": unit_of_op.get(r["Operation ID"]),
                "defined": not UNSPEC.search(sem + r["Inputs"])})
    if UNSPEC.search(sem + r["Inputs"]):
        log["problems"].append(f"{r['Operation ID']} {r['Operation name']}: result not defined ('{sem[:70]}')")

# IN-07 open questions and decisions
qs = [{"id": r["Question ID"], "question": r["Question"], "status": r["Status"],
       "answer": r["Answer / resolution"]} for r in table("ALU_Open_Questions.csv")]
decs = [{"id": r["Decision ID"], "resolves": r["Resolves question"], "text": r["Proposed decision"],
         "status": r["Status"], "approved_by": val(r["Approved by"]), "date": val(r["Date"])}
        for r in table("ALU_Design_Decisions.csv")]

cons = [{"id": r["Item ID"], "category": r["Category"], "text": r["Description"],
         "status": r["Approval status"]} for r in table("ALU_Constraints_and_Assumptions.csv")]

# IN-16 smoke / golden vectors
vecs = []
for r in table("ALU_Golden_Vectors.csv"):
    vecs.append({"id": f"GV-{int(r['Vector #']):02d}", "op": r["Operation"], "a": int(r["A"]),
                 "b": int(r["B"]), "carry_in": int(r["Carry in"]), "expect": int(r["Expected result"]),
                 "expect_carry": None if r["Expected carry"] == "unchanged" else int(r["Expected carry"]),
                 "note": r["Note"]})

# IN-08 architecture: only an editable source can be parsed; images are recorded, not read
arch = {"editable_source": None, "images": [p.name for p in src.iterdir() if p.suffix in (".png", ".jpg")],
        "components": [], "relations": []}
for p in src.iterdir():
    if p.suffix in (".puml", ".drawio"):
        arch["editable_source"] = p.name
if spec:                                    # the spec's class list is a parseable architecture
    arch["derived_from"] = "alu_spec.json classes + package"
    arch["components"] = [{"name": spec["package"]["name"], "kind": "package"}] + [
        {"name": c["name"], "kind": "class", "file": c["file"]} for c in spec["classes"]]
    by_file = {c["file"]: c["name"] for c in spec["classes"]}
    arch["relations"] = [{"from": spec["package"]["name"], "to": by_file.get(f, f), "type": "includes",
                          "file": f} for f in spec["package"]["includes_in_order"]]
    arch["relations"] += [{"from": c["name"], "to": c["extends"], "type": "extends"}
                          for c in spec["classes"] if c.get("extends")]
    arch["relations"] += [{"from": c["name"], "to": p["type"], "type": "contains", "as": p["name"]}
                          for c in spec["classes"] for p in c.get("properties", [])
                          if p["type"] in [x["name"] for x in spec["classes"]]]
elif not arch["editable_source"]:
    log["problems"].append(f"architecture is only an image ({', '.join(arch['images'])}); "
                           "no component or relation can be read from it")

handoff = {
    "baseline": {"project": "ALU class hierarchy and CPU integration",
                 "spec_version": spec["spec_version"] if spec else None,
                 "status": spec["status_note"] if spec else None, "approved_by": None, "commit": None},
    "design": {"kind": spec["design_kind"] if spec else None,
               "package": spec["package"] if spec else None},
    "requirements": reqs, "interfaces": ifs,
    "types": spec["types"] if spec else [],
    "data_semantics": spec["data_semantics"] if spec else None,
    "operations": ops, "constraints": cons,
    "open_questions": qs, "decisions": decs,
    "classes": spec["classes"] if spec else [],
    "architecture": arch,
    "verification": [{"id": t["Test ID"], "covers": ids(t["Related requirement IDs"]),
                      "objective": t["Test objective"]} for t in tests],
    "golden_vectors": vecs,
    "test_program": spec["test_program"] if spec else None,
    "tool_gate": spec["tool_gate"] if spec else None,
    "coding_rules": None, "existing_rtl": [],
}
log["loaded"] = {k: len(v) for k, v in handoff.items() if isinstance(v, list)}
(out / "phase1_handoff.json").write_text(json.dumps(handoff, indent=1, ensure_ascii=False))
(out / "s1_parse_log.json").write_text(json.dumps(log, indent=1, ensure_ascii=False))
print(json.dumps(log["loaded"]), f"{len(log['problems'])} problems")
