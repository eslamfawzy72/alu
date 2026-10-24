#!/usr/bin/env bash
# Phase 3 regression: builds the Phase 2 DUT with tb/tb_cpu.sv, runs it, checks the log and
# writes the results. Uses Verilator (5.020 or later), the simulator of Phase 2's tool gate.
#
# usage: bash run.sh [+SEED=n] [+RANDOM_N=n]   -> results/
#        bash run.sh +CHECKER_SELFTEST         -> results/checker_selftest/ (must catch the fault)
# exit:  0 when the run passes (or the self-test catches its fault), 1 otherwise
set -euo pipefail
cd "$(dirname "$0")"

DUT="../phase 2/04_rtl"   # from phase 2/08_release/phase2_handoff.md (filelist files.f)
OUT=results
case " $* " in *" +CHECKER_SELFTEST "*) OUT=results/checker_selftest ;; esac
LOG=$OUT/sim.log

command -v verilator > /dev/null || { echo "verilator not found (Phase 3 uses Verilator >= 5.020)"; exit 1; }
# Built from a copy in a temp folder: GNU Make cannot build in a path with a space ("phase 3")
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
mkdir -p "$OUT"
cp -r "$DUT" "$BUILD/dut"
cp tb/tb_cpu.sv "$BUILD/"

{
  echo "date:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "commit: $(git rev-parse --short HEAD 2> /dev/null || echo unknown)"
  echo "args:   $*"
  echo "tool:   $(verilator --version)"
  echo "golden vectors sha256: $(sha256sum < '../phase 1/ALU_Golden_Vectors.csv')"
  echo "DUT sha256:"
  (cd "$BUILD/dut/rtl" && sha256sum ./*)
} > "$OUT/run_info.txt"

if ! (cd "$BUILD/dut" && verilator --binary -Wno-fatal -f files.f ../tb_cpu.sv \
        --top-module tb_cpu -Mdir ../obj -o tb_cpu) > "$OUT/build.log" 2>&1; then
  echo "BUILD FAILED, see $OUT/build.log"
  exit 1
fi

# +verilator+error+limit: CPU.Calc reports invalid codes with $error, which Verilator would
# otherwise treat as $stop (Phase 2 review flag F1). Runs from this folder because the
# program reads ../phase 1/ALU_Golden_Vectors.csv.
"$BUILD/obj/tb_cpu" +verilator+error+limit+100 "$@" > "$LOG" 2>&1 || true

# TC-005 (D-010): every EXPECT-DISPLAY line must be printed exactly by display(), whole line
want=0
got=0
while IFS= read -r text; do
  want=$((want + 1))
  if grep -v '^EXPECT-DISPLAY ' "$LOG" | grep -qxF -- "$text"; then got=$((got + 1)); fi
done < <(sed -n 's/^EXPECT-DISPLAY //p' "$LOG")
tc005=FAIL
if [ "$want" -gt 0 ] && [ "$got" -eq "$want" ]; then tc005=PASS; fi

# TC-027 (D-009): one $error naming each invalid code, and no other error
errors=$(grep -c '%Error' "$LOG" || true)
e1110=$(grep '%Error' "$LOG" | grep -c "1110" || true)
e1111=$(grep '%Error' "$LOG" | grep -c "1111" || true)
tc027=FAIL
if [ "$errors" -eq 2 ] && [ "$e1110" -eq 1 ] && [ "$e1111" -eq 1 ]; then tc027=PASS; fi

verdict=FAIL
if grep -q '^RESULT PASS' "$LOG" && [ "$tc005" = PASS ] && [ "$tc027" = PASS ]; then verdict=PASS; fi

{
  echo "Phase 3 regression: $verdict   ($OUT/run_info.txt has the inputs used)"
  echo
  # per-bin "COVERAGE BIN" lines stay in sim.log (Phase 7 merges them)
  grep -E '^(TC-|COVERAGE (HOLE|[0-9])|RESULT)' "$LOG" || echo "no summary from tb_cpu: read $LOG"
  echo "LOG-CHECK TC-005 $tc005: $got of $want expected display() lines found"
  echo "LOG-CHECK TC-027 $tc027: $errors %Error lines, $e1110 naming 4'b1110, $e1111 naming 4'b1111 (expected 2, 1, 1)"
} > "$OUT/summary.txt"
cat "$OUT/summary.txt"

if [ "$OUT" = results/checker_selftest ]; then
  if [ "$verdict" = FAIL ] && grep -q '^FAIL ' "$LOG"; then
    echo "checker self-test OK: the corrupted value was reported as FAIL" | tee -a "$OUT/summary.txt"
    exit 0
  fi
  echo "checker self-test NOT OK: the corrupted value was not caught" | tee -a "$OUT/summary.txt"
  exit 1
fi
[ "$verdict" = PASS ]
