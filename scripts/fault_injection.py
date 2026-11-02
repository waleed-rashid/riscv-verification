#!/usr/bin/env python3
"""Inject temporary RTL faults and verify that the testbench detects them."""

from __future__ import annotations

import json
import subprocess
import tempfile
import time
from dataclasses import asdict, dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL_FILES = ["alu.sv", "register_file.sv", "decoder.sv", "cpu.sv"]
TB_FILES = ["generator.sv", "driver.sv", "monitor.sv", "scoreboard.sv",
            "assertions.sv", "coverage.sv", "phase2_tb.sv"]


@dataclass
class FaultResult:
    name: str
    description: str
    detected: bool
    runtime_seconds: float
    detection_source: str
    output: str


FAULTS = [
    {"name": "alu_add_as_sub", "description": "Replace ALU ADD with subtraction.",
     "file": "alu.sv", "old": "result = a + b;", "new": "result = a - b;"},
    {"name": "pc_increment_by_eight", "description": "Change PC increment from four to eight bytes.",
     "file": "cpu.sv", "old": "assign next_pc = pc + 32'd4;", "new": "assign next_pc = pc + 32'd8;"},
    {"name": "unsupported_rtype_writes", "description": "Allow unsupported R-type writes.",
     "file": "decoder.sv",
     "old": "default: begin\n                        reg_write = 1'b0;\n                        alu_control = 3'b000;",
     "new": "default: begin\n                        reg_write = 1'b1;\n                        alu_control = 3'b000;"},
]


def run_fault(fault: dict[str, str]) -> FaultResult:
    start = time.perf_counter()
    with tempfile.TemporaryDirectory(prefix=f"riscv-fault-{fault['name']}-") as temp_dir:
        temp = Path(temp_dir)
        rtl_dir = temp / "rtl"
        rtl_dir.mkdir()
        for filename in RTL_FILES:
            source = (ROOT / "rtl" / filename).read_text()
            if filename == fault["file"]:
                if fault["old"] not in source:
                    raise RuntimeError(f"fault pattern not found in {filename}")
                source = source.replace(fault["old"], fault["new"], 1)
            (rtl_dir / filename).write_text(source)

        compile_command = ["iverilog", "-g2012", "-s", "phase2_tb", "-o", str(temp / "fault.sim")]
        compile_command += [str(rtl_dir / filename) for filename in RTL_FILES]
        compile_command += [str(ROOT / "tb" / filename) for filename in TB_FILES]
        compile_result = subprocess.run(compile_command, cwd=ROOT, capture_output=True, text=True)
        output = compile_result.stdout + compile_result.stderr
        return_code = compile_result.returncode
        detection_source = "compile failure" if return_code else ""
        if return_code == 0:
            run_result = subprocess.run(["vvp", str(temp / "fault.sim")], cwd=ROOT,
                                        capture_output=True, text=True)
            output += run_result.stdout + run_result.stderr
            return_code = run_result.returncode
            if "ASSERTION FAILED" in output:
                detection_source = "SystemVerilog assertion"
            elif "SCOREBOARD ERROR" in output:
                detection_source = "scoreboard"
            elif "PHASE 2 TEST COMPLETE: FAIL" in output:
                detection_source = "testbench result"

    return FaultResult(fault["name"], fault["description"], return_code != 0,
                       time.perf_counter() - start, detection_source or "no failure detected", output)


def main() -> int:
    results_dir = ROOT / "results" / "fault_injection"
    results_dir.mkdir(parents=True, exist_ok=True)
    results = [run_fault(fault) for fault in FAULTS]
    for result in results:
        (results_dir / f"{result.name}.log").write_text(result.output)

    summary = {"total_faults": len(results),
               "detected_faults": sum(result.detected for result in results),
               "results": [asdict(result) for result in results]}
    (results_dir / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    markdown = ["# Fault Injection Summary", "",
                f"Detected {summary['detected_faults']}/{summary['total_faults']} injected faults.", "",
                "| Fault | Detected | Detection source | Runtime (s) |",
                "|---|---:|---|---:|"]
    for result in results:
        markdown.append(f"| {result.name} | {'PASS' if result.detected else 'FAIL'} | "
                        f"{result.detection_source} | {result.runtime_seconds:.3f} |")
    (results_dir / "summary.md").write_text("\n".join(markdown) + "\n")
    print(f"FAULT INJECTION: {summary['detected_faults']}/{summary['total_faults']} detected")
    for result in results:
        print(f"  {result.name}: {'DETECTED' if result.detected else 'MISSED'} ({result.detection_source})")
    return 0 if summary["detected_faults"] == summary["total_faults"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
