"""Watch the RTL and re-run the Phase 2 checks every time a file is saved.

usage (from the Phase2_ALU_Output folder):
    python3 tools/watch.py            # watch until Ctrl+C
    python3 tools/watch.py --once     # run the checks once and exit

On every save in S5_rtl/rtl/ it:
  1 CHANGE   diffs the file against the Git baseline and lists the spec IDs the change touches
  2 S6 GATE  Verilator -Wall lint, Verible (if installed), interface check against the plan
  3 S7       if the gate fails: classifies each message (local / structural) and says where it goes
  4 S8 SMOKE if the gate passes: rebuilds and runs the smoke test (91 checks)
  5 S9 TRACE if the smoke passes: every spec ID still tagged in its owning unit
Results go to watch_out/ ; the baseline evidence in S6_gate/ ... S9_trace/ is never overwritten.
No LLM is called and no file is changed.
"""
import difflib, json, re, shutil, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RTL = ROOT / "S5_rtl" / "rtl"
OUT = ROOT / "watch_out"
PLAN = ROOT / "S4_review" / "design_plan_approved.json"
H = ROOT / "S1_intake" / "run2_answered" / "phase1_handoff.json"
TAG = "phase2-baseline-s1.1-proposed-p2"
G, R, Y, D, B = "\033[32m", "\033[31m", "\033[33m", "\033[2m", "\033[1m"
X = "\033[0m"


def sh(cmd):
    try:
        p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
        return p.returncode, p.stdout + p.stderr
    except FileNotFoundError:
        return 127, ""


def baseline(name):
    rc, txt = sh(["git", "show", f"{TAG}:S5_rtl/rtl/{name}"])
    return txt if rc == 0 else None


def tags(line):
    return re.findall(r"@([A-Z]{1,3}-\d{3})", line.split("//", 1)[1]) if "//" in line else []


def touched_ids(old, new):
    """IDs on changed lines, plus the IDs of the method or class that encloses each change."""
    o, n = old.splitlines(), new.splitlines()
    ids, lines = set(), []
    for op, i1, i2, j1, j2 in difflib.SequenceMatcher(None, o, n).get_opcodes():
        if op == "equal":
            continue
        for k in range(i1, i2):
            ids |= set(tags(o[k]))
        for k in range(j1, j2):
            ids |= set(tags(n[k]))
            lines.append(k + 1)
        k = min(j1, len(n) - 1)
        while k >= 0:                       # walk up to the enclosing function/task/class header
            if re.match(r"\s*(virtual\s+)?(function|task|class)\b", n[k]):
                ids |= set(tags(n[k]))
                break
            k -= 1
    return sorted(ids), lines


def text_of(i):
    h = json.loads(H.read_text())
    for k in ("requirements", "interfaces", "operations", "decisions"):
        for x in h[k]:
            if x["id"] == i:
                return (x.get("title") or x.get("name") or x.get("result") or x.get("text"))[:70]
    return ""


def check(changed, first=False):
    t0 = time.time()
    print(f"\n{B}=== {'initial check' if first else 'change detected'}: {', '.join(changed)} ({time.strftime('%H:%M:%S')}) ==={X}")
    # 1 change impact
    for f in changed:
        old = baseline(f)
        new = (RTL / f).read_text() if (RTL / f).exists() else ""
        if old is None:
            print(f"  {f}: no Git baseline to compare with")
            continue
        if old == new:
            print(f"  {f}: same as the baseline")
            continue
        ids, lines = touched_ids(old, new)
        print(f"  {f}: lines {lines[:8]}{' ...' if len(lines) > 8 else ''} differ from the baseline")
        for i in ids:
            print(f"    touches {i:7} {D}{text_of(i)}{X}")
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir()
    # 2 S6
    sh([sys.executable, "tools/s6_gate.py", "S5_rtl", str(PLAN), "watch_out/S6_round1"])
    gate = json.loads((OUT / "S6_round1" / "gate_report.json").read_text())
    print(f"  S6 gate   : " + "  ".join(f"{k}={v.split(' ')[0]}" for k, v in gate["checks"].items()))
    if gate["result"] != "pass":
        for m in gate["messages"]:
            print(f"    {R}{m['tool']} {m['rule']}{X} {m['file']}:{m['line']} {m['text']}")
        if not gate["messages"]:
            print(f"    {R}{(OUT / 'S6_round1' / 'verilator_lint.log').read_text().strip()[-400:]}{X}")
        # 3 S7
        sh([sys.executable, "tools/s7_classify.py", "watch_out/S6_round1/gate_report.json", str(PLAN), str(H),
            "watch_out/S7_round1/classification.json"])
        cp = OUT / "S7_round1" / "classification.json"
        if cp.exists():
            c = json.loads(cp.read_text())
            for x in c["classified"]:
                print(f"  S7        : {x['message']['rule']} is {x['cls']} -> {x['route']}"
                      f"{' (' + x.get('fix', '') + ')' if x.get('fix') else ''}")
        print(f"{R}{B}  RESULT: FAIL at S6{X} ({time.time() - t0:.0f}s) - smoke and trace not run")
        return
    # 4 S8
    sh([sys.executable, "tools/s8_smoke.py", str(H), "S5_rtl", "watch_out/S8"])
    sm = json.loads((OUT / "S8" / "smoke_result.json").read_text())
    if not sm["built"]:
        print(f"  S8 smoke  : {R}build failed{X}, see watch_out/S8/build.log")
        print(f"{R}{B}  RESULT: FAIL at S8{X}"); return
    print(f"  S8 smoke  : {sm['summary']}  ($error lines: {sm['errors_reported']}, expected 2)")
    for line in (OUT / "S8" / "smoke_log.txt").read_text().splitlines():
        if line.startswith("FAIL"):
            print(f"    {R}{line}{X}")
    if sm["result"] != "pass":
        print(f"{R}{B}  RESULT: FAIL at S8{X} ({time.time() - t0:.0f}s)"); return
    # 5 S9
    try:
        import networkx  # noqa: F401
    except ImportError:
        print(f"  S9 trace  : {Y}skipped (sudo apt-get install python3-networkx){X}")
        print(f"{G}{B}  RESULT: PASS{X} through S8 ({time.time() - t0:.0f}s)"); return
    rc, log = sh([sys.executable, "tools/s9_trace.py", str(H), str(PLAN), "S5_rtl",
                  "watch_out/S6_round1/design.xml", "watch_out/S9"])
    if not (OUT / "S9" / "conformance_report.json").exists():
        print(f"  S9 trace  : {R}tool error{X}\n{D}{log.strip()[-600:]}{X}")
        print(f"{Y}{B}  RESULT: PASS through S8, S9 did not run{X}"); return
    cf = json.loads((OUT / "S9" / "conformance_report.json").read_text())
    print(f"  S9 trace  : {cf['implemented']} implemented, {cf['explained']} explained, "
          f"{len(cf['missing'])} missing, {len(cf['mismatches'])} mismatches")
    for m in cf["mismatches"]:
        print(f"    {R}{m['kind']}{X} {m.get('item')} in {m.get('unit')} -> route {m['route']}")
    ok = cf["conforms"]
    print(f"{(G if ok else R)}{B}  RESULT: {'PASS' if ok else 'FAIL at S9'}{X} ({time.time() - t0:.0f}s)")


def snapshot():
    return {p.name: p.stat().st_mtime for p in RTL.iterdir() if p.suffix in (".sv", ".svh")}


if __name__ == "__main__":
    if shutil.which("verilator") is None:
        sys.exit("verilator not found: sudo apt-get install verilator g++ make")
    seen = snapshot()
    check(sorted(seen), first=True)
    if "--once" in sys.argv:
        sys.exit(0)
    print(f"\n{D}watching {RTL.relative_to(ROOT)}/ - save a file to re-run, Ctrl+C to stop{X}")
    try:
        while True:
            time.sleep(1)
            now = snapshot()
            changed = sorted(f for f in now if now[f] != seen.get(f)) + sorted(set(seen) - set(now))
            if changed:
                time.sleep(0.5)            # let the editor finish writing
                seen = snapshot()
                check(changed)
                print(f"\n{D}watching ... (Ctrl+C to stop){X}")
    except KeyboardInterrupt:
        print("\nstopped")
