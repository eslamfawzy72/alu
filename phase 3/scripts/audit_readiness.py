#!/usr/bin/env python3
"""Report readiness without claiming simulated coverage."""
import csv
from pathlib import Path
p=Path(__file__).resolve().parents[1]
with (p/'planning/verification_matrix.csv').open(newline='', encoding='utf-8-sig') as f: rows=list(csv.DictReader(f))
with (p/'planning/directed_scenarios.csv').open(newline='', encoding='utf-8-sig') as f: scenarios=list(csv.DictReader(f))
from collections import Counter
print('Verification items:',len(rows), Counter(r['Plan status'] for r in rows))
print('Directed scenarios:',len(scenarios),Counter(r['Status'] for r in scenarios))
print('DUT status: UNCONNECTED; simulation results: NONE')
