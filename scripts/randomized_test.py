#!/usr/bin/env python3
"""Generate and run a reproducible randomized CPU program against the RTL."""

from __future__ import annotations

import argparse
import json
import random
import re
import subprocess
import tempfile
from pathlib import Path

from reference_model import CPUModel, encode_addi, encode_rtype


ROOT = Path(__file__).resolve().parents[1]
RTL = [
    ROOT / "rtl/alu.sv",
    ROOT / "rtl/register_file.sv",
    ROOT / "rtl/decoder.sv",
    ROOT / "rtl/cpu.sv",
]
RANDOM_TB = ROOT / "tb/random_tb.sv"

R_FUNCTS = {
    "ADD": (0x00, 0x0),
    "SUB": (0x20, 0x0),
    "AND": (0x00, 0x7),
    "OR": (0x00, 0x6),
    "XOR": (0x00, 0x4),
}
EDGE_IMMEDIATES = (-2048, -1, 0, 1, 2047)


def choose_register(rng: random.Random, recent: list[int], allow_zero: bool = True) -> int:
    if recent and rng.random() < 0.70:
        return rng.choice(recent)
    if allow_zero and rng.random() < 0.12:
        return 0
    return rng.randrange(1, 32)


def generate_program(count: int, seed: int) -> tuple[list[int], list[str]]:
    rng = random.Random(seed)
    program: list[int] = []
    assembly: list[str] = []
    recent_destinations: list[int] = []

    for index in range(count):
        force_edge = index < len(EDGE_IMMEDIATES) or rng.random() < 0.12
        if force_edge:
            immediate = EDGE_IMMEDIATES[index % len(EDGE_IMMEDIATES)]
        else:
            immediate = rng.randint(-2048, 2047)

        if index % 7 == 0 or rng.random() < 0.45:
            rd = 0 if rng.random() < 0.10 else rng.randrange(1, 32)
            rs1 = choose_register(rng, recent_destinations)
            program.append(encode_addi(rd, rs1, immediate))
            assembly.append(f"ADDI x{rd}, x{rs1}, {immediate}")
        else:
            operation = rng.choice(list(R_FUNCTS))
            funct7, funct3 = R_FUNCTS[operation]
            rd = 0 if rng.random() < 0.10 else rng.randrange(1, 32)
            rs1 = choose_register(rng, recent_destinations)
            rs2 = choose_register(rng, recent_destinations)
            program.append(encode_rtype(funct7, rs2, rs1, funct3, rd))
            assembly.append(f"{operation} x{rd}, x{rs1}, x{rs2}")

        if rd != 0:
            recent_destinations.append(rd)
            recent_destinations = recent_destinations[-8:]

    return program, assembly


def run_rtl(program_file: Path, count: int) -> tuple[dict[int, int], int, str]:
    with tempfile.TemporaryDirectory(prefix="riscv-random-") as temp_dir:
        sim = Path(temp_dir) / "random_sim"
        compile_cmd = ["iverilog", "-g2012", "-o", str(sim), *map(str, RTL), str(RANDOM_TB)]
        subprocess.run(compile_cmd, cwd=ROOT, check=True, capture_output=True, text=True)
        result = subprocess.run(
            ["vvp", str(sim), f"+PROGRAM={program_file}", f"+COUNT={count}"],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )

    registers = {
        int(index): int(value, 16)
        for index, value in re.findall(r"^R\[(\d+)\]=([0-9a-fA-F]+)$", result.stdout, re.MULTILINE)
    }
    pc_match = re.search(r"^PC=([0-9a-fA-F]+)$", result.stdout, re.MULTILINE)
    if len(registers) != 32 or pc_match is None:
        raise RuntimeError("randomized RTL test did not report all architectural state")
    return registers, int(pc_match.group(1), 16), result.stdout


def save_failure(output_dir: Path, seed: int, program: list[int], assembly: list[str], output: str) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    hex_file = output_dir / f"failure_seed_{seed}.hex"
    asm_file = output_dir / f"failure_seed_{seed}.asm"
    log_file = output_dir / f"failure_seed_{seed}.log"
    metadata_file = output_dir / f"failure_seed_{seed}.json"
    hex_file.write_text("".join(f"{instruction:08x}\n" for instruction in program))
    asm_file.write_text("\n".join(assembly) + "\n")
    log_file.write_text(output)
    metadata_file.write_text(json.dumps({"seed": seed, "count": len(program)}, indent=2) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--count", type=int, default=100, help="number of instructions")
    parser.add_argument("--seed", type=int, default=42, help="reproducible random seed")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "results/randomized")
    args = parser.parse_args()

    if args.count <= 0:
        parser.error("--count must be positive")

    program, assembly = generate_program(args.count, args.seed)
    model = CPUModel()
    model.run(program)
    expected_registers = dict(enumerate(model.regs))
    expected_pc = model.pc

    try:
        args.output_dir.mkdir(parents=True, exist_ok=True)
        program_file = args.output_dir / f"program_seed_{args.seed}.hex"
        program_file.write_text("".join(f"{instruction:08x}\n" for instruction in program))
        actual_registers, actual_pc, rtl_output = run_rtl(program_file, args.count)
    except subprocess.CalledProcessError as error:
        print(f"RANDOM TEST FAIL: seed={args.seed} simulator command failed")
        print(error.stdout or error.stderr)
        save_failure(args.output_dir, args.seed, program, assembly, error.stdout or error.stderr)
        return 1

    mismatches = {
        f"x{index}": (expected_registers[index], actual_registers[index])
        for index in range(32)
        if expected_registers[index] != actual_registers[index]
    }
    if expected_pc != actual_pc:
        mismatches["pc"] = (expected_pc, actual_pc)

    if mismatches:
        print(f"RANDOM TEST FAIL: seed={args.seed} count={args.count}")
        print(f"mismatches={mismatches}")
        save_failure(args.output_dir, args.seed, program, assembly, rtl_output)
        return 1

    print(f"RANDOM TEST PASS: seed={args.seed} count={args.count}")
    print(f"final_pc=0x{actual_pc:08x} x0=0x{actual_registers[0]:08x}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
