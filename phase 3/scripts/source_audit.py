#!/usr/bin/env python3
"""Source organization/keyword audit, not an SV compiler or proof of conformance."""
import argparse,re,pathlib,sys
p=argparse.ArgumentParser();p.add_argument('phase2_path',type=pathlib.Path);args=p.parse_args()
files=list(args.phase2_path.rglob('*.sv'))
if not files:sys.exit('NOT RUN: no SystemVerilog files found')
text={f:f.read_text(errors='replace') for f in files}
classes=('base_alu','logical_alu','arithmetic_alu','CPU')
errors=[]
for name in classes:
  matches=[f for f,s in text.items() if re.search(r'\bclass\s+'+re.escape(name)+r'\b',s)]
  if len(matches)!=1:errors.append(f'{name} declared in {len(matches)} files (expected 1)')
  print(f'{name}: '+(', '.join(str(x) for x in matches) or 'NOT FOUND'))
if not any(re.search(r'\bpackage\s+cpu_pkg\b',s) for s in text.values()):errors.append('cpu_pkg missing')
for name in ('logical_alu','arithmetic_alu'):
  if not any(re.search(r'\bclass\s+'+name+r'\s+extends\s+base_alu\b',s) for s in text.values()):errors.append(f'{name} inheritance not found')
for name in ('operand_A','operand_B','alu_op','alu_result','load_operand_A','load_operand_B','initialize','display','Reset','Calc','l_alu','a_alu'):
  if not any(re.search(r'\b'+name+r'\b',s) for s in text.values()):errors.append(f'identifier {name} missing')
print('AUDIT:', 'FAIL: '+ '; '.join(errors) if errors else 'Static keyword/structure scan OK (compile/review still needed)')
sys.exit(bool(errors))
