#!/usr/bin/env python3
"""Verify Phase 3 CSV identifiers, links and blocked/test consistency."""
from pathlib import Path
import csv, sys
ROOT=Path(__file__).resolve().parents[1]
P=ROOT/'planning'
def read(name):
    with (P/name).open(encoding='utf-8',newline='') as f:
        return list(csv.DictReader(f))
v=read('verification_matrix.csv');s=read('directed_scenarios.csv');c=read('coverage_plan.csv');t=read('traceability.csv')
assert len(v)==28 and len(s)==42 and len(c)==16
for records,key in [(v,'Verification item ID'),(s,'Scenario ID'),(c,'Coverage ID'),(t,'Trace ID')]:
    ids=[x[key] for x in records];assert len(ids)==len(set(ids)),f'duplicate {key}'
assert {x['Phase 1 test ID'] for x in v}=={f'TC-{n:03}' for n in range(1,29)}
assert {x['Operation ID'] for x in s}=={f'OP-{n:03}' for n in range(1,15)}
for x in s:
    if x['Status']=='PLANNED':
        assert x['Operation ID'] in {'OP-008','OP-009','OP-010'} and x['Expected source']==x['Operation ID']
    else:
        assert x['Status']=='BLOCKED' and x['Expected source']=='PENDING'
assert len(t)==len(v)+len(s)+len(c)
print(f'Plan validated: {len(v)} VI, {len(s)} TS, {len(c)} CI, {len(t)} VTR')
