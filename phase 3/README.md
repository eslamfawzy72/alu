# Phase 3 — Verification Planning and Environment

Verification plan and class-based SystemVerilog testbench for the ALU assignment. The environment is independent of the CPU implementation; it is ready for Phase 2 integration, **not verified against a DUT**.

- `planning/`: verification plan, Phase 1 traceability, 28-test execution mapping, directed/random strategies, coverage, checkers, pending clarification decisions.
- `tb/`: transaction, test generator, driver, DUT adapter, monitor, oracle, scoreboard, coverage and API probes. See `tb/README.md`.
- `scripts/`: planning validator, requirements readiness, source audit, offline mapping tests and testbench-source integrity checks.
- `results/`: evidence placeholders; no simulated PASS results.

From the `phase 3/` folder run `python scripts/validate_plan.py` and `python scripts/verify_tb_sources.py`. Those checks inspect documentation/source structure only; SystemVerilog compilation requires an SV-capable simulator. Run `python scripts/offline_unit_tests.py` for mapping tests. Run `python scripts/source_audit.py /path/to/phase2` to inspect Phase 2 class/package organization once available.

The runner generates 144 directed stimulus cases (10 x 14 + 4 invalid opcode probes) and defaults to 300 seeded randomized transactions. By default only AND/OR/XOR have candidate expected-value comparisons supported by the Phase 1 bitwise interpretation; the others are explicitly blocked until decisions are approved. `+PLAN_ONLY` can enumerate without a DUT but **never counts as DUT verification**.

**Integration:** bind the adapter using the confirmed `cpu_pkg` API, compile with an SV simulator, execute, and record results. See `tb/integration_checks.md`. No pretend RTL, fabricated simulation or undocumented behavior is included.

For isolated testbench fault-detection tests, see `tb/selftest/README.md`. The mock is never used for actual DUT sign-off.
