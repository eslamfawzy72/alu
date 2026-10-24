#!/usr/bin/env python3
"""Phase 8: checks the signoff evidence mechanically and writes signoff_check.txt.

Each line is PASS, FAIL or MANUAL (a person must confirm it in signoff.md). Nothing is
changed anywhere: the script only reads the other phases' files, git and (for the tag)
the remote.

usage: python3 signoff_check.py      -> signoff_check.txt
exit:  0 when no check FAILs, 1 otherwise
"""
import csv
import os
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
results = []  # (status, item, evidence)


def check(ok, item, evidence):
    results.append(("PASS" if ok else "FAIL", item, evidence))


def manual(item, evidence):
    results.append(("MANUAL", item, evidence))


def git(*args, timeout=60):
    # Never wait for a login prompt (the remote check would hang without credentials)
    env = dict(os.environ, GIT_TERMINAL_PROMPT="0", GCM_INTERACTIVE="never")
    try:
        p = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, env=env,
                           stdin=subprocess.DEVNULL, timeout=timeout)
    except subprocess.TimeoutExpired:
        return 124, ""
    return p.returncode, p.stdout.strip()


# Regression inputs: a run made at an older commit still applies if none of these changed since
INPUTS = ["phase 1", "phase 2/04_rtl", "phase 2/07_smoke/smoke_tb.sv", "phase 2/07_smoke/run_smoke.sh",
          "phase 3/tb", "phase 3/run.sh", "phase 4/build.sh"]


def same_inputs(commit):
    return git("diff", "--quiet", commit, "HEAD", "--", *INPUTS)[0] == 0


def rows(path):
    with open(path, encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def md_table(path, first_col):
    """Rows (as dicts) of every Markdown table in path whose first header cell is first_col."""
    out, header = [], None
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            header = None
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if header is None:
            header = cells if cells and cells[0] == first_col else []
            continue
        if not header or set(line) <= set("|-: "):
            continue
        out.append(dict(zip(header, cells)))
    return out


# ---- the commit under signoff ----
_, head = git("rev-parse", "--short", "HEAD")
_, dirty = git("status", "--porcelain")
check(dirty == "", "working tree clean (signoff is on a committed state)",
      f"HEAD {head}" + ("" if dirty == "" else f"; {len(dirty.splitlines())} uncommitted paths"))

# ---- Phase 1 ----
spec = (ROOT / "phase 1" / "alu_spec.json").read_text(encoding="utf-8")
m = re.search(r'"spec_version"\s*:\s*"([^"]+)"', spec)
sv = m[1] if m else "missing"
check(m is not None and "proposed" not in sv, "Phase 1 spec_version final (no -proposed)", f"spec_version {sv}")

dec = rows(ROOT / "phase 1" / "ALU_Design_Decisions.csv")
unapproved = [d["Decision ID"] for d in dec
              if d["Status"] != "Approved" or not d["Approved by"].strip() or not d["Date"].strip()]
check(not unapproved, "Phase 1 decisions approved with approver and date",
      f"{len(dec) - len(unapproved)}/{len(dec)} approved" + (f"; not: {', '.join(unapproved)}" if unapproved else ""))

oq = rows(ROOT / "phase 1" / "ALU_Open_Questions.csv")
open_oq = [q["Question ID"] for q in oq if not q["Status"].startswith("Resolved")]
check(not open_oq, "Phase 1 ALU_Open_Questions.csv has no open question",
      f"{len(oq) - len(open_oq)}/{len(oq)} resolved" + (f"; open: {', '.join(open_oq)}" if open_oq else ""))

q2 = md_table(ROOT / "phase 2" / "01_spec_check" / "questions_for_phase1.md", "#")
ans_col = next((k for k in (q2[0] if q2 else {}) if k.startswith("Answer")), None)
open_q2 = [q["#"] for q in q2 if ans_col and not q[ans_col].strip()]
check(not open_q2, "Phase 2 questions for Phase 1 answered",
      f"{len(q2) - len(open_q2)}/{len(q2)} answered" + (f"; open: {', '.join(open_q2)}" if open_q2 else ""))

q3_text = (ROOT / "phase 3" / "questions_for_phase1.md").read_text(encoding="utf-8")
q3_items = re.split(r"\n(?=\d+\. )", q3_text)
q3 = [(it.split(".", 1)[0], "**Answered" in it) for it in q3_items if re.match(r"\d+\. ", it)]
open_q3 = [f"#{n}" for n, answered in q3 if not answered]
check(not open_q3, "Phase 3 questions for Phase 1 answered",
      f"{len(q3) - len(open_q3)}/{len(q3)} answered" + (f"; open: {', '.join(open_q3)}" if open_q3 else ""))

# ---- Phase 2 ----
tags = [t for t in git("tag", "-l", "phase2-rtl-v*", "--sort=-v:refname")[1].splitlines() if t]
rtl_tag = next((t for t in tags if git("diff", "--quiet", t, "--", "phase 2/04_rtl")[0] == 0), None)
check(rtl_tag is not None, "accepted RTL revision: a phase2-rtl-v* tag equals phase 2/04_rtl at HEAD",
      rtl_tag or f"no tag matches (tags: {', '.join(tags) or 'none'})")
if rtl_tag:
    rc, remote = git("ls-remote", "--tags", "origin", rtl_tag, timeout=30)
    check(rc == 0 and rtl_tag in remote, f"RTL tag {rtl_tag} exists on origin",
          "found on origin" if rc == 0 and rtl_tag in remote else "not found on origin (or origin unreachable)")
dv2 = [q for q in q2 if q.get("#") == "Q3"]
check(bool(dv2) and ans_col and dv2[0][ans_col].strip() != "", "deviations DV-1 and DV-2 accepted by Phase 1",
      "DV-1 accepted (Q2); DV-2 " + ("answered (Q3)" if dv2 and ans_col and dv2[0][ans_col].strip() else "not answered (Q3 open)"))

# ---- Phases 3 to 5 ----
defects = md_table(ROOT / "phase 5" / "defects.md", "ID")
open_def = [d["ID"] for d in defects if d.get("ID", "—") not in ("—", "") and d.get("Status", "").lower() not in ("closed", "deferred")]
check(not open_def, "Phase 5 defects closed or formally deferred",
      f"{len(open_def)} open" + (f": {', '.join(open_def)}" if open_def else ""))

# ---- Phase 6 ----
hist_path = ROOT / "phase 6" / "history.csv"
hist = rows(hist_path) if hist_path.exists() else []
rel = [h for h in hist if h["level"] == "release"]
last_rel = rel[-1] if rel else None
check(bool(last_rel) and last_rel["verdict"] == "PASS" and same_inputs(last_rel["commit"]) and last_rel["dirty"] == "no"
      and last_rel["seeds_flaky"] == "0",
      "Phase 6 release regression PASS on the inputs at HEAD, no uncommitted inputs, no FLAKY",
      (f"last release run {last_rel['results_dir']}: {last_rel['verdict']}, commit {last_rel['commit']} "
       f"(inputs {'unchanged' if same_inputs(last_rel['commit']) else 'CHANGED'} since), "
       f"dirty {last_rel['dirty']}, flaky {last_rel['seeds_flaky']}") if last_rel else "no release run in phase 6/history.csv")
fails = [h for h in hist if h["verdict"] != "PASS"]
manual("every failing Phase 6 run explained in phase 6/regression_report.md",
       f"{len(fails)} non-PASS rows in history.csv" + (": " + ", ".join(h["results_dir"].split("/")[-1] for h in fails) if fails else ""))

# ---- Phase 7 (on the Phase 6 run of record) ----
if last_rel:
    p7 = ROOT / "phase 7" / "results" / Path(last_rel["results_dir"]).name
    cm, rs = p7 / "coverage_merged.txt", p7 / "requirement_summary.txt"
    cm_ok = cm.exists() and ": MET" in cm.read_text(encoding="utf-8")
    check(cm_ok, "Phase 7 G1 functional coverage goal met on the release run",
          str(cm.relative_to(ROOT).as_posix()) if cm.exists() else f"missing {cm.relative_to(ROOT).as_posix()}")
    if rs.exists():
        txt = rs.read_text(encoding="utf-8")
        gaps = txt.split("Not covered yet:")[1].split("\n\n")[0].strip() if "Not covered yet:" in txt else "?"
        check(gaps == "none", "Phase 7 G2/G3 every TC and requirement covered or excluded",
              "no gaps" if gaps == "none" else f"{len(gaps.splitlines())} gaps in {rs.relative_to(ROOT).as_posix()}")
    else:
        check(False, "Phase 7 G2/G3 every TC and requirement covered or excluded", f"missing {rs.relative_to(ROOT).as_posix()}")
else:
    check(False, "Phase 7 coverage on the release run", "no release run to analyse")
code = sorted((ROOT / "phase 7" / "results").glob("code_*"))
code_dir = code[-1] if code else None
if code_dir:
    first = (code_dir / "summary.txt").read_text(encoding="utf-8").splitlines()[0]
    info = (code_dir / "run_info.txt").read_text(encoding="utf-8")
    m = re.search(r"(\d+)/(\d+) points hit", first)
    c = re.search(r"^commit: (\w+)(.*)$", info, re.M)
    fresh = bool(c) and "uncommitted" not in c[2] and same_inputs(c[1])
    check(bool(m) and m[1] == m[2] and "RESULT PASS" in first and fresh,
          "Phase 7 G4 RTL code coverage points all hit, on the inputs at HEAD",
          f"{code_dir.relative_to(ROOT).as_posix()}: {first}" + ("" if fresh else "; run is not on the inputs at HEAD"))
else:
    check(False, "Phase 7 G4 RTL code coverage points all hit, on the inputs at HEAD", "no phase 7/results/code_*")
excl_path = ROOT / "phase 7" / "exclusions.md"
excl = md_table(excl_path, "ID") if excl_path.exists() else []
pending = [e["ID"] for e in excl if e.get("Status", "").lower() != "approved"]
check(not pending, "Phase 7 exclusions all approved (reviewer and date)",
      f"{len(excl) - len(pending)}/{len(excl)} approved" + (f"; pending: {', '.join(pending)}" if pending else ""))

# ---- AGENTS.md known issues ----
agents = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
ki = agents.split("## Known issues", 1)[1].split("\n---", 1)[0] if "## Known issues" in agents else ""
n_ki = len(re.findall(r"^\d+\. ", ki, re.M))
manual("AGENTS.md known issues resolved", f"{n_ki} listed under 'Known issues'")

# ---- report ----
n_fail = sum(1 for s, _, _ in results if s == "FAIL")
n_manual = sum(1 for s, _, _ in results if s == "MANUAL")
lines = [f"Signoff check: {'READY' if n_fail == 0 else 'NOT READY'}   (HEAD {head}; "
         f"{n_fail} FAIL, {n_manual} MANUAL to confirm in signoff.md)", ""]
lines += [f"{s:<6} {item}: {ev}" for s, item, ev in results]
with open(HERE / "signoff_check.txt", "w", encoding="utf-8", newline="\n") as f:  # LF on every OS
    f.write("\n".join(lines) + "\n")
print("\n".join(lines))
raise SystemExit(0 if n_fail == 0 else 1)
