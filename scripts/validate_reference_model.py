#!/usr/bin/env python3
"""Validate the Python reference model against the RTL CPU simulation."""

from __future__ import annotations

import re
import subprocess
import tempfile
from pathlib import Path

from reference_model import CPUModel, directed_program, encode_addi, encode_rtype


ROOT = Path(__file__).resolve().parents[1]
RTL = [
    ROOT / "rtl/alu.sv",
    ROOT / "rtl/register_file.sv",
    ROOT / "rtl/decoder.sv",
    ROOT / "rtl/cpu.sv",
]
CPU_TB = ROOT / "tb/cpu_tb.sv"


def validate_model_only() -> None:
    """Check immediate sign extension and dependent arithmetic independently."""
    program = [
        encode_addi(1, 0, -5),
        encode_addi(2, 1, 7),
        encode_rtype(0x00, 2, 1, 0x0, 3),
        encode_rtype(0x20, 1, 2, 0x0, 4),
    ]
    model = CPUModel()
    model.run(program)

    expected = {1: 0xFFFFFFFB, 2: 2, 3: 0xFFFFFFFD, 4: 7}
    actual = {index: model.regs[index] for index in expected}
    if actual != expected:
        raise AssertionError(f"model-only validation failed: {actual} != {expected}")

    if model.pc != len(program) * 4 or model.regs[0] != 0:
        raise AssertionError("model-only PC or x0 invariant failed")


def run_rtl() -> dict[int, int]:
    with tempfile.TemporaryDirectory(prefix="riscv-reference-") as temp_dir:
        sim = Path(temp_dir) / "cpu_sim"
        compile_cmd = ["iverilog", "-g2012", "-o", str(sim), *map(str, RTL), str(CPU_TB)]
        subprocess.run(compile_cmd, cwd=ROOT, check=True, capture_output=True, text=True)
        result = subprocess.run(["vvp", str(sim)], cwd=ROOT, check=True,
                                capture_output=True, text=True)

    matches = re.findall(r"^x(\d+) = (\d+)$", result.stdout, re.MULTILINE)
    registers = {int(index): int(value) for index, value in matches}
    if not registers:
        raise RuntimeError("RTL simulation did not report register values")
    return registers


def main() -> int:
    validate_model_only()

    model = CPUModel()
    model.run(directed_program())
    expected = {index: model.regs[index] for index in range(9)}
    actual = run_rtl()

    mismatches = {
        index: (expected[index], actual.get(index))
        for index in expected
        if actual.get(index) != expected[index]
    }
    if mismatches:
        print(f"REFERENCE MODEL: FAIL: {mismatches}")
        return 1

    print("REFERENCE MODEL: model-only validation PASS")
    print("REFERENCE MODEL: RTL comparison PASS")
    for index in range(1, 9):
        print(f"x{index}: expected={expected[index]} actual={actual[index]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
