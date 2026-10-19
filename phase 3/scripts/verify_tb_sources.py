#!/usr/bin/env python3
"""Offline package integrity audit; never confused with SV compilation."""
from pathlib import Path
import csv
p=Path(__file__).resolve().parents[1];tb=p/'tb'
needed=['alu_tb_pkg.sv','alu_rules.svh','alu_dut_adapter.sv','alu_driver.sv','alu_monitor.sv','alu_test.sv','tb_filelist.f','README.md','integration_checks.md']
for n in needed:assert (tb/n).is_file(),n
s={n:(tb/n).read_text() for n in needed}
for name in ['alu_oracle','alu_scoreboard','alu_coverage'] :assert 'class '+name in s['alu_tb_pkg.sv']
for name in ['alu_driver','alu_monitor','alu_dut_adapter']:assert 'class '+name in s[name+'.sv']
assert 'PLAN_ONLY' in s['alu_test.sv']
assert 'P3_NOT_RUN' in s['alu_dut_adapter.sv'] and 'P3_FAIL' in s['alu_tb_pkg.sv']
assert 'if(!ready)' in s['alu_test.sv'] and 'sb.blocked' in s['alu_test.sv']
assert 'if(!dut.connected())' in s['alu_test.sv']
assert all(f'4\'h{n:x}' in s['alu_tb_pkg.sv'] for n in range(14))
with (p/'planning/requirement_execution_map.csv').open() as f:
 rows=list(csv.DictReader(f));assert len(rows)==28
 assert len({r['Phase 1 TC'] for r in rows})==28
print('Offline structural checks passed: components, 14 opcodes, 28 TC mappings.')
print('NOT a SystemVerilog compile or DUT test; simulator execution is still required.')
