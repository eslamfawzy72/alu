#!/usr/bin/env bash
# Phase 7: merges the functional coverage of one Phase 6 regression. Reads the
# "COVERAGE BIN <name> <hits>" lines that tb_cpu.sv prints for every bin (Phase 3 repair 4)
# from each seed run's sim.log, and compares the result with the goal of
# phase 3/verification_plan.md section 7: all 44 bins hit in every run.
#
# usage: bash merge_coverage.sh "../phase 6/results/<run>"   -> results/<run>/coverage_merged.txt
# exit:  0 when the goal is met, 1 otherwise
set -uo pipefail

GOAL_BINS=44   # phase 3/verification_plan.md section 7: 16 opcode + 8 carry out + 4 carry in + 16 amount

[ $# -eq 1 ] && [ -d "$1" ] || { echo 'usage: bash merge_coverage.sh "phase 6/results/<run>"'; exit 1; }
run=$(cd "$1" && pwd)   # resolved before leaving the caller's folder
cd "$(dirname "$0")"
name=$(basename "$run")
logs=()
for d in "$run"/seed* "$run"/long; do [ -f "$d/sim.log" ] && logs+=("$d/sim.log"); done
[ ${#logs[@]} -gt 0 ] || { echo "no seed*/sim.log in $run"; exit 1; }
if ! grep -q '^COVERAGE BIN ' "${logs[@]}"; then
  echo "no 'COVERAGE BIN' lines in $run: that run used a tb_cpu.sv without per-bin counts (before Phase 3 repair 4)"
  exit 1
fi
out="results/$name"
mkdir -p "$out"

# <bin name> <runs> <runs hit> <total hits> <min> <max>, one line per bin
table=$(awk '
  FNR == 1 { run++ }
  /^COVERAGE BIN / { n = $NF; b = $3; for (i = 4; i < NF; i++) b = b " " $i
                     bins[b] = 1; hits[b, run] = n; total[b] += n }
  END { for (b in bins) {
          hitruns = 0; min = -1; max = 0
          for (r = 1; r <= run; r++) { n = hits[b, r] + 0; if (n > 0) hitruns++
                                       if (min < 0 || n < min) min = n; if (n > max) max = n }
          printf "%s\t%d\t%d\t%d\t%d\t%d\n", b, run, hitruns, total[b], min, max } }
' "${logs[@]}" | sort)
nbins=$(printf '%s\n' "$table" | grep -c .)
nfull=$(printf '%s\n' "$table" | awk -F'\t' '$3 == $2' | grep -c . || true)
goal=MET
[ "$nbins" -eq "$GOAL_BINS" ] && [ "$nfull" -eq "$GOAL_BINS" ] || goal="NOT MET"

{
  echo "Functional coverage, merged over ${#logs[@]} seed runs of phase 6/results/$name"
  echo
  echo "Goal (phase 3/verification_plan.md section 7): $GOAL_BINS bins, each hit in every run: $goal"
  echo "Bins found: $nbins; hit in every run: $nfull; hit in no run: $(printf '%s\n' "$table" | awk -F'\t' '$3 == 0' | grep -c . || true)"
  echo
  printf '%-26s %10s %12s %10s %10s\n' BIN "RUNS HIT" "TOTAL HITS" "MIN/RUN" "MAX/RUN"
  printf '%s\n' "$table" | awk -F'\t' '{ printf "%-26s %10s %12d %10d %10d\n", $1, $3 "/" $2, $4, $5, $6 }'
  echo
  echo "Lowest MIN/RUN first (the bins closest to being missed):"
  printf '%s\n' "$table" | sort -t$'\t' -k5,5n | head -n 8 | awk -F'\t' '{ printf "  %-26s min %d per run\n", $1, $5 }'
} > "$out/coverage_merged.txt"
cat "$out/coverage_merged.txt"
[ "$goal" = MET ]
