"""Plan rules (deterministic, no LLM). Used by S3 as a self-check and by S4 as the automatic gate.

usage: python3 check_plan.py <phase1_handoff.json> <design_plan_vN.json> <out_dir>
writes: <out_dir>/plan_vN_validation.json  pass/fail per rule with findings
        <out_dir>/design_plan_vN.mmd       Mermaid class diagram drawn from the plan
"""
import json, re, sys
from pathlib import Path

h = json.loads(Path(sys.argv[1]).read_text())
plan = json.loads(Path(sys.argv[2]).read_text())
out = Path(sys.argv[3]); out.mkdir(parents=True, exist_ok=True)
v = plan["plan_version"]
units = {u["name"]: u for u in plan["units"]}
R = {}


def rule(rid, title):
    R[rid] = {"title": title, "errors": [], "warnings": []}
    return R[rid]


def norm(sig):
    return re.sub(r"\s+", " ", sig.replace("virtual ", "")).strip()


# P01 ownership
r = rule("P01", "every spec ID is owned by exactly one unit or explained in not_in_rtl")
spec_ids = [x["id"] for k in ("requirements", "interfaces", "operations", "decisions") for x in h[k]]
owned = {}
for u in plan["units"]:
    for i in u["owns"]:
        owned.setdefault(i, []).append(u["name"])
explained = {e["id"] for e in plan["not_in_rtl"]}
for i in spec_ids:
    n = len(owned.get(i, [])) + (i in explained)
    if n == 0:
        r["errors"].append(f"{i} has no owner and no explanation")
    elif n > 1:
        r["errors"].append(f"{i} owned more than once: {owned.get(i)} {'+ not_in_rtl' if i in explained else ''}")
for i in set(owned) - set(spec_ids):
    r["errors"].append(f"{i} owned in the plan but not in the spec")
for u in plan["units"]:
    for i in u["uses"]:
        if i not in spec_ids:
            r["errors"].append(f"{u['name']} uses unknown ID {i}")

# P02 interfaces match the spec
r = rule("P02", "every spec interface appears with the same name, owner, type or signature")
for i in h["interfaces"]:
    u = units.get(i["owner"])
    if not u:
        r["errors"].append(f"{i['id']}: owner {i['owner']} not in plan"); continue
    if i["kind"] == "property":
        p = next((p for p in u.get("properties", []) if p["name"] == i["name"]), None)
        if not p:
            r["errors"].append(f"{i['id']} {i['name']} missing from {u['name']}")
        elif not (i["type"] or "").startswith(p["type"]):
            r["errors"].append(f"{i['id']} {i['name']}: spec type '{i['type']}', plan '{p['type']}'")
        elif p.get("width") != i["width"] and i["width"]:
            r["errors"].append(f"{i['id']} {i['name']}: spec width {i['width']}, plan {p.get('width')}")
    elif i["kind"] == "method":
        m = next((m for m in u["methods"] if m["name"] == i["name"]), None)
        if not m:
            r["errors"].append(f"{i['id']} {i['name']} missing from {u['name']}")
        elif norm(m["signature"]) != norm(i["signature"]):
            r["errors"].append(f"{i['id']}: spec '{i['signature']}', plan '{m['signature']}'")
        elif m["signature"] != i["signature"]:
            r["warnings"].append(f"{i['id']} {i['name']}: plan adds 'virtual' ({m['signature']}); "
                                 "the call interface is unchanged")
    elif i["kind"] == "type":
        if not any(t["name"] == "alu_op_t" for t in u.get("types", [])):
            r["errors"].append(f"{i['id']}: enum not declared in {u['name']}")

# P03 every operation implemented in the unit the spec names, with its enum value
r = rule("P03", "every operation has a datapath entry in its spec unit; enum values match")
enum = {m["name"]: m["value"] for t in h["types"] for m in t["members"]}
penum = units["cpu_pkg"]["types"][0]["members"]
if penum != enum:
    r["errors"].append(f"enum members differ from spec: {set(penum.items()) ^ set(enum.items())}")
for o in h["operations"]:
    u = units.get(o["unit"])
    if not u or not any(d["op"] == o["id"] for d in u.get("datapath", [])):
        r["errors"].append(f"{o['id']} not in the datapath of {o['unit']}")

# P04 every referenced type is defined
r = rule("P04", "every type used is defined (built-in, enum, or a planned class)")
known = {"int", "bit", "string", "int unsigned", "logic [32:0]"} | set(units) | set(penum.keys()) | {"alu_op_t"}
for u in plan["units"]:
    for p in u.get("properties", []) + u.get("locals", []):
        if p["type"] not in known:
            r["errors"].append(f"{u['name']}.{p['name']}: unknown type {p['type']}")

# P05 hierarchy, include order and build order
r = rule("P05", "extends targets exist and are built first; package includes follow the build order")
order = plan["build_order"]
for u in plan["units"]:
    if u.get("extends"):
        if u["extends"] not in units:
            r["errors"].append(f"{u['name']} extends unknown {u['extends']}")
        elif order.index(u["extends"]) > order.index(u["name"]):
            r["errors"].append(f"{u['name']} built before its base {u['extends']}")
    for p in u.get("properties", []):
        if p["type"] in units and order.index(p["type"]) > order.index(u["name"]):
            r["errors"].append(f"{u['name']} uses {p['type']} before it is built")
inc = units["cpu_pkg"]["includes"]
files = [units[n]["file"] for n in order[1:]]
if inc != files:
    r["errors"].append(f"includes {inc} do not follow build order {files}")
rel = {(x["from"], x["to"], x["type"]) for x in h["architecture"]["relations"]}
for x in rel:
    if x[2] == "extends" and units.get(x[0], {}).get("extends") != x[1]:
        r["errors"].append(f"architecture says {x[0]} extends {x[1]}; plan disagrees")

# P06 nothing beyond the spec unless flagged
r = rule("P06", "every member not in the spec overrides a spec member or is listed in added_elements")
spec_members = {(i["owner"], i["name"]) for i in h["interfaces"]}
for c in h["classes"]:
    for m in c.get("methods", []):
        spec_members.add((c["name"], re.search(r"(\w+)\(", m["sig"]).group(1)))
    for p in c.get("extra_properties", []):
        spec_members.add((c["name"], p["name"]))
added = " ".join(a["name"] + " " + a["unit"] for a in plan["added_elements"])


def inherited(u, name):
    b = u.get("extends")
    while b:
        if (b, name) in spec_members or any(m["name"] == name for m in units[b]["methods"]):
            return True
        b = units[b].get("extends")
    return False


for u in plan["units"]:
    for m in u.get("methods", []) + u.get("properties", []):
        n = m["name"]
        if (u["name"], n) in spec_members or n == "new" or inherited(u, n):
            continue
        if f"{n}()" in added or n in added:
            continue
        r["errors"].append(f"{u['name']}.{n} is not in the spec and not flagged as added")
for a in plan["added_elements"]:
    r["warnings"].append(f"added element for the reviewer: {a['name']} in {a['unit']} ({a['why']})")

# P07 one unit per file
r = rule("P07", "one unit per file, file names unique")
fs = [u["file"] for u in plan["units"]]
for f in set(fs):
    if fs.count(f) > 1:
        r["errors"].append(f"{f} holds more than one unit")
for u in plan["units"]:
    if u["file"].rsplit(".", 1)[0] != u["name"]:
        r["warnings"].append(f"{u['file']}: file name differs from unit name {u['name']} "
                             "(taken from D-014; lint may flag it)")

# P08 initial values
r = rule("P08", "every stored property has a value after initialize() (IN-06)")
for u in plan["units"]:
    for p in u.get("properties", []):
        if p["type"] not in units and "after_initialize" not in p:
            r["errors"].append(f"{u['name']}.{p['name']} has no value after initialize()")

# P09 control covers every 4-bit code
r = rule("P09", "CPU.Calc routes every 4-bit code: 14 valid to one ALU each, the rest to the error path")
ar = [int(v.split("b")[1], 2) for k, v in penum.items() if units["arithmetic_alu"] and
      any(d["enum"] == k for d in units["arithmetic_alu"]["datapath"])]
lo = [int(v.split("b")[1], 2) for k, v in penum.items() if any(d["enum"] == k for d in units["logical_alu"]["datapath"])]
if sorted(ar) != list(range(0, 7)) or sorted(lo) != list(range(7, 14)):
    r["errors"].append(f"code ranges not contiguous: arithmetic {sorted(ar)}, logical {sorted(lo)}")
if not any("other" in c["when"] for c in units["CPU"]["control"]):
    r["errors"].append("no branch for invalid codes")

ok = not any(x["errors"] for x in R.values())
rep = {"plan_version": v, "result": "pass" if ok else "fail",
       "ids_in_spec": len(spec_ids), "ids_owned": len(owned), "ids_explained": len(explained), "rules": R}
(out / f"plan_v{v}_validation.json").write_text(json.dumps(rep, indent=1, ensure_ascii=False))

# Mermaid class diagram straight from the plan
L = ["classDiagram"]
for u in plan["units"]:
    if u["kind"] != "class":
        continue
    L.append(f"  class {u['name']} {{")
    for p in u.get("properties", []):
        L.append(f"    +{p['type']} {p['name']}")
    for m in u["methods"]:
        if m["name"] != "new":
            L.append(f"    +{m['name']}()")
    L.append("  }")
for u in plan["units"]:
    if u.get("extends"):
        L.append(f"  {u['extends']} <|-- {u['name']}")
    for p in u.get("properties", []):
        if p["type"] in units:
            L.append(f"  {u['name']} *-- {p['type']} : {p['name']}")
L.append(f"  note for CPU \"all classes are included in cpu_pkg (cpu_pkg.sv) with alu_op_t\"")
(out / f"design_plan_v{v}.mmd").write_text("\n".join(L) + "\n")
print(rep["result"], {k: (len(x["errors"]), len(x["warnings"])) for k, x in R.items()})
