# Smoke result

Test: `07_smoke/smoke_tb.sv`: 37 golden vectors (result + carry each = 74 checks), Reset (9 checks), invalid codes 4'b1110 / 4'b1111 (4 checks each), display() on all three ALU classes (printed).

| Run | Date | SUMMARY line | Failing cases | Error lines (expect 2) | Action |
|---|---|---|---|---|---|
| 1 | 2026-10-19 | `SUMMARY pass=91 fail=0` | none | 2 (`invalid operation code 4'b1110`, `… 4'b1111`) | none: go to 09 |
| 2 | 2026-10-20 | `SUMMARY pass=91 fail=0` | none | 2 (same) | rerun by Phase 4 on Verilator 5.020 / WSL2 after the build-path fix (`06_repairs` #1); `smoke_log.txt` identical to run 1. "09" in run 1 is the old step numbering; the next folder is `08_release`. |

display() output (D-010 format):
```
[base_alu] op=OP_SEL_B A=0 B=0 result=0
[logical_alu] op=OP_AND A=12 B=10 result=8
[arithmetic_alu] op=OP_SUB A=9 B=4 result=5 carry=0
```

Boundary cases confirmed: wrap-around (vectors 3, 6, 9), carry out (8, 12), borrow out (15, 18), shift by 32 → 0 (27), logical shift right (30, 31), rotate wrap (32, 35).
