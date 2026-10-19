# Verification Plan

## 1. Scope and objective

Verify the publicly observable behavior and required class/API organization of the SystemVerilog ALU and CPU, using the assignment and Phase 1 records as the expected-behavior baseline. The design under test is accessed through the CPU API; the testbench does not derive expected results from its implementation.

The assignment specifies 14 opcodes (`4'b0000` through `4'b1101`), a base class, two ALU subclasses, a CPU class, a package, and a demonstration program. Requirements are linked using the original `FR`, `IF`, `OP`, `CA` and `TC` IDs.

## 2. Verification approach and priorities

| Priority | Focus | Verification method | Current readiness |
|---|---|---|---|
| High | AND/OR/XOR observable results (OP-008..OP-010) | Directed and reproducible random tests, bitwise oracle | Spec-defined; DUT adapter pending |
| High | CPU.Calc contract and opcode dispatch (FR-010, IF-012/014) | API calls, route/integration checks | Interface signature needs confirmation (Q-012) |
| High | Arithmetic, carry/borrow, shifts and rotations | Directed/random tests once source semantics are resolved | Blocked by Q-002..Q-006, Q-017 |
| Medium | Reset and initialize | State checks | Blocked by Q-007/Q-008 |
| Medium | Class hierarchy, required methods and package | Compile/static review | Available after Phase 2 source delivery |
| Medium | Unassigned opcodes and errors | Negative tests | Blocked by Q-009 |

## 3. Responsibilities and interfaces

Verification planning maintains test scenarios, scoreboards, coverage and evidence. Interface details, missing operation semantics and any approved clarifications are recorded through the existing Phase 1 questions. The source implementation is integrated only through `tb/alu_dut_adapter.sv`. Actual names/roles and dates are not supplied and are not invented here.

## 4. Deliverables

- **Verification matrix** (`verification_matrix.csv`): maps all 28 Phase 1 candidate tests into VI items.
- **Directed tests** (`directed_scenarios.csv`): 42 nominal, boundary and corner scenarios, including blocked entries.
- **Constrained/random strategy** (`random_strategy.csv`): current bitwise random stream and gated expansion.
- **Coverage** (`coverage_plan.csv`): 16 verification coverage items.
- **Checkers** (`checker_plan.csv`): active/pending expected-value checks.
- **Open questions** (`open_questions.csv`): mirrors all 18 supplied Phase 1 open questions.
- **Traceability** (`traceability.csv`): source-to-phase-3 relationships.
- **Testbench** (`../tb/`): transaction, driver, DUT adapter, monitor, reference model, scoreboard, coverage, test runner and isolated mock self-test.

## 5. Stimulus and checks

Each directed operation has nominal, zero/boundary and alternating-bit cases; these are planning candidates, not claims that all 14 can already be checked. Bitwise AND/OR/XOR use signed `int` operands as 32-bit bit patterns and a separate reference model. Random bitwise stimulus uses a deterministic seeded linear-congruential generator and a configurable iteration count. Only a **checked** comparison contributes to pass or coverage; a missing oracle must be blocked, never counted as passing.

The current testbench records generated, compared, blocked, and passed/failed counts per opcode; only the candidate AND/OR/XOR model is enabled by default. Stimulus coverage is not functional sign-off coverage. CSV coverage rows for remaining operations are planning targets, not measured results.

## 6. Exit criteria and evidence

| ID | Exit criterion | Evidence |
|---|---|---|
| EC-001 | Each applicable Phase 1 requirement/test has a verification disposition | `verification_matrix.csv` |
| EC-002 | All approved expected-value scenarios executed; zero unexplained mismatches | Simulator test log |
| EC-003 | All approved operation and boundary coverage targets reached or formally waived | Coverage summary/report |
| EC-004 | Open behavior questions closed or explicitly waived with blocked tests documented | `open_questions.csv` and decision records |
| EC-005 | Testbench adapter matches the released CPU API; regression compiles/runs | Compile log / invocation |
| EC-006 | Any testbench self-validation and failure-detection checks are recorded | `results/` evidence |

**Sign-off: not achieved.** No Phase 2 DUT, confirmed interface binding or regression evidence is provided in this package.

## 7. Principal dependencies

- **Q-001/Q-012:** enum type and precise `Calc` call/return contract (adapter integration).
- **Q-002/Q-004:** operand ordering, width, arithmetic overflow (oracle).
- **Q-003:** shift/rotation count (oracle).
- **Q-005/Q-006/Q-016:** carry/borrow source and observations (multi-step arithmetic checks).
- **Q-007/Q-008:** initialize and reset resulting state (state checks).
- **Q-009/Q-017:** unsupported opcode and select-B semantics (negative/selection tests).

## 8. Verification environment overview

```text
Directed / random test generator
              |
         ALU transaction
              |
     Driver -> DUT adapter --> CPU class in cpu_pkg (black box)
              |                            |
              +---------- actual result <-+
              |
  Monitor(actual) + oracle(expected) -> Scoreboard -> Pass/fail counters
              |
      Checked sample counters / summary
```

See `../tb/README.md` for binding details and compilation order.
