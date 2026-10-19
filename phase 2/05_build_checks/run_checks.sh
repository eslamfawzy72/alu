#!/usr/bin/env bash
# Steps 10-11: compile, elaborate and lint the RTL. Run from anywhere.
cd "$(dirname "$0")/../04_rtl" || exit 1
OUT=../05_build_checks
echo "== verilator lint (-Wall) ==" | tee $OUT/lint.log
verilator --lint-only -Wall -f files.f --top-module cpu_pkg 2>&1 | tee -a $OUT/lint.log
if [ "${PIPESTATUS[0]}" -eq 0 ]; then echo "LINT: PASS (no messages)" | tee -a $OUT/lint.log
else echo "LINT: FAIL - write each message into 06_repairs/repair_log.md" | tee -a $OUT/lint.log; exit 1; fi
if command -v verible-verilog-lint >/dev/null; then
  echo "== verible style lint ==" | tee -a $OUT/lint.log
  verible-verilog-lint rtl/*.sv rtl/*.svh 2>&1 | tee -a $OUT/lint.log
fi
