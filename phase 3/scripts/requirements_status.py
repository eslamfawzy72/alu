#!/usr/bin/env python3
"""Source-grounded requirement coverage ledger. No simulation claims."""
import csv, pathlib, argparse
p=pathlib.Path(__file__).resolve().parents[1]
a=argparse.ArgumentParser();a.add_argument('--dut',type=pathlib.Path,help='optional delivered Phase 2 source root for manual review');args=a.parse_args()
with (p/'planning/verification_matrix.csv').open(encoding='utf-8-sig',newline='') as f: rows=list(csv.DictReader(f))
output=p/'results/requirements_readiness.csv'
block={'TC-004','TC-005','TC-009','TC-010','TC-011','TC-012','TC-013','TC-014','TC-015','TC-016','TC-017','TC-018','TC-019','TC-021','TC-027','TC-028'}
bitwise={'TC-006','TC-007','TC-008'}
with output.open('w',encoding='utf-8',newline='') as f:
 w=csv.writer(f);w.writerow(['verification_item','phase1_test','requirement_ids','prepared_mechanism','execution_status','notes'])
 for r in rows:
  tc=r['Phase 1 test ID'];state='BLOCKED_SPEC' if tc in block else 'NOT_RUN'
  mechanism='numeric_oracle_and_scoreboard' if tc in bitwise else ('directed_stimulus_only' if tc in block else 'adapter_hook_or_source_review')
  w.writerow([r['Verification item ID'],tc,r['Requirement IDs'],mechanism,state,'No Phase 2 execution evidence'])
print('Wrote',output,'for',len(rows),'verification items; no PASS recorded')
if args.dut: print('Phase 2 sources to review:',args.dut,'(this script does not infer compliance from filenames)')
