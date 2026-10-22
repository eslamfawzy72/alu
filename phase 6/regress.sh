#!/usr/bin/env bash
# Phase 6: reruns the Phase 3 regression at many seeds after a change and keeps a history.
# Behaviour is set by spec.md (section numbers below refer to it). It never fixes anything:
# every failure goes to Phase 5 for triage.
#   quick    build gate, smoke test, checker self-test, seed 1
#   full     build gate, smoke test, checker self-test, seeds 1 to 20
#   release  full, plus one long run (seed 99)
# Seed 1 runs last, so ../phase 3/results/ ends up holding the seed-1 run of record.
#
# usage: bash regress.sh quick|full|release [--force]
#        --force runs even when the inputs are unchanged since an equal or higher PASS
# exit:  0 for PASS or a skip (inputs unchanged), 1 otherwise
set -uo pipefail
cd "$(dirname "$0")"

# Settings: the only thing Phase 6 owns (spec.md section 2). RANDOM_N is never below 3000.
SEEDS_FULL=$(seq 1 20)
RANDOM_N=5000
LONG_SEED=99
LONG_RANDOM_N=100000

ROOT=..
RUN="$ROOT/phase 3/run.sh"
RES="$ROOT/phase 3/results"
BUILD="$ROOT/phase 4/build.sh"
SMOKE="$ROOT/phase 2/07_smoke/run_smoke.sh"
SPEC="$ROOT/phase 1/alu_spec.json"
HISTORY=history.csv
HEADER="date,commit,rtl_tag,spec_version,verilator,level,seeds,random_n,pass,fail,verdict,fingerprint,results_dir"
FILES=(summary.txt sim.log build.log run_info.txt)

usage() { echo "usage: bash regress.sh quick|full|release [--force]"; exit 1; }
level=""
force=0
for arg in "$@"; do
  case "$arg" in
    quick | full | release) [ -z "$level" ] || usage; level=$arg ;;
    --force) force=1 ;;
    *) usage ;;
  esac
done
[ -n "$level" ] || usage

rank() { case "$1" in quick) echo 1 ;; full) echo 2 ;; release) echo 3 ;; *) echo 0 ;; esac; }

command -v verilator > /dev/null || { echo "verilator not found (Phase 6 uses Verilator >= 5.020)"; exit 1; }

# ---- Section 5: fingerprint of the inputs (the commit is recorded but not part of it) ----
spec_version=$(sed -n 's/.*"spec_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$SPEC" | head -n 1)
tool=$(verilator --version | tr ',' ';')
# One "<value>  <input>" line per input, like sha256sum, so a changed line names its input
fingerprint_lines() {
  (cd "$ROOT" && sha256sum "phase 2/04_rtl/rtl/"* "phase 2/04_rtl/files.f" "phase 3/tb/tb_cpu.sv" \
     "phase 3/run.sh" "phase 1/ALU_Golden_Vectors.csv")
  echo "$spec_version  spec_version"
  echo "$tool  verilator"
}
fp_text=$(fingerprint_lines)
fingerprint=$(printf '%s\n' "$fp_text" | sha256sum | cut -c1-16)

commit=$(git rev-parse --short HEAD 2> /dev/null || echo unknown)
dirty=""
if ! git diff --quiet HEAD -- "$ROOT/phase 2/04_rtl" "$ROOT/phase 3/tb" "$RUN" "$ROOT/phase 1" 2> /dev/null; then
  dirty=" (inputs have uncommitted changes)"
fi
# RTL tag: the newest phase2-rtl-v* tag whose 04_rtl matches the files under test, else none
rtl_tag=none
for t in $(git tag -l 'phase2-rtl-v*' --sort=-v:refname 2> /dev/null); do
  if git diff --quiet "$t" -- "$ROOT/phase 2/04_rtl" 2> /dev/null; then rtl_tag=$t; break; fi
done

# ---- Section 5: change check against the last PASS row of history.csv ----
# Fields: 1 date, 2 commit, 3 rtl_tag, 6 level, 11 verdict, 12 fingerprint, 13 results_dir
last=""
[ -f "$HISTORY" ] && last=$(awk -F, 'NR > 1 && $11 == "PASS"' "$HISTORY" | tail -n 1)
required=quick
if [ -z "$last" ]; then
  echo "change check: no PASS in $HISTORY yet, nothing to compare with"
else
  IFS=, read -r l_date l_commit l_tag _ _ l_level _ _ _ _ _ l_fp l_dir <<< "$last"
  if [ "$l_fp" = "$fingerprint" ] && [ "$(rank "$l_level")" -ge "$(rank "$level")" ] && [ "$force" -eq 0 ]; then
    echo "inputs unchanged since $l_commit ($l_level PASS on $l_date)"
    exit 0
  fi
  if [ "$l_fp" = "$fingerprint" ]; then
    echo "change check: inputs unchanged since $l_commit ($l_level PASS on $l_date)$([ "$force" -eq 1 ] && echo ', running anyway (--force)')"
  elif [ -f "$l_dir/fingerprint.txt" ]; then
    echo "change check: inputs changed since $l_commit ($l_level PASS on $l_date):"
    # An input whose "<value>  <input>" line differs (or is new, or gone) has changed
    changed=$(diff <(sort "$l_dir/fingerprint.txt") <(printf '%s\n' "$fp_text" | sort) \
                | sed -n 's/^[<>] .*  //p' | sort -u)
    while IFS= read -r input; do
      echo "  $input"
      # Section 4: which level the change asks for
      case "$input" in
        "phase 2/04_rtl/"*) ;;
        *) required=full ;;
      esac
    done <<< "$changed"
  else
    echo "change check: fingerprint differs from $l_commit ($l_level PASS on $l_date); $l_dir/fingerprint.txt is missing, so the changed inputs can't be listed"
  fi
  if [ "$rtl_tag" != none ] && [ "$rtl_tag" != "$l_tag" ]; then
    echo "  new RTL tag $rtl_tag (last PASS: $l_tag): do Phase 3 readiness check R10 first"
    required=full
  fi
fi
if [ "$(rank "$required")" -gt "$(rank "$level")" ]; then
  echo "WARNING: these changes need a '$required' regression (spec.md section 4); running '$level' as asked"
fi

# ---- Section 6: results folder ----
stamp=$(date -u +%Y-%m-%dT%H%M%SZ)
dir="results/${stamp}_${commit}_${level}"
mkdir -p "$dir"
printf '%s\n' "$fp_text" > "$dir/fingerprint.txt"

keep() {  # keep <step folder> <results folder of run.sh>
  mkdir -p "$dir/$1"
  for f in "${FILES[@]}"; do cp "$2/$f" "$dir/$1/" 2> /dev/null || true; done
}

steps=()        # one "<step> <verdict>" line each
failed=()       # step folders that failed, for failures.txt
verdict=PASS
seeds_run=()
npass=0
nfail=0
stopped=""

# Build gate: lint and build must both pass before any seed runs
mkdir -p "$dir/build"
bash "$BUILD" > "$dir/build/console.log" 2>&1
for f in build_info.txt lint.log build.log; do cp "$ROOT/phase 4/$f" "$dir/build/" 2> /dev/null || true; done
if grep -qx 'LINT: PASS (no messages)' "$dir/build/console.log" && grep -q '^BUILD: PASS' "$dir/build/console.log"; then
  steps+=("build    PASS")
else
  steps+=("build    FAIL (see build/console.log)")
  failed+=(build)
  verdict=FAIL
  stopped="build gate failed"
fi

# Smoke test (Phase 2): a FAIL here fails the regression but the seeds still run
if [ -z "$stopped" ]; then
  mkdir -p "$dir/smoke"
  if bash "$SMOKE" > "$dir/smoke/summary.txt" 2>&1; then
    steps+=("smoke    PASS")
  else
    steps+=("smoke    FAIL (see smoke/summary.txt)")
    failed+=(smoke)
    verdict=FAIL
  fi
  cp "$ROOT/phase 2/07_smoke/smoke_log.txt" "$dir/smoke/sim.log" 2> /dev/null || true
  cp "$ROOT/phase 2/07_smoke/build.log" "$dir/smoke/" 2> /dev/null || true
fi

# Checker self-test: if it does not catch its fault, no seed result can be trusted
if [ -z "$stopped" ]; then
  mkdir -p "$dir/selftest"
  if bash "$RUN" +CHECKER_SELFTEST > "$dir/selftest/console.log" 2>&1; then
    steps+=("selftest OK")
  else
    steps+=("selftest NOT OK (see selftest/summary.txt)")
    failed+=(selftest)
    verdict=FAIL
    stopped="checker self-test not OK"
  fi
  keep selftest "$RES/checker_selftest"
fi

# Section 8: a failing seed is rerun once; an identical sim.log means a real FAIL, else FLAKY
run_seed() {  # run_seed <step folder> <seed> <random_n>
  local name=$1 args=(+SEED=$2 +RANDOM_N=$3)
  seeds_run+=("$2")
  if bash "$RUN" "${args[@]}" > /dev/null 2>&1; then
    keep "$name" "$RES"
    steps+=("$name $(printf '%*s' $((8 - ${#name})) '')PASS")
    npass=$((npass + 1))
    return
  fi
  keep "$name" "$RES"
  bash "$RUN" "${args[@]}" > /dev/null 2>&1
  keep "$name/rerun" "$RES"
  local how=FAIL
  cmp -s "$dir/$name/sim.log" "$dir/$name/rerun/sim.log" || how=FLAKY
  steps+=("$name $(printf '%*s' $((8 - ${#name})) '')$how (rerun $([ $how = FAIL ] && echo identical || echo differs))")
  failed+=("$name:$how")
  nfail=$((nfail + 1))
  verdict=FAIL
}

if [ -z "$stopped" ]; then
  others=()
  [ "$level" != quick ] && for s in $SEEDS_FULL; do [ "$s" -ne 1 ] && others+=("$s"); done
  for s in "${others[@]}"; do run_seed "seed$s" "$s" "$RANDOM_N"; done
  [ "$level" = release ] && run_seed long "$LONG_SEED" "$LONG_RANDOM_N"
  run_seed seed1 1 "$RANDOM_N"   # last: phase 3/results/ keeps the run of record
fi

case "$level" in
  quick) seeds=1 ;;
  full) seeds="1-20" ;;
  release) seeds="1-20+$LONG_SEED" ;;
esac
[ ${#seeds_run[@]} -eq 0 ] && seeds="-"
random_n=$RANDOM_N
[ "$level" = release ] && random_n="$RANDOM_N+$LONG_RANDOM_N"

# failures.txt: seed, TC and the first FAIL line of each failing step
if [ "$verdict" = FAIL ]; then
  for item in "${failed[@]}"; do
    name=${item%%:*}
    how=${item#*:}
    [ "$how" = "$item" ] && how=FAIL
    log="$dir/$name/sim.log"
    line=$(grep -m 1 '^FAIL ' "$log" 2> /dev/null)
    [ -n "$line" ] || line=$(cat "$dir/$name/summary.txt" "$dir/$name/console.log" 2> /dev/null | grep -m 1 'FAIL')
    tc=$(grep -o 'TC-[0-9][0-9]*' <<< "$line" | head -n 1)
    case "$name" in
      seed*) label="seed ${name#seed}" ;;
      long) label="seed $LONG_SEED (long)" ;;
      *) label="step $name" ;;
    esac
    echo "$label $how  TC: ${tc:--}  first FAIL: ${line:-none, read $name/}"
  done > "$dir/failures.txt"
  echo "Triage each one in phase 5/defects.md; replay with: bash \"phase 3/run.sh\" +SEED=<n> +RANDOM_N=<n>" >> "$dir/failures.txt"
fi

{
  echo "Phase 6 regression: $verdict"
  echo "level:        $level"
  echo "commit:       $commit$dirty"
  echo "rtl tag:      $rtl_tag"
  echo "spec_version: $spec_version"
  echo "verilator:    $tool"
  echo "fingerprint:  $fingerprint"
  echo "RANDOM_N:     $random_n"
  echo "seeds:        $seeds (pass=$npass fail=$nfail)"
  [ -n "$stopped" ] && echo "stopped:      $stopped, so no seed ran"
  echo "steps:"
  printf '  %s\n' "${steps[@]}"
  [ "$verdict" = FAIL ] && echo "failures:     $dir/failures.txt"
} > "$dir/regression_summary.txt"
cat "$dir/regression_summary.txt"

[ -f "$HISTORY" ] || echo "$HEADER" > "$HISTORY"
echo "$(date -u +%Y-%m-%d),$commit,$rtl_tag,$spec_version,$tool,$level,$seeds,$random_n,$npass,$nfail,$verdict,$fingerprint,$dir" >> "$HISTORY"

[ "$verdict" = PASS ]
