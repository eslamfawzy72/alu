#!/usr/bin/env bash
# Phase 7: RTL code coverage. Builds the Phase 2 DUT with the Phase 3 test program under
# Verilator --coverage, runs one seed, and reports every RTL coverage point (line, block and
# branch) with its hit count. The test program itself is not reported.
# Verilator 5.020's --binary main does not write coverage.dat, so this script supplies its own
# C++ main. Verilator puts no coverage point in a branch that calls $stop or $error, so those
# branches are listed separately as "not measured".
#
# usage: bash code_coverage.sh [+SEED=n] [+RANDOM_N=n]   -> results/code_<UTC date-time>_<commit>/
# exit:  0 when the simulation passes and every RTL coverage point is hit, 1 otherwise
set -uo pipefail
cd "$(dirname "$0")"

DUT="../phase 2/04_rtl"
TB="../phase 3/tb/tb_cpu.sv"
GOLDEN="$(cd "../phase 1" && pwd)/ALU_Golden_Vectors.csv"

command -v verilator > /dev/null || { echo "verilator not found (Phase 7 uses Verilator >= 5.020)"; exit 1; }
commit=$(git rev-parse --short HEAD 2> /dev/null || echo unknown)
out="results/code_$(date -u +%Y-%m-%dT%H%M%SZ)_$commit"
mkdir -p "$out"
out=$(cd "$out" && pwd)

# Built in a temp folder: GNU Make cannot build in a path with a space ("phase 7")
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cp -r "$DUT" "$BUILD/dut"
cp "$TB" "$BUILD/"
cat > "$BUILD/sim_main.cpp" << 'EOF'
// Minimal main that, unlike --binary's, writes coverage.dat at the end
#include <memory>
#include "Vtb_cpu.h"
#include "verilated.h"
#include "verilated_cov.h"
int main(int argc, char** argv) {
    const std::unique_ptr<VerilatedContext> ctx{new VerilatedContext};
    ctx->commandArgs(argc, argv);
    const std::unique_ptr<Vtb_cpu> top{new Vtb_cpu{ctx.get()}};
    while (!ctx->gotFinish()) {
        top->eval();
        if (!top->eventsPending()) break;
        ctx->time(top->nextTimeSlot());
    }
    top->final();
    ctx->coveragep()->write("coverage.dat");
    return 0;
}
EOF

{
  echo "date:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "commit: $commit$(git diff --quiet HEAD -- "$DUT" "$TB" 2> /dev/null || echo ' (DUT or test program has uncommitted changes)')"
  echo "args:   $*"
  echo "tool:   $(verilator --version)"
  echo "sha256:"
  (cd "$BUILD/dut" && sha256sum rtl/* && cd .. && sha256sum tb_cpu.sv)
} > "$out/run_info.txt"

if ! (cd "$BUILD/dut" && verilator --cc --exe --build --timing --coverage -Wno-fatal -f files.f \
        ../tb_cpu.sv ../sim_main.cpp --top-module tb_cpu -Mdir ../obj -o tb_cpu) > "$out/build.log" 2>&1; then
  echo "BUILD FAILED, see $out/build.log"
  exit 1
fi
# +verilator+error+limit: CPU.Calc reports invalid codes with $error (Phase 2 flag F1)
(cd "$BUILD" && ./obj/tb_cpu +verilator+error+limit+100 +GOLDEN="$GOLDEN" "$@") > "$out/sim.log" 2>&1 || true
cp "$BUILD/coverage.dat" "$out/" 2> /dev/null || { echo "no coverage.dat written, see $out/sim.log"; exit 1; }
sim=$(grep -m 1 '^RESULT' "$out/sim.log" || echo "RESULT missing")

# One line per RTL coverage point: <file>:<line> <kind> <hits>
tr '\001\002' '|=' < "$out/coverage.dat" | grep '|f=rtl/' |
  sed -E "s/^C '\|f=([^|]*)\|l=([0-9]+)\|.*\|o=([^|]*)\|.*' ([0-9]+)$/\1:\2 \3 \4/" |
  sort -t: -k1,1 -k2,2n > "$out/rtl_points.txt"

# Annotated RTL sources (every line; uncovered points start with %)
(cd "$BUILD/dut" && verilator_coverage --annotate "$BUILD/ann" --annotate-all --annotate-min 1 "$out/coverage.dat") > /dev/null 2>&1
mkdir -p "$out/annotated"
for f in "$BUILD/dut/rtl/"*; do   # verilator_coverage writes the annotated files flat, by base name
  cp "$BUILD/ann/$(basename "$f")" "$out/annotated/" 2> /dev/null
done

total=$(grep -c . "$out/rtl_points.txt" || true)
hit=$(awk '$3 > 0' "$out/rtl_points.txt" | grep -c . || true)
{
  echo "RTL code coverage: $hit/$total points hit   ($sim; inputs in run_info.txt)"
  echo
  echo "Per file (points hit / points):"
  awk '{ split($1, a, ":"); n[a[1]]++; if ($3 > 0) h[a[1]]++ }
       END { for (f in n) printf "  %-24s %d/%d\n", f, h[f], n[f] }' "$out/rtl_points.txt" | sort
  echo
  echo "Points never hit:"
  awk '$3 == 0 { print "  " $0 }' "$out/rtl_points.txt" | grep . || echo "  none"
  echo
  echo "Not measured: RTL lines that call \$stop or \$error get no coverage point from Verilator."
  echo "Phase 7 covers them by a functional check or a justified exclusion (coverage_report.md):"
  (cd "$BUILD/dut" && grep -nE '\$(error|stop|fatal)' rtl/*) | sed 's/^/  /'
  echo
  echo "Every point: rtl_points.txt (<file>:<line> <kind> <hits>); annotated sources: annotated/"
} > "$out/summary.txt"
cat "$out/summary.txt"
echo "-> phase 7/${out##*/phase 7/}"

case "$sim" in "RESULT PASS"*) ;; *) exit 1 ;; esac
[ "$hit" -eq "$total" ]
