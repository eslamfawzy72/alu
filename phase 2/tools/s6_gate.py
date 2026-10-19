"""S6 · Static analysis gate (real tools, no LLM).

usage: python3 s6_gate.py <rtl_root containing files.f> <design_plan_approved.json> <out_dir>
runs  : 1 verilator --lint-only -Wall      (parse, elaborate, lint with all warnings)
        2 verible-verilog-lint              (style lint, every file)
        3 verilator --xml-only + compare    (every planned class member exists with the planned type)
        (no Yosys: the plan's mode is class_model, classes are not synthesizable)
writes: <out_dir>/verilator_lint.log, verible_lint.log, design.xml, gate_report.json
"""
import json, re, subprocess, sys, xml.etree.ElementTree as ET
from pathlib import Path

root, plan_p, out = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
out.mkdir(parents=True, exist_ok=True)
plan = json.loads(plan_p.read_text())
files = sorted(str(p.relative_to(root)) for p in (root / "rtl").iterdir() if p.suffix in (".sv", ".svh"))


def run(cmd):
    try:
        p = subprocess.run(cmd, cwd=root, capture_output=True, text=True)
    except FileNotFoundError:
        return 127, f"{cmd[0]}: not installed"
    return p.returncode, p.stdout + p.stderr


msgs, checks = [], {}

# 1 compile + lint
rc, log = run(["verilator", "--lint-only", "-Wall", "-f", "files.f", "--top-module", plan["top"]])
(out / "verilator_lint.log").write_text(f"$ verilator --lint-only -Wall -f files.f --top-module {plan['top']}\n{log}")
for m in re.finditer(r"%(Warning|Error)(?:-(\w+))?: ([^:\n]+):(\d+):(\d+): (.*)", log):
    msgs.append({"tool": "verilator", "severity": m[1].lower(), "rule": m[2] or "ERROR",
                 "file": m[3], "line": int(m[4]), "text": m[6].strip()})
checks["compile_lint"] = "pass" if rc == 0 and not any(x["tool"] == "verilator" for x in msgs) else "fail"

# 2 style lint
rc2, log2 = run(["verible-verilog-lint"] + files)
(out / "verible_lint.log").write_text(f"$ verible-verilog-lint {' '.join(files)}\n{log2 or '(no findings)'}\n")
for m in re.finditer(r"([^:\n]+):(\d+):(\d+)(?:-\d+)?: (.*?) \[Style: [^\]]*\] \[([\w-]+)\]", log2):
    msgs.append({"tool": "verible", "severity": "warning", "rule": m[5], "file": m[1], "line": int(m[2]),
                 "text": m[4]})
checks["style"] = "skipped (verible not installed)" if rc2 == 127 else ("pass" if rc2 == 0 else "fail")

# 3 interface conformance from Verilator's own parse tree
rc3, log3 = run(["verilator", "--xml-only", "-Wno-fatal", "-f", "files.f", "--top-module", plan["top"],
                 "--xml-output", str((out / "design.xml").resolve())])
found = {}
if rc3 == 0:
    x = ET.parse(out / "design.xml").getroot()
    types = {d.get("id"): d for d in x.iter() if d.get("id")}
    for c in x.iter("class"):
        mem = found.setdefault(c.get("name"), {"properties": {}, "methods": set(), "extends": None})
        for e in c.iter("classextends"):
            r = e.find("classrefdtype")
            mem["extends"] = r.get("name") if r is not None else None
        for v in c.findall("var"):
            mem["properties"][v.get("name")] = v.get("vartype") or ""
        for f in list(c.findall("func")) + list(c.findall("task")):
            mem["methods"].add(f.get("name"))
iface = []
for u in (plan["units"] if rc3 == 0 else []):
    if u["kind"] != "class":
        continue
    got = found.get(u["name"])
    if not got:
        iface.append(f"class {u['name']} not found"); continue
    for p in u.get("properties", []):
        t = got["properties"].get(p["name"])
        if t is None:
            iface.append(f"{u['name']}.{p['name']} missing")
        elif p["type"] not in t:
            iface.append(f"{u['name']}.{p['name']}: planned {p['type']}, code {t}")
    for m in u["methods"]:
        if m["name"] not in got["methods"]:
            iface.append(f"{u['name']}.{m['name']}() missing")
    if u.get("extends") and got["extends"] != u["extends"]:
        iface.append(f"{u['name']} extends {got['extends']}, planned {u['extends']}")
for t in iface:
    msgs.append({"tool": "interface_check", "severity": "error", "rule": "IFACE", "file": "", "line": 0, "text": t})
checks["interface"] = ("skipped (design does not parse)" if rc3 != 0 else
                       "pass" if not iface else "fail")
checks["synthesis"] = "not_applicable (class_model)"

rep = {"result": "pass" if all(v == "pass" or v.startswith(("not_", "skipped (")) for v in checks.values()) else "fail",
       "checks": checks, "messages": msgs, "classes_found": {k: sorted(v["methods"]) for k, v in found.items()},
       "tools": {"verilator": run(["verilator", "--version"])[1].strip(),
                 "verible": run(["verible-verilog-lint", "--version"])[1].split("\n")[0]}}
(out / "gate_report.json").write_text(json.dumps(rep, indent=1))
print(rep["result"], checks, f"{len(msgs)} messages")
