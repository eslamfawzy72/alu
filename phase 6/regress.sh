#!/usr/bin/env bash
# Phase 6: multi-seed regression. Reruns the existing gates and the Phase 3 regression after a
# change, keeps every run's evidence in results/<run>/, compares it with the previous run and
# adds a row to history.csv. It fixes nothing: each failure goes to Phase 5 triage.
#   quick    build gate, smoke, checker self-test, seed 1
#   full     build gate, smoke, checker self-test, seeds 1 to 20
#   release  full, plus one long run (seed 99, RANDOM_N=100000)
# The gate scripts rewrite their own output files in phase 2/, 3/ and 4/. Those files are
# copied into results/<run>/ and then restored, so Phase 6 changes nothing outside phase 6/.
#
# usage: bash regress.sh quick|full|release [--note "why this run"]
# exit:  0 when the regression passes, 1 otherwise
set -uo pipefail
cd "$(dirname "$0")"

# Settings (README "Settings"). RANDOM_N stays >= 3000 (phase 3/README.md step 5).
SEEDS_FULL=$(seq 1 20)
RANDOM_N=5000
LONG_SEED=99
LONG_RANDOM_N=100000
SMOKE_EXPECT="SUMMARY pass=91 fail=0"   # phase 2/README.md, 07_smoke "done when"

ROOT=..
RUN="$ROOT/phase 3/run.sh"
RES="$ROOT/phase 3/results"
BUILD="$ROOT/phase 4/build.sh"
SMOKE="$ROOT/phase 2/07_smoke/run_smoke.sh"
SPEC="$ROOT/phase 1/alu_spec.json"
HISTORY=history.csv
HEADER="date,commit,dirty,rtl_tag,spec_version,verilator,level,seeds,random_n,seeds_pass,seeds_fail,seeds_flaky,verdict,results_dir,note"
FILES=(summary.txt sim.log build.log run_info.txt)
# Inputs whose sha256 is recorded in run_config.txt and compared between runs (repo-relative)
mapfile -t INPUTS < <(cd "$ROOT" && ls "phase 2/04_rtl/rtl/"*.sv "phase 2/04_rtl/rtl/"*.svh &&
  printf '%s\n' "phase 2/04_rtl/files.f" "phase 2/07_smoke/smoke_tb.sv" "phase 2/07_smoke/run_smoke.sh" \
    "phase 3/tb/tb_cpu.sv" "phase 3/run.sh" "phase 4/build.sh" \
    "phase 1/ALU_Golden_Vectors.csv" "phase 1/alu_spec.json")
# Output files the gate scripts rewrite; restored on exit
TOUCHED=("phase 2/07_smoke/smoke_log.txt" "phase 2/07_smoke/build.log"
         "phase 4/build_info.txt" "phase 4/lint.log" "phase 4/build.log" "phase 3/results")

usage() { echo 'usage: bash regress.sh quick|full|release [--note "why this run"]'; exit 1; }
level=""
note=""
while [ $# -gt 0 ]; do
  case "$1" in
    quick | full | release) [ -z "$level" ] || usage; level=$1 ;;
    --note) [ $# -ge 2 ] || usage; note=$2; shift ;;
    *) usage ;;
  esac
  shift
done
[ -n "$level" ] || usage
note=$(printf '%s' "$note" | tr ',\n' '; ')   # history.csv is comma-separated

command -v verilator > /dev/null || { echo "verilator not found (Phase 6 uses Verilator >= 5.020)"; exit 1; }

# ---- snapshot the files the gate scripts rewrite, restore them on exit ----
SNAP=$(mktemp -d)
for p in "${TOUCHED[@]}"; do
  if [ -e "$ROOT/$p" ]; then mkdir -p "$SNAP/$(dirname "$p")"; cp -R "$ROOT/$p" "$SNAP/$p"; fi
done
restore() {
  for p in "${TOUCHED[@]}"; do
    rm -rf "${ROOT:?}/$p"
    if [ -e "$SNAP/$p" ]; then cp -R "$SNAP/$p" "$ROOT/$p"; fi
  done
  rm -rf "$SNAP"
}
trap restore EXIT

# ---- what is under test ----
started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
commit=$(git rev-parse --short HEAD 2> /dev/null || echo unknown)
branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null || echo unknown)
dirty=no
if [ -n "$(cd "$ROOT" && git status --porcelain -- "${INPUTS[@]}" 2> /dev/null)" ]; then dirty=yes; fi
# RTL tag: the newest phase2-rtl-v* tag whose 04_rtl equals the files under test, else none
rtl_tag=none
for t in $(git tag -l 'phase2-rtl-v*' --sort=-v:refname 2> /dev/null); do
  if git diff --quiet "$t" -- "$ROOT/phase 2/04_rtl" 2> /dev/null; then rtl_tag=$t; break; fi
done
spec_version=$(sed -n 's/.*"spec_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$SPEC" | head -n 1)
tool=$(verilator --version)
tool_short=$(echo "$tool" | awk '{print $2}')

case "$level" in
  quick) seeds=(1) ;;
  *) read -r -a seeds <<< "$(echo $SEEDS_FULL)" ;;
esac
seeds_label="${seeds[0]}"
[ ${#seeds[@]} -gt 1 ] && seeds_label="${seeds[0]}-${seeds[-1]}"
[ "$level" = release ] && seeds_label="$seeds_label+$LONG_SEED"

dir="results/$(date -u +%Y-%m-%dT%H%M%SZ)_${commit}_${level}"
mkdir -p "$dir"
prev=""
[ -f "$HISTORY" ] && prev=$(tail -n +2 "$HISTORY" | tail -n 1 | cut -d, -f14)

{
  echo "date:         $started"
  echo "level:        $level"
  echo "note:         ${note:--}"
  echo "commit:       $commit"
  echo "branch:       $branch"
  echo "dirty inputs: $dirty"
  echo "rtl_tag:      $rtl_tag"
  echo "spec_version: $spec_version"
  echo "tool:         $tool"
  echo "host:         $(uname -srm)"
  echo "seeds:        $seeds_label"
  echo "random_n:     $RANDOM_N"
  [ "$level" = release ] && echo "long run:     seed $LONG_SEED, random_n $LONG_RANDOM_N"
  echo "inputs (sha256):"
  (cd "$ROOT" && sha256sum "${INPUTS[@]}")
} > "$dir/run_config.txt"

step() { echo "$1 $2${3:+ $3}" >> "$dir/steps.txt"; }  # step <name> <status> [detail]
: > "$dir/steps.txt"
stopped=""
echo "Phase 6 $level regression -> phase 6/$dir"

# ---- 1. build gate (Phase 4): lint -Wall and build, warnings fatal ----
mkdir -p "$dir/build"
if bash "$BUILD" > "$dir/build/console.log" 2>&1; then step build PASS
else step build FAIL "see build/console.log"; stopped="build gate"; fi
cp "$ROOT/phase 4/build_info.txt" "$ROOT/phase 4/lint.log" "$ROOT/phase 4/build.log" "$dir/build/" 2> /dev/null
echo "  build    $(tail -n 1 "$dir/steps.txt" | cut -d' ' -f2)"

# ---- 2. smoke (Phase 2): judged from its log, because run_smoke.sh always exits 0 ----
if [ -z "$stopped" ]; then
  mkdir -p "$dir/smoke"
  bash "$SMOKE" > "$dir/smoke/console.log" 2>&1
  cp "$ROOT/phase 2/07_smoke/smoke_log.txt" "$dir/smoke/sim.log" 2> /dev/null
  cp "$ROOT/phase 2/07_smoke/build.log" "$dir/smoke/build.log" 2> /dev/null
  slog="$dir/smoke/sim.log"
  serr=$(grep -c '%Error' "$slog" 2> /dev/null || true)
  s1110=$(grep '%Error' "$slog" 2> /dev/null | grep -c "1110" || true)
  s1111=$(grep '%Error' "$slog" 2> /dev/null | grep -c "1111" || true)
  if grep -qx "$SMOKE_EXPECT" "$slog" 2> /dev/null && [ "$serr" -eq 2 ] && [ "$s1110" -eq 1 ] && [ "$s1111" -eq 1 ]; then
    step smoke PASS
  else
    step smoke FAIL "$(grep '^SUMMARY' "$slog" 2> /dev/null || echo 'no SUMMARY line'), $serr %Error lines (expected '$SMOKE_EXPECT', 2)"
  fi
  echo "  smoke    $(tail -n 1 "$dir/steps.txt" | cut -d' ' -f2)"
fi

# ---- 3. checker self-test (Phase 3): if it misses its fault, no seed result counts ----
if [ -z "$stopped" ]; then
  mkdir -p "$dir/selftest"
  if bash "$RUN" +CHECKER_SELFTEST > "$dir/selftest/console.log" 2>&1; then step selftest OK
  else step selftest NOT-OK "the corrupted value was not caught"; stopped="checker self-test"; fi
  for f in "${FILES[@]}"; do cp "$RES/checker_selftest/$f" "$dir/selftest/" 2> /dev/null; done
  echo "  selftest $(tail -n 1 "$dir/steps.txt" | cut -d' ' -f2)"
fi

# ---- 4. seeds: a failing seed is rerun once; same log again = FAIL, different log = FLAKY ----
npass=0; nfail=0; nflaky=0
run_seed() {  # run_seed <step> <seed> <random_n>
  local name=$1 seed=$2 n=$3 st detail=""
  mkdir -p "$dir/$name"
  if bash "$RUN" +SEED="$seed" +RANDOM_N="$n" > "$dir/$name/console.log" 2>&1; then
    st=PASS
    for f in "${FILES[@]}"; do cp "$RES/$f" "$dir/$name/" 2> /dev/null; done
  else
    for f in "${FILES[@]}"; do cp "$RES/$f" "$dir/$name/" 2> /dev/null; done
    mkdir -p "$dir/$name/rerun"
    if bash "$RUN" +SEED="$seed" +RANDOM_N="$n" > "$dir/$name/rerun/console.log" 2>&1; then
      st=FLAKY; detail="failed, then passed on rerun"
    elif cmp -s "$dir/$name/sim.log" "$RES/sim.log"; then
      st=FAIL; detail="failed twice with identical logs"
    else
      st=FLAKY; detail="failed twice with different logs"
    fi
    for f in "${FILES[@]}"; do cp "$RES/$f" "$dir/$name/rerun/" 2> /dev/null; done
  fi
  case $st in PASS) npass=$((npass + 1)) ;; FAIL) nfail=$((nfail + 1)) ;; FLAKY) nflaky=$((nflaky + 1)) ;; esac
  step "$name" "$st" "seed=$seed random_n=$n${detail:+, $detail}"
  echo "  $name $st"
}
if [ -z "$stopped" ]; then
  for s in "${seeds[@]}"; do run_seed "seed$s" "$s" "$RANDOM_N"; done
  [ "$level" = release ] && run_seed long "$LONG_SEED" "$LONG_RANDOM_N"
fi

# ---- verdict ----
verdict=PASS
if [ -n "$stopped" ] || grep -qvE '^[^ ]+ (PASS|OK)( |$)' "$dir/steps.txt"; then verdict=FAIL; fi

# ---- test report: every TC over all seed runs (first runs only, not reruns) ----
seed_summaries=()
for s in "${seeds[@]}"; do [ -f "$dir/seed$s/summary.txt" ] && seed_summaries+=("$dir/seed$s/summary.txt"); done
[ -f "$dir/long/summary.txt" ] && seed_summaries+=("$dir/long/summary.txt")
{
  echo "Test report: each Phase 1 TC over ${#seed_summaries[@]} seed runs (TC-005 and TC-027 log checks from run.sh)"
  echo
  printf '%-8s %-6s %-12s %s\n' TC STATUS "RUNS PASSED" "CHECKS (summed over runs)"
  if [ ${#seed_summaries[@]} -gt 0 ]; then
    # A TC passes a run when its tb_cpu line and its run.sh log check (if any) both pass
    awk '
      FNR == 1 { run++ }
      $1 ~ /^TC-[0-9]+$/ { tc = $1; p = $3; f = $4; sub("pass=", "", p); sub("fail=", "", f)
                           all[tc] = 1; tb[tc] = 1; if ($2 != "PASS") bad[tc, run] = 1
                           chk_p[tc] += p; chk_f[tc] += f; next }
      $1 == "LOG-CHECK"  { tc = $2; st = $3; sub(":", "", st)
                           all[tc] = 1; lg[tc]++; if (st == "PASS") lg_ok[tc]++; else bad[tc, run] = 1; next }
      END { for (tc in all) {
              ok = 0; for (r = 1; r <= run; r++) if (!((tc, r) in bad)) ok++
              checks = (tc in tb) ? sprintf("pass=%d fail=%d", chk_p[tc], chk_f[tc]) : ""
              if (tc in lg) checks = checks ((tc in tb) ? " + " : "") sprintf("log check %d/%d", lg_ok[tc], lg[tc])
              printf "%-8s %-6s %-12s %s\n", tc, (ok == run) ? "PASS" : "FAIL", ok "/" run, checks } }
    ' "${seed_summaries[@]}" | sort
  fi
  echo
  echo "Coverage per seed run:"
  for f in "${seed_summaries[@]}"; do
    printf '  %-8s %s\n' "$(basename "$(dirname "$f")")" "$(grep '^COVERAGE [0-9]' "$f" || echo 'no COVERAGE line')"
  done
} > "$dir/test_report.txt"
ntc=$(grep -cE '^TC-[0-9]+ ' "$dir/test_report.txt" || true)
ntc_fail=$(grep -cE '^TC-[0-9]+ +FAIL' "$dir/test_report.txt" || true)
ncov=$(grep -c '^  [^ ]* *COVERAGE ' "$dir/test_report.txt" || true)
ncov_full=$(grep -cE '^  [^ ]* *COVERAGE ([0-9]+)/\1 bins hit' "$dir/test_report.txt" || true)

# ---- comparison with the previous run in history.csv ----
{
  if [ -z "$prev" ] || [ ! -d "$prev" ]; then
    echo "No previous regression in $HISTORY: this run is the baseline."
  else
    echo "Compared with: phase 6/$prev"
    echo
    echo "verdict:   $(sed -n '1s/^Phase 6 regression: \([A-Z]*\).*/\1/p' "$prev/regression_summary.txt") -> $verdict"
    for k in level commit rtl_tag spec_version tool random_n seeds; do
      a=$(sed -n "s/^$k: *//p" "$prev/run_config.txt"); b=$(sed -n "s/^$k: *//p" "$dir/run_config.txt")
      if [ "$a" = "$b" ]; then printf '%-13s same (%s)\n' "$k:" "$b"; else printf '%-13s %s -> %s\n' "$k:" "$a" "$b"; fi
    done
    echo
    echo "Inputs changed (sha256):"
    # sha256sum lines are "<hash>  <path>"; paths contain spaces
    changes=$(awk 'FNR == 1 { f++ } /^inputs/ { on[f] = 1; next } !on[f] { next }
                   { h = substr($0, 1, 64); p = substr($0, 67); if (f == 1) a[p] = h; else b[p] = h }
                   END { for (p in b) if (!(p in a)) print "  added:   " p; else if (a[p] != b[p]) print "  changed: " p
                         for (p in a) if (!(p in b)) print "  removed: " p }' \
              "$prev/run_config.txt" "$dir/run_config.txt" | sort)
    echo "${changes:-  none}"
    echo
    echo "Steps (previous -> this run):"
    awk 'NR == FNR { a[$1] = $2; next } { b[$1] = $2; order[++n] = $1 }
         END { for (i = 1; i <= n; i++) { s = order[i]; printf "  %-9s %s -> %s\n", s, (s in a) ? a[s] : "not run", b[s]; delete a[s] }
               for (s in a) printf "  %-9s %s -> not run\n", s, a[s] }' "$prev/steps.txt" "$dir/steps.txt"
    echo
    echo "TC status changes:"
    tcchg=$(awk 'NR == FNR { if ($1 ~ /^TC-/) a[$1] = $2; next }
                 $1 ~ /^TC-/ { if (!($1 in a)) print "  " $1 " new: " $2
                               else if (a[$1] != $2) print "  " $1 " " a[$1] " -> " $2; delete a[$1] }
                 END { for (t in a) print "  " t " " a[t] " -> not run" }' "$prev/test_report.txt" "$dir/test_report.txt" | sort)
    echo "${tcchg:-  none}"
    echo
    echo "Seed logs (same seed in both runs; identical is expected when no input changed):"
    for n in $(awk '$1 ~ /^(seed[0-9]+|long)$/ { print $1 }' "$dir/steps.txt"); do  # run order
      d="$dir/$n"
      [ -f "$d/sim.log" ] || continue
      if [ -f "$prev/$n/sim.log" ]; then
        if cmp -s "$prev/$n/sim.log" "$d/sim.log"; then echo "  $n identical"; else echo "  $n differs"; fi
      fi
    done
  fi
} > "$dir/comparison.txt"

# ---- failures.txt: what failed, the first FAIL line, how to replay ----
if [ "$verdict" = FAIL ]; then
  {
    echo "Failures in phase 6/$dir. Triage each one into phase 5/defects.md (phase 5/README.md step 2)."
    echo
    while read -r name st rest; do
      case "$st" in PASS | OK) continue ;; esac
      echo "$name $st${rest:+ ($rest)}"
      if [ -f "$dir/$name/sim.log" ]; then
        first=$(grep -m 1 '^FAIL ' "$dir/$name/sim.log" || grep -m 1 '^LOG-CHECK .* FAIL' "$dir/$name/summary.txt" 2> /dev/null || true)
        [ -n "$first" ] && echo "  first failure: $first"
        grep -m 1 '^RESULT FAIL' "$dir/$name/sim.log" | sed 's/^/  /'
        grep '^COVERAGE HOLE' "$dir/$name/sim.log" | sed 's/^/  /'
      fi
      seed=$(echo "$rest" | sed -n 's/.*seed=\([0-9]*\).*/\1/p')
      n=$(echo "$rest" | sed -n 's/.*random_n=\([0-9]*\).*/\1/p')
      [ -n "$seed" ] && echo "  replay: bash \"phase 3/run.sh\" +SEED=$seed +RANDOM_N=$n"
    done < "$dir/steps.txt"
    [ -n "$stopped" ] && echo "stopped at the $stopped, so the later steps did not run"
  } > "$dir/failures.txt"
fi

# ---- regression_summary.txt and history.csv ----
{
  echo "Phase 6 regression: $verdict   (level $level, $started, commit $commit, $((SECONDS / 60)) min $((SECONDS % 60)) s)"
  echo "note:         ${note:--}"
  echo "rtl_tag:      $rtl_tag   spec_version: $spec_version   tool: Verilator $tool_short"
  echo "seeds:        $seeds_label at random_n $RANDOM_N (pass=$npass fail=$nfail flaky=$nflaky)"
  echo "tests:        $((ntc - ntc_fail)) of $ntc TCs passed in every seed run (test_report.txt)"
  echo "coverage:     all bins hit in $ncov_full of $ncov seed runs (test_report.txt)"
  [ "$dirty" = yes ] && echo "WARNING:      inputs have uncommitted changes, so this is not a run of record"
  [ -n "$stopped" ] && echo "stopped:      at the $stopped"
  echo "compared:     ${prev:-none (baseline)} (comparison.txt)"
  [ "$verdict" = FAIL ] && echo "failures:     failures.txt"
  echo
  sed 's/^/  /' "$dir/steps.txt"
} > "$dir/regression_summary.txt"

[ -f "$HISTORY" ] || echo "$HEADER" > "$HISTORY"
echo "$(date -u +%Y-%m-%d),$commit,$dirty,$rtl_tag,$spec_version,$tool_short,$level,$seeds_label,$RANDOM_N,$npass,$nfail,$nflaky,$verdict,$dir,$note" >> "$HISTORY"

echo
cat "$dir/regression_summary.txt"
[ "$verdict" = PASS ]
