# RISC-V Verification Framework

A lightweight SystemVerilog and Python verification environment for a simplified 32-bit, single-cycle RISC-V-style processor.

The processor is the DUT. The main focus is verification: directed tests, a structured testbench, an independent reference model, randomized testing, assertions, functional coverage, regression automation, waveform debugging, and fault injection.

## Supported instructions

| Instruction | Operation |
|---|---|
| ADD | `rd = rs1 + rs2` |
| SUB | `rd = rs1 - rs2` |
| AND | `rd = rs1 & rs2` |
| OR | `rd = rs1 \| rs2` |
| XOR | `rd = rs1 ^ rs2` |
| ADDI | `rd = rs1 + sign_extended(immediate)` |

The design includes a 32-bit PC, 32 registers, two register read ports, one write port, internal instruction memory, and an x0 register hardwired to zero. Unsupported instructions must not write architectural state.

## Verification environment

```text
Generator → Driver → DUT → Monitor → Scoreboard
                         ↓
              Assertions and Coverage
```

- `rtl/`: ALU, register file, decoder, and CPU RTL
- `tb/`: directed tests and structured SystemVerilog environment
- `scripts/`: Python reference model, random generator, regression, and fault injection
- `docs/`: verification plan and fault-injection report
- `results/`: logs and generated reports

The Python model independently predicts the PC and all 32 registers. Randomized tests use reproducible seeds and compare RTL state against the model. Assertions check x0, PC progression, valid writes, and unsupported instructions.

## Running the project

Run the complete regression:

```bash
python3 scripts/regression.py --tests 10 --seed 42 --instructions 100
```

Run one reproducible randomized test:

```bash
python3 scripts/randomized_test.py --count 100 --seed 42
```

Run the reference-model comparison:

```bash
python3 scripts/validate_reference_model.py
```

Run fault-injection experiments:

```bash
python3 scripts/fault_injection.py
```

Open generated waveforms with GTKWave:

```bash
gtkwave phase2.vcd
```

## Results

Latest recorded regression:

```text
14/14 tests passed
100.00% pass rate
0.677 seconds runtime
```

Fault injection detected 3/3 injected defects: an incorrect ALU ADD operation, an incorrect PC increment, and an unsupported decoder write.

Reports are generated in `results/reports/` and logs in `results/logs/`.

## Limitations and future work

- No branches, loads, stores, or other control-flow instructions yet
- Instruction memory is currently an internal simulation array
- Coverage is procedural rather than UCIS-based
- Future work includes broader RV32I support, memory interfaces, CI integration, and aggregated coverage across randomized tests
