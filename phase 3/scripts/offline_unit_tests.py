#!/usr/bin/env python3
"""Basic offline tests of the Phase 1 mapping and directed case quantities.
No actual SystemVerilog code is executed by this script.
"""
import csv
from pathlib import Path
p=Path(__file__).resolve().parents[1]
rows=list(csv.DictReader((p/'planning/requirement_execution_map.csv').open()))
assert len(rows)==28
op={6:7,7:8,8:9,9:10,10:11,11:12,12:13,13:0,14:1,15:2,16:3,17:4,18:5,19:6}
assert set(op.values())==set(range(14))
for tid,opcode in op.items():
 x=next(r for r in rows if r['Phase 1 TC']==f'TC-{tid:03}')
 assert f'Opcode {opcode}:' in x['Planned verification procedure'],x
sv=(p/'tb/alu_test.sv').read_text()
assert sv.count('run_case(')>=13
assert 'i<14' in sv and 'i<16' in sv
print('Offline mapping and directed stimulus checks passed (28 TC IDs; all 14 opcodes).')
print('NOT an SV compilation or simulation.')
