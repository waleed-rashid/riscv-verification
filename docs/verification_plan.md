# Verification Plan

## Scope

The Device Under Test is a simplified single-cycle 32-bit RISC-V-style CPU.
The supported subset is ADD, SUB, AND, OR, XOR, and ADDI. Unsupported
encodings must not modify architectural registers, and x0 must remain zero.

## Verification methods

| Feature | Method | Status |
|---|---|---|
| ALU operations | Directed SystemVerilog tests | Passing |
| Register file | CPU integration checks and x0 assertion | Passing |
| Instruction decoding | Directed programs and scoreboard | Passing |
| PC progression | Assertion and scoreboard | Passing |
| Unsupported instructions | Directed tests and assertions | Passing |
| Independent CPU behavior | Python reference model | Passing |
| Random instruction combinations | Seeded Python generation | Passing |
| Regression automation | Python runner with logs/reports | Passing |
| Fault detection | Temporary RTL mutations | Passing |
| Functional coverage | Procedural coverage counters | Implemented |

## Test scenarios

The directed suite covers every supported instruction, register dependencies,
x0 reads, x0 protection, writeback, reset, and unsupported instructions. The
randomized suite varies instruction count, seed, source/destination registers,
dependencies, x0 usage, and signed 12-bit immediates.

## Assertions

The assertion module checks x0 immutability, valid write targets, unsupported
instruction suppression, four-byte PC progression, and reset PC behavior.

## Coverage goals

Coverage records instruction classes, source/destination register usage,
dependencies, x0 operands, immediate signs, writebacks, unsupported
instructions, and reset cycles. Coverage measures exercised scenarios; it is
not proof of correctness.

The current directed test hits all six instruction classes, but not all
registers or both immediate signs. Randomized testing is intended to improve
those bins. Future work can aggregate coverage across all random seeds.

## Actual results

Latest regression command:

```text
python3 scripts/regression.py --tests 10 --seed 42 --instructions 100
```

Actual result: 14/14 tests passed, 100.00% pass rate, 0.677 seconds runtime.

The latest directed coverage summary reported all 6 instruction classes, 8
writebacks, 2 unsupported instructions, 2 dependencies, and 1 reset cycle.

## Limitations

- No branches, loads, stores, or control-flow instructions are implemented.
- Instruction memory is an internal simulation array.
- Coverage is procedural and does not produce a UCIS database.
- The lightweight environment uses immediate assertions because Icarus has
  limited support for full concurrent SVA syntax.
