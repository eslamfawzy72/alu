#!/usr/bin/env bash
# Smoke simulation: compile the RTL with the smoke test and run it.
cd "$(dirname "$0")/../04_rtl" || exit 1
verilator --binary -f files.f ../07_smoke/smoke_tb.sv --top-module smoke_tb \
  -Mdir ../07_smoke/obj_dir -o smoke > ../07_smoke/build.log 2>&1 \
  || { echo "BUILD FAILED - see 07_smoke/build.log"; exit 1; }
../07_smoke/obj_dir/smoke +verilator+error+limit+1000 | tee ../07_smoke/smoke_log.txt | grep -v "^PASS"
echo "Full log: 07_smoke/smoke_log.txt   (expected: 2 %Error lines for the invalid codes, SUMMARY pass=91 fail=0)"
