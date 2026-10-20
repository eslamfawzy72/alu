# Phase 3: Verification

Phase 3 checks that the Phase 2 design does what Phase 1 specifies. It delivers a verification plan, the self-checking test program required by FR-013, and the regression results.

**Rule:** Phase 1 decides what is correct and Phase 3 decides how to test it. Every expected value and pass criterion in Phase 3 must come from a Phase 1 file and cite its ID (TC-, OP-, D- or a golden vector). If Phase 3 needs something that Phase 1 has not provided, it asks Phase 1 (step 2). Phase 3 does not fill the gap itself, and it keeps no copies of Phase 1 or Phase 2 files.

## Files

| File | Content |
|---|---|
| `verification_plan.md` | inputs used, readiness result, how the test map is laid out, stimulus, checking, coverage, exit criteria, status |
| `test_map.csv` | where each TC, OP and D-ID is checked in `tb/tb_cpu.sv`, how, its coverage bins, and anything not tested with the reason |
| `questions_for_phase1.md` | what Phase 3 asked Phase 1 in the last readiness check |
| `tb/tb_cpu.sv` | the test program: Phase 1 golden vectors, one test per TC, random test with a reference model, coverage |
| `run.sh` | builds and runs the test program against the Phase 2 DUT, checks the log, writes `results/` |
| `results/` | written by `run.sh`: `summary.txt`, `sim.log`, `build.log`, `run_info.txt` (not present until the first run) |

## Inputs

Read from the other phase folders as they are.

| From | File | Used for |
|---|---|---|
| Phase 1 | `../phase 1/ALU_Verification_Requirements.csv` | the 28 tests and their pass criteria |
| Phase 1 | `../phase 1/ALU_Golden_Vectors.csv` | exact expected values (the program reads this file at run time) |
| Phase 1 | `../phase 1/alu_spec.json` | API, enum and operation semantics (reference model) |
| Phase 1 | `../phase 1/ALU_Design_Decisions.csv` | D-001 to D-018: state, invalid codes, display format, test program content |
| Phase 1 | `../phase 1/ALU_Open_Questions.csv` | must have no open question |
| Phase 2 | `../phase 2/08_release/phase2_handoff.md` | DUT files and filelist (`../phase 2/04_rtl/files.f`) |
| Phase 2 | `../phase 2/08_release/phase2_handoff.md` | DUT behaviour the tests must allow for (flags F1, F2) |

## Steps

### 1. Read the inputs

Read every file in the Inputs table. Note the Phase 1 `spec_version` (in `alu_spec.json`) and the Phase 2 git tag (in `phase2_handoff.md`).

### 2. Readiness check: ask Phase 1 for anything missing

Check each row. A failed row is a question for Phase 1.

| # | Phase 3 needs | Look in | Ready when |
|---|---|---|---|
| R1 | a pass criterion for every TC | Verification Requirements | each TC states a concrete criterion, or names the D-ID or golden vectors that make it concrete |
| R2 | exact expected values for every operation | Golden Vectors | at least one vector per operation; every row has "Expected result" and "Expected carry" |
| R3 | semantics for every operation, including flags and boundaries | `alu_spec.json` → `operations`, `data_semantics` | no operation is undefined or "not specified" |
| R4 | the API the tests call | `alu_spec.json` → `classes`, `types` | every class, method and enum member used has a full declaration |
| R5 | the state after construction, `initialize()` and `Reset()` | Design Decisions | a value for every property |
| R6 | the behaviour for invalid inputs | Design Decisions | defined result, state and report |
| R7 | the output format of anything the tests compare | Design Decisions | defined |
| R8 | no open questions | Open Questions | no row has Status "Open" |
| R9 | approved decisions | Design Decisions → "Approved by", "Date" | filled in |
| R10 | a design to test | `phase2_handoff.md` | it names a git tag and a build list that exists (`04_rtl/files.f`), and its lint and smoke results passed |

Write every failed row to `questions_for_phase1.md` (or report R10 to Phase 2). Use one numbered question per gap, cite the ID, and say what answer is needed. This is the same format as `phase 2/01_spec_check/questions_for_phase1.md`.

- **R1 to R8, R10 failed:** blocking. Stop until Phase 1 answers by updating its files with the same IDs, then repeat from step 1.
- **R9 failed:** a condition. Continue, mark all results provisional, and list it in `verification_plan.md` section 3.

Record the result in `verification_plan.md` section 3.

### 3. Write the plan

Update `verification_plan.md` and `test_map.csv`. The map has one row per Phase 1 TC, OP and D-ID: what is checked, which test checks it, how, which Phase 1 IDs the expected values come from, and which coverage bins it fills. Anything left untested gets a reason in "Not tested? reason", never an empty row. Do not copy Phase 1 text into the plan or the map; cite the ID instead.

### 4. Write the test program

Update `tb/tb_cpu.sv`. There is one task per TC (or group of TCs), named after the TC. Each check is counted under its TC and cites the D-ID or OP-ID it uses. Golden vectors are read from the Phase 1 CSV and never typed in. The reference model must reproduce every golden vector before it is used. Stimulus choices (extra corner values, random settings, coverage bins) belong to Phase 3. Expected values do not.

### 5. Run

On a machine with Verilator 5.020 or later:

```sh
bash run.sh +CHECKER_SELFTEST   # must end with "checker self-test OK"
bash run.sh                     # the regression; must end with "Phase 3 regression: PASS"
```

`+SEED=<n>` and `+RANDOM_N=<n>` (default 5000) change the random test. Below about 3000 random calls, some shift-amount coverage bins can stay empty, and the run then fails on coverage.

### 6. Triage every FAIL

- **"reference model disagrees with Phase 1 golden vector N":** Phase 3 has misread the spec. Fix the model so it follows `alu_spec.json`. If `alu_spec.json` and the vector contradict each other, ask Phase 1.
- **A DUT check fails and the Phase 1 source it cites is clear:** this is a DUT bug. Report it to Phase 2 with the TC, the inputs, the value received, the value expected and the Phase 1 ID.
- **A DUT check fails and the Phase 1 source is unclear:** ask Phase 1 (step 2).

Never edit an expected value to make a test pass.

### 7. Record

Commit `results/` and update `verification_plan.md` section 9. Sign-off needs the exit criteria in section 8.

## Redoing Phase 3 after a change

| Change | What to do |
|---|---|
| Phase 1 changes golden vectors | nothing to edit; run step 5 |
| Phase 1 changes a decision or the semantics | steps 1 and 2; update the checks and model lines that cite that ID; step 5 |
| Phase 1 adds or removes a TC | steps 1 to 5 for that TC |
| Phase 2 delivers a new DUT | step 2 (R10), then step 5 |
