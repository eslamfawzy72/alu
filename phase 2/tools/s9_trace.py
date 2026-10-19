"""S9 · Trace and conformance (tools only, no LLM).

usage: python3 s9_trace.py <handoff> <design_plan_approved.json> <rtl_root> <design.xml> <out_dir>
 1 scans every "// @ID" tag -> rtl_trace.json (ID -> file, line, code)
 2 turns Verilator's parse tree into a graph: units, members, extends / contains / includes /
   calls / writes edges -> design_graph.graphml and design_graph.json (node-link)
 3 compares the code with the plan: every planned unit and member exists, nothing unplanned
 4 checks every spec ID is implemented (tagged in its owning unit) or explained (not_in_rtl)
writes: conformance_report.json, traceability.csv
"""
import csv, json, re, sys, xml.etree.ElementTree as ET
from pathlib import Path
import networkx as nx

h = json.loads(Path(sys.argv[1]).read_text())
plan = json.loads(Path(sys.argv[2]).read_text())
root, xml_p, out = Path(sys.argv[3]), Path(sys.argv[4]), Path(sys.argv[5])
out.mkdir(parents=True, exist_ok=True)
units = {u["name"]: u for u in plan["units"]}
by_file = {u["file"]: u["name"] for u in plan["units"]}

# 1 tags
trace = {}
for f in sorted((root / "rtl").iterdir()):
    for n, line in enumerate(f.read_text().splitlines(), 1):
        if "//" in line:
            for i in re.findall(r"@([A-Z]{1,3}-\d{3})", line.split("//", 1)[1]):
                trace.setdefault(i, []).append({"file": f"rtl/{f.name}", "line": n,
                                                "unit": by_file[f.name], "code": line.split("//")[0].strip()})
(out / "rtl_trace.json").write_text(json.dumps(dict(sorted(trace.items())), indent=1))

# 2 graph from the parse tree
x = ET.parse(xml_p).getroot()
g = nx.DiGraph()
code, parent, classes = {}, {}, list(x.iter("class"))
for pkg in x.iter("package"):
    if pkg.get("name") == plan["top"]:
        g.add_node(pkg.get("name"), kind="package", file=units[pkg.get("name")]["file"])
for c in classes:                                  # pass 1: units, members, hierarchy
    cn = c.get("name")
    code[cn] = {"properties": {}, "methods": set()}
    g.add_node(cn, kind="class", file=units.get(cn, {}).get("file", ""))
    g.add_edge(plan["top"], cn, rel="includes")
    e = c.find("classextends/classrefdtype")
    parent[cn] = e.get("name") if e is not None else None
    if parent[cn]:
        g.add_edge(cn, parent[cn], rel="extends")
    for v in c.findall("var"):
        code[cn]["properties"][v.get("name")] = v.get("vartype")
        g.add_node(f"{cn}.{v.get('name')}", kind="property", type=v.get("vartype"))
        g.add_edge(cn, f"{cn}.{v.get('name')}", rel="has")
        if v.get("vartype") in units:
            g.add_edge(cn, v.get("vartype"), rel="contains", name=v.get("name"))
    for fn in c.findall("func") + c.findall("task"):
        code[cn]["methods"].add(fn.get("name"))
        g.add_node(f"{cn}.{fn.get('name')}()", kind="method")
        g.add_edge(cn, f"{cn}.{fn.get('name')}()", rel="has")


def resolve(cls, name, kind):                      # walk up the hierarchy to the declaring class
    while cls:
        if name in code[cls][kind]:
            return cls
        cls = parent.get(cls)
    return None


for c in classes:                                  # pass 2: what each method writes and calls
    cn = c.get("name")
    for fn in c.findall("func") + c.findall("task"):
        node = f"{cn}.{fn.get('name')}()"
        local = {v.get("name"): v.get("vartype") for v in fn.iter("var")}
        for a in fn.iter():
            if a.tag in ("assign", "assigndly") and len(a) >= 2 and a[1].tag == "membersel":
                obj = a[1][0].get("name")           # obj.member = ...
                t = local.get(obj) or code[cn]["properties"].get(obj)
                o = resolve(t, a[1].get("name"), "properties") if t in code else None
                if o:
                    g.add_edge(node, f"{o}.{a[1].get('name')}", rel="writes", via=obj)
            elif a.tag in ("assign", "assigndly") and len(a) >= 2:
                for ref in a[1].iter("varref"):    # child[1] is the target (LHS)
                    o = resolve(cn, ref.get("name"), "properties")
                    if o and ref.get("name") not in local:
                        g.add_edge(node, f"{o}.{ref.get('name')}", rel="writes")
            if a.tag in ("funcref", "taskref"):
                # a method calling its own name is super.<name>(): start at the parent class
                start = parent.get(cn) if a.get("name") == fn.get("name") else cn
                o = resolve(start, a.get("name"), "methods")
                if o:
                    g.add_edge(node, f"{o}.{a.get('name')}()", rel="calls")
            if a.tag == "methodcall" and len(a):
                obj = a[0].get("name")
                t = local.get(obj) or code[cn]["properties"].get(obj)
                o = resolve(t, a.get("name"), "methods") if t in code else None
                if o:
                    g.add_edge(node, f"{o}.{a.get('name')}()", rel="calls", via=obj)
for i, rows in trace.items():
    g.add_node(i, kind="spec_id")
    for r in rows:
        g.add_edge(i, r["unit"], rel="implemented_in", line=f"{r['file']}:{r['line']}")
nx.write_graphml(g, out / "design_graph.graphml")
try:                                               # networkx >= 3.4
    nl = nx.node_link_data(g, edges="links")
except TypeError:                                  # older networkx (Ubuntu 24.04 ships 2.8)
    nl = nx.node_link_data(g)
(out / "design_graph.json").write_text(json.dumps(nl, indent=1))

# 3 plan vs code
mm = []
for u in plan["units"]:
    if u["kind"] != "class":
        continue
    c = code.get(u["name"])
    if not c:
        mm.append({"kind": "missing_unit", "unit": u["name"], "route": "S5"}); continue
    want_p = {p["name"] for p in u.get("properties", [])}
    want_m = {m["name"] for m in u["methods"]}
    for n in sorted(want_p - set(c["properties"])):
        mm.append({"kind": "missing_member", "unit": u["name"], "item": n, "route": "S5"})
    for n in sorted(set(c["properties"]) - want_p):
        mm.append({"kind": "unplanned_member", "unit": u["name"], "item": n, "route": "S5"})
    for n in sorted(want_m - c["methods"]):
        mm.append({"kind": "missing_member", "unit": u["name"], "item": n + "()", "route": "S5"})
    for n in sorted(c["methods"] - want_m - {"new"}):   # Verilator adds an implicit new()
        mm.append({"kind": "unplanned_member", "unit": u["name"], "item": n + "()", "route": "S5"})

# 4 ID coverage
explained = {e["id"]: e["reason"] for e in plan["not_in_rtl"]}
owner = {i: u["name"] for u in plan["units"] for i in u["owns"]}
allowed = {i: {owner[i]} | {u["name"] for u in plan["units"] if i in u["uses"]} for i in owner}
text = {}
for k in ("requirements", "interfaces", "operations", "decisions"):
    for it in h[k]:
        text[it["id"]] = it.get("title") or it.get("name") or it.get("text")
rows, n_impl, n_expl, missing = [], 0, 0, []
for i in text:
    hits = trace.get(i, [])
    if i in explained:
        st, where = "explained", explained[i]; n_expl += 1
    elif any(r["unit"] == owner.get(i) for r in hits):
        st, where = "implemented", "; ".join(f"{r['file']}:{r['line']}" for r in hits); n_impl += 1
    else:
        st, where = "missing", ""; missing.append(i)
        mm.append({"kind": "id_not_tagged" if i in owner else "id_not_owned", "item": i,
                   "unit": owner.get(i), "route": "S5" if i in owner else "S3"})
    rows.append([i, i.split("-")[0], text[i], owner.get(i, ""), st, where])
for i, hits in trace.items():
    if i not in text:
        mm.append({"kind": "tag_unknown_id", "item": i, "route": "S5", "at": hits[0]["file"]})
        continue
    for r in hits:
        if i in allowed and r["unit"] not in allowed[i]:
            mm.append({"kind": "tag_wrong_unit", "item": i, "unit": r["unit"], "route": "S5",
                       "at": f"{r['file']}:{r['line']}", "owner": owner[i]})
with open(out / "traceability.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["ID", "Kind", "Spec item", "Owner unit", "Status", "Implemented at / reason"])
    w.writerows(rows)
rep = {"conforms": not mm, "mismatches": mm, "ids_total": len(rows), "implemented": n_impl,
       "explained": n_expl, "missing": missing,
       "graph": {"nodes": g.number_of_nodes(), "edges": g.number_of_edges(),
                 "edge_kinds": sorted({d["rel"] for _, _, d in g.edges(data=True)})},
       "tag_lines": sum(len(v) for v in trace.values())}
(out / "conformance_report.json").write_text(json.dumps(rep, indent=1))
print("conforms" if rep["conforms"] else "MISMATCH", n_impl, n_expl, missing, rep["graph"], len(mm))
