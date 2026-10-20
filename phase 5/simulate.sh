#!/usr/bin/env bash
# Phase 5: runs the Phase 3 regression in the order Phase 5 needs and keeps each run's results
# in runs/<name>/ (run.sh overwrites ../phase 3/results/ every time).
#   1. checker self-test        must catch its corrupted value, or nothing else is trusted
#   2. +SEED=7                  a second seed, compared with seed 1 in step 4
#   3. seed 1, twice            the regression of record; the two logs must be identical
#   4. seed check               seed 1 and seed 7 logs must differ apart from their header
# The last run is seed 1, so ../phase 3/results/ holds the regression of record.
#
# usage: bash simulate.sh [+RANDOM_N=n]
# exit:  0 when every step passes, 1 otherwise
set -uo pipefail
cd "$(dirname "$0")"

RUN="../phase 3/run.sh"
RES="../phase 3/results"
FILES=(summary.txt sim.log build.log run_info.txt)
mkdir -p runs

keep() {  # keep <name> <results folder>
  rm -rf "runs/$1"
  mkdir -p "runs/$1"
  for f in "${FILES[@]}"; do cp "$2/$f" "runs/$1/" 2> /dev/null || true; done
}

# sim.log without the header line that names the seed
body() { grep -v '^tb_cpu: golden=' "runs/$1/sim.log"; }

verdict=0
report=()

if bash "$RUN" +CHECKER_SELFTEST "$@"; then
  report+=("SELFTEST OK")
else
  keep selftest "$RES/checker_selftest"
  echo "STOP: checker self-test NOT OK, so the checkers cannot be trusted. Fix the test program."
  exit 1
fi
keep selftest "$RES/checker_selftest"

for name in seed7 seed1_a seed1_b; do
  args=("$@")
  if [ "$name" = seed7 ]; then args+=(+SEED=7); fi
  if bash "$RUN" "${args[@]}"; then
    report+=("REGRESSION $name PASS")
  else
    report+=("REGRESSION $name FAIL: triage every FAIL in runs/$name/sim.log into defects.md")
    verdict=1
  fi
  keep "$name" "$RES"
done

if cmp -s runs/seed1_a/sim.log runs/seed1_b/sim.log; then
  report+=("REPRODUCIBLE PASS: two seed-1 runs gave identical logs")
else
  report+=("REPRODUCIBLE FAIL: two seed-1 runs differ (diff runs/seed1_a/sim.log runs/seed1_b/sim.log)")
  verdict=1
fi

if cmp -s <(body seed1_a) <(body seed7); then
  report+=("SEED-CHECK FAIL: seed 1 and seed 7 logs are the same apart from the header, so nothing shows that +SEED changes the stimulus")
  verdict=1
else
  report+=("SEED-CHECK PASS: seed 1 and seed 7 logs differ")
fi

{
  echo "Phase 5 simulation: $([ $verdict -eq 0 ] && echo PASS || echo FAIL)   ($(date -u +%Y-%m-%dT%H:%M:%SZ), commit $(git rev-parse --short HEAD 2> /dev/null || echo unknown))"
  printf '%s\n' "${report[@]}"
} | tee runs/summary.txt
exit $verdict
