# Fault-Injection Bug Reports

Fault injection mutates temporary RTL copies. The working RTL is never
modified. Run the experiment with:

```text
python3 scripts/fault_injection.py
```

## Experiments

| Injected fault | Detection method | Root cause exposed |
|---|---|---|
| ALU ADD changed to SUB | Scoreboard | Incorrect arithmetic/writeback |
| PC increment changed from 4 to 8 | PC assertion and scoreboard | Incorrect instruction address |
| Unsupported R-type enabled `reg_write` | Assertion and scoreboard | Invalid encoding changed state |

The experiment is expected to detect 3/3 faults. Detailed simulator output is
stored under `results/fault_injection/`.

## GTKWave debug workflow

1. Identify the failing test and assertion/scoreboard message.
2. Open the generated VCD with GTKWave.
3. Inspect `clk`, `reset`, `pc`, `instruction`, `alu_control`, `alu_result`,
   `reg_write`, and `writeback_data`.
4. Compare the transaction with the scoreboard and reference-model result.
5. Correct the RTL and rerun the complete regression.

Example:

```bash
gtkwave phase2.vcd
```
