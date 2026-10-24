#!/usr/bin/env python3
"""Phase 7: requirement coverage of one Phase 6 regression.

Joins, for every Phase 1 ID (FR, IF, OP, D, TC):
  - the tests that check it: TC -> FR from phase 1/ALU_Verification_Requirements.csv,
    OP/D/IF -> TC and "Not tested? reason" from phase 3/test_map.csv
  - where the RTL implements it: owner file from phase 2/02_requirements/requirements_map.csv
    and every "// @ID" tag in phase 2/04_rtl/rtl/
  - the result of each test in the Phase 6 run (test_report.txt)
  - approved exclusions from phase 7/exclusions.md (rows with a reviewer and a date)
and gives each ID a status: covered, partial, excluded, failing, not run, not covered, not mapped.

usage: python3 trace_requirements.py "../phase 6/results/<run>"
       -> results/<run>/requirement_coverage.csv, results/<run>/requirement_summary.txt
exit:  0 when every ID is covered or excluded, 1 otherwise
"""
import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
KINDS = ["FR", "IF", "OP", "D", "TC"]
DONE = ("covered", "excluded")


def rows(path):
    with open(path, encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def ids(text, prefix):
    return re.findall(rf"\b{prefix}-\d+\b", text or "")


def short(text, n=70):
    text = " ".join((text or "").split())
    return text if len(text) <= n else text[: n - 3] + "..."


def approved_exclusions(path):
    """{ID: reason} for exclusions.md table rows whose Reviewer and Date are filled in."""
    out = {}
    if not path.exists():
        return out
    header = None
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            header = None
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if header is None:
            header = [c.lower() for c in cells]
            continue
        if set(line) <= set("|-: "):
            continue
        row = dict(zip(header, cells))
        if row.get("reviewer") and row.get("date") and row.get("status", "").lower() == "approved":
            for i in re.findall(r"\b(?:FR|IF|OP|D|TC)-\d+\b", row.get("id", "")):
                out[i] = row.get("reason", "")
    return out


def main():
    if len(sys.argv) != 2 or not Path(sys.argv[1]).is_dir():
        sys.exit('usage: python3 trace_requirements.py "../phase 6/results/<run>"')
    run = Path(sys.argv[1]).resolve()
    report = run / "test_report.txt"
    if not report.exists():
        sys.exit(f"no test_report.txt in {run}")

    # TC results of the Phase 6 run: "TC-013   PASS   20/20   pass=... fail=..."
    result = {}
    for line in report.read_text(encoding="utf-8").splitlines():
        m = re.match(r"(TC-\d+)\s+(\S+)\s+(\S+)", line)
        if m:
            result[m[1]] = f"{m[2]} {m[3]}"

    p1 = ROOT / "phase 1"
    items = []  # (id, kind, title)
    for r in rows(p1 / "ALU_Functional_Requirements.csv"):
        items.append((r["Requirement ID"], "FR", r["Requirement title"]))
    for r in rows(p1 / "ALU_Interfaces_and_Signals.csv"):
        items.append((r["Interface ID"], "IF", r["Interface name"]))
    for r in rows(p1 / "ALU_Operation_Behavior_Table.csv"):
        items.append((r["Operation ID"], "OP", r["Operation name"]))
    for r in rows(p1 / "ALU_Design_Decisions.csv"):
        items.append((r["Decision ID"], "D", r["Proposed decision"]))
    vreq = rows(p1 / "ALU_Verification_Requirements.csv")
    for r in vreq:
        items.append((r["Test ID"], "TC", r["Test objective"]))
    tc_fr = {r["Test ID"]: ids(r["Related requirement IDs"], "FR") for r in vreq}

    tmap = {r["ID"]: r for r in rows(ROOT / "phase 3" / "test_map.csv")}
    owner = {r["ID"]: r["Owner file (you decide in step 3)"]
             for r in rows(ROOT / "phase 2" / "02_requirements" / "requirements_map.csv")}
    tags = defaultdict(list)
    for f in sorted((ROOT / "phase 2" / "04_rtl" / "rtl").iterdir()):
        for n, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            for t in re.findall(r"@((?:FR|IF|OP|D|TC)-\d+)", line):
                tags[t].append(f"{f.name}:{n}")
    excl = approved_exclusions(HERE / "exclusions.md")

    def tc_status(tc):
        res = result.get(tc)
        if res is None:
            return "not run"
        if not res.startswith("PASS"):
            return "failing"
        reason = tmap.get(tc, {}).get("Not tested? reason", "")
        return "partial" if reason.startswith("Partly") else "covered"

    out_rows = []
    for i, kind, title in items:
        mrow = tmap.get(i)
        reason = (mrow or {}).get("Not tested? reason", "").strip()
        if kind == "TC":
            tests = [i]
        elif kind == "FR":
            tests = [tc for tc, frs in tc_fr.items() if i in frs]
        else:
            tests = ids((mrow or {}).get("Related Phase 1 IDs", ""), "TC")
        states = {tc: tc_status(tc) for tc in tests}
        note = reason

        if i in excl:
            status, note = "excluded", "approved exclusion: " + excl[i]
        elif kind == "TC":
            status = states[i]
        elif mrow is None and not tests:
            status = "not mapped"
            note = "no row in phase 3/test_map.csv and no TC cites it"
        elif reason.startswith("Not tested"):
            status = "not covered"
        elif not tests:
            status = "not covered"
        elif "failing" in states.values():
            status = "failing"
        elif "not run" in states.values():
            status = "not run"
        elif reason.startswith("Partly"):
            status = "partial"
        elif kind == "FR" and "partial" in states.values():
            status = "partial"
            note = "via " + ", ".join(tc for tc, s in states.items() if s == "partial")
        else:
            status = "covered"

        rtl = "; ".join(x for x in [owner.get(i, ""), " ".join(tags.get(i, []))] if x)
        out_rows.append({
            "ID": i, "Kind": kind, "Title": short(title), "RTL (owner; @ID tags)": rtl,
            "Tests": " ".join(tests), "Test results": "; ".join(f"{tc} {result.get(tc, 'not run')}" for tc in tests),
            "Status": status, "Note": short(note, 160),
        })

    out = HERE / "results" / run.name
    out.mkdir(parents=True, exist_ok=True)
    with open(out / "requirement_coverage.csv", "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(out_rows[0]), lineterminator="\n")
        w.writeheader()
        w.writerows(out_rows)

    lines = [f"Requirement coverage of phase 6/results/{run.name}", "",
             "Goal (phase 7/coverage_goals.md): every ID covered, or excluded with an approved exclusion", ""]
    lines.append(f"{'KIND':<5} {'IDS':>4} {'DONE':>5}   STATUS COUNTS")
    all_done = True
    for kind in KINDS:
        ks = [r for r in out_rows if r["Kind"] == kind]
        counts = defaultdict(int)
        for r in ks:
            counts[r["Status"]] += 1
        done = sum(counts[s] for s in DONE)
        all_done &= done == len(ks)
        lines.append(f"{kind:<5} {len(ks):>4} {done:>5}   " + ", ".join(f"{s} {n}" for s, n in sorted(counts.items())))
    lines += ["", "Not covered yet:"]
    gaps = [r for r in out_rows if r["Status"] not in DONE]
    lines += [f"  {r['ID']:<7} {r['Status']:<12} {r['Note'] or r['Test results']}" for r in gaps] or ["  none"]
    lines += ["", "Every ID: requirement_coverage.csv"]
    with open(out / "requirement_summary.txt", "w", encoding="utf-8", newline="\n") as f:  # LF on every OS
        f.write("\n".join(lines) + "\n")
    print("\n".join(lines))
    print(f"-> phase 7/results/{run.name}/")
    sys.exit(0 if all_done else 1)


if __name__ == "__main__":
    main()
