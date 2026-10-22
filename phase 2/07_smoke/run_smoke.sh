#!/usr/bin/env bash
# Smoke simulation: compile the RTL with the smoke test and run it.
# exit: 0 when the log shows the expected SUMMARY and exactly 2 %Error lines, 1 otherwise
cd "$(dirname "$0")/../04_rtl" || exit 1
EXPECT_SUMMARY="SUMMARY pass=91 fail=0"   # 07_smoke/smoke_result.md
EXPECT_ERRORS=2                           # one $error per invalid code, 4'b1110 and 4'b1111 (D-009)
# GNU Make cannot build in a path with a space ("phase 2"), so the C++ goes to a temp folder
OBJ=$(mktemp -d)
trap 'rm -rf "$OBJ"' EXIT
verilator --binary -f files.f ../07_smoke/smoke_tb.sv --top-module smoke_tb \
  -Mdir "$OBJ" -o smoke > ../07_smoke/build.log 2>&1 \
  || { echo "BUILD FAILED - see 07_smoke/build.log"; exit 1; }
"$OBJ"/smoke +verilator+error+limit+1000 | tee ../07_smoke/smoke_log.txt | grep -v "^PASS"
echo "Full log: 07_smoke/smoke_log.txt   (expected: $EXPECT_ERRORS %Error lines for the invalid codes, $EXPECT_SUMMARY)"

errors=$(grep -c '%Error' ../07_smoke/smoke_log.txt)
if tr -d '\r' < ../07_smoke/smoke_log.txt | grep -qx "$EXPECT_SUMMARY" && [ "$errors" -eq "$EXPECT_ERRORS" ]; then
  echo "SMOKE: PASS"
else
  echo "SMOKE: FAIL ($errors %Error lines; SUMMARY line: $(grep '^SUMMARY' ../07_smoke/smoke_log.txt || echo none))"
  exit 1
fi
