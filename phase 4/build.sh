#!/usr/bin/env bash
# Phase 4: compiles and elaborates the Phase 2 DUT together with the Phase 3 test program.
# Lints both with -Wall first, then builds the simulation binary with warnings still fatal.
# Uses Verilator (5.020 or later), the simulator of Phase 2's tool gate.
#
# usage: bash build.sh   -> build_info.txt, lint.log, build.log; binary build/obj/tb_cpu
# exit:  0 when lint and build print no unwaived message, 1 otherwise
set -euo pipefail
cd "$(dirname "$0")"

DUT="../phase 2/04_rtl"     # from phase 2/08_release/phase2_handoff.md (filelist files.f)
TB="../phase 3/tb/tb_cpu.sv"
TOP=tb_cpu

command -v verilator > /dev/null || { echo "verilator not found (Phase 4 uses Verilator >= 5.020)"; exit 1; }
rm -rf build
mkdir -p build
cp -r "$DUT" build/dut      # built from a copy so no compiler path contains a space
cp "$TB" build/
# waivers.vlt holds the warnings waived in elab_report.md, each with its reason
WAIVERS=()
if [ -f waivers.vlt ]; then
  cp waivers.vlt build/
  WAIVERS=(../waivers.vlt)
fi

{
  echo "date:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "commit: $(git rev-parse --short HEAD 2> /dev/null || echo unknown)"
  echo "tool:   $(verilator --version)"
  echo "host:   $(uname -srm)"
  echo "top:    $TOP"
  echo "files (sha256), in compile order:"
  (cd build/dut && sha256sum rtl/cpu_pkg.sv rtl/base_alu.svh rtl/logical_alu.svh \
     rtl/arithmetic_alu.svh rtl/CPU.svh files.f && cd .. && sha256sum tb_cpu.sv)
  if [ -f waivers.vlt ]; then sha256sum waivers.vlt; fi
} > build_info.txt

# Step 1: lint DUT and test program together, as Phase 2 linted the DUT alone
status=0
(cd build/dut && verilator --lint-only -Wall "${WAIVERS[@]}" -f files.f ../tb_cpu.sv \
   --top-module $TOP) > lint.log 2>&1 || status=$?
if [ "$status" -eq 0 ] && [ ! -s lint.log ]; then
  echo "LINT: PASS (no messages)" | tee -a lint.log
else
  echo "LINT: FAIL - give every message a disposition in elab_report.md" | tee -a lint.log
  exit 1
fi

# Step 2: compile and elaborate into the simulation binary (warnings stay fatal)
status=0
(cd build/dut && verilator --binary -Wall "${WAIVERS[@]}" -f files.f ../tb_cpu.sv \
   --top-module $TOP -Mdir ../obj -o $TOP -j 0) > build.log 2>&1 || status=$?
if [ "$status" -ne 0 ] || [ ! -x build/obj/$TOP ]; then
  echo "BUILD: FAIL - see build.log" | tee -a build.log
  exit 1
fi

# Elaboration evidence: the classes Verilator built from cpu_pkg
{
  echo "elaborated classes:"
  ls build/obj | sed -n 's/.*cpu_pkg__03a__03a\([A-Za-z_]*\)__Vclpkg.*/  cpu_pkg::\1/p' | sort -u
} >> build_info.txt
echo "BUILD: PASS (build/obj/$TOP)" | tee -a build.log
