#!/usr/bin/env python3
"""Run the processor verification suite and generate regression reports."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RTL = [
    ROOT / "rtl/alu.sv",
    ROOT / "rtl/register_file.sv",
    ROOT / "rtl/decoder.sv",
    ROOT / "rtl/cpu.sv",
]


@dataclass
class TestResult:
    name: str
    category: str
    passed: bool
    runtime_seconds: float
    seed: int | None = None
    log_file: str = ""
    error: str = ""


def run_process(command: list[str], cwd: Path) -> tuple[int, str, float]:
    start = time.perf_counter()
    process = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
    runtime = time.perf_counter() - start
    output = process.stdout
    if process.stderr:
        output += "\n[stderr]\n" + process.stderr
    return process.returncode, output, runtime


def run_iverilog_test(name: str, sources: list[Path], top: str | None,
                      log_dir: Path) -> TestResult:
    start = time.perf_counter()
    log_path = log_dir / f"{name}.log"
    with tempfile.TemporaryDirectory(prefix=f"riscv-{name}-") as temp_dir:
        sim_path = Path(temp_dir) / f"{name}.sim"
        compile_command = ["iverilog", "-g2012"]
        if top:
            compile_command += ["-s", top]
        compile_command += ["-o", str(sim_path), *map(str, sources)]
        compile_code, compile_output, _ = run_process(compile_command, ROOT)

        output = f"$ {' '.join(compile_command)}\n{compile_output}"
        return_code = compile_code
        if compile_code == 0:
            run_code, run_output, _ = run_process(["vvp", str(sim_path)], ROOT)
            output += f"\n$ vvp {sim_path}\n{run_output}"
            return_code = run_code

    log_path.write_text(output)
    return TestResult(
        name=name,
        category="directed",
        passed=return_code == 0,
        runtime_seconds=time.perf_counter() - start,
        log_file=str(log_path.relative_to(ROOT)),
        error="simulation failed; see log" if return_code else "",
    )


def run_script_test(name: str, command: list[str], category: str,
                    log_dir: Path, seed: int | None = None) -> TestResult:
    return_code, output, runtime = run_process(command, ROOT)
    log_path = log_dir / f"{name}.log"
    log_path.write_text(f"$ {' '.join(command)}\n{output}")
    return TestResult(
        name=name,
        category=category,
        passed=return_code == 0,
        runtime_seconds=runtime,
        seed=seed,
        log_file=str(log_path.relative_to(ROOT)),
        error="simulation or model comparison failed; see log" if return_code else "",
    )


def write_reports(results: list[TestResult], report_dir: Path, started_at: str,
                  total_runtime: float, args: argparse.Namespace) -> tuple[Path, Path]:
    report_dir.mkdir(parents=True, exist_ok=True)
    passed = sum(result.passed for result in results)
    failed = len(results) - passed
    report = {
        "started_at": started_at,
        "finished_at": datetime.now(timezone.utc).isoformat(),
        "configuration": {
            "random_tests": args.tests,
            "base_seed": args.seed,
            "instructions_per_random_test": args.instructions,
        },
        "total_tests": len(results),
        "passed": passed,
        "failed": failed,
        "pass_rate": (passed / len(results) * 100.0) if results else 0.0,
        "runtime_seconds": total_runtime,
        "results": [asdict(result) for result in results],
    }
    json_path = report_dir / "regression_latest.json"
    json_path.write_text(json.dumps(report, indent=2) + "\n")

    markdown = [
        "# Regression Summary",
        "",
        f"- Total tests: {len(results)}",
        f"- Passed: {passed}",
        f"- Failed: {failed}",
        f"- Pass rate: {report['pass_rate']:.2f}%",
        f"- Runtime: {total_runtime:.3f} seconds",
        f"- Base seed: {args.seed}",
        f"- Instructions per randomized test: {args.instructions}",
        "",
        "| Test | Category | Result | Runtime (s) | Seed | Log |",
        "|---|---|---:|---:|---:|---|",
    ]
    for result in results:
        status = "PASS" if result.passed else "FAIL"
        seed = "" if result.seed is None else str(result.seed)
        markdown.append(
            f"| {result.name} | {result.category} | {status} | "
            f"{result.runtime_seconds:.3f} | {seed} | `{result.log_file}` |"
        )
    if failed:
        markdown += ["", "## Failures", ""]
        for result in results:
            if not result.passed:
                markdown.append(f"- `{result.name}`: {result.error}")

    markdown_path = report_dir / "regression_latest.md"
    markdown_path.write_text("\n".join(markdown) + "\n")
    return json_path, markdown_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tests", type=int, default=10,
                        help="number of randomized tests")
    parser.add_argument("--seed", type=int, default=42,
                        help="base seed; each test uses base seed plus its index")
    parser.add_argument("--instructions", type=int, default=100,
                        help="instructions in each randomized test")
    parser.add_argument("--results-dir", type=Path, default=ROOT / "results")
    args = parser.parse_args()

    if args.tests < 0:
        parser.error("--tests cannot be negative")
    if args.instructions <= 0:
        parser.error("--instructions must be positive")
    if shutil.which("iverilog") is None or shutil.which("vvp") is None:
        print("ERROR: Icarus Verilog (iverilog and vvp) is required", file=sys.stderr)
        return 2

    started_at = datetime.now(timezone.utc).isoformat()
    start = time.perf_counter()
    log_dir = args.results_dir / "logs"
    report_dir = args.results_dir / "reports"
    log_dir.mkdir(parents=True, exist_ok=True)
    results: list[TestResult] = []

    results.append(run_iverilog_test(
        "alu_directed",
        [ROOT / "rtl/alu.sv", ROOT / "tb/alu_tb.sv"],
        None,
        log_dir,
    ))
    results.append(run_iverilog_test(
        "cpu_directed",
        [*RTL, ROOT / "tb/cpu_tb.sv"],
        None,
        log_dir,
    ))
    results.append(run_iverilog_test(
        "phase2_structured",
        [*RTL, ROOT / "tb/generator.sv", ROOT / "tb/driver.sv",
         ROOT / "tb/monitor.sv", ROOT / "tb/scoreboard.sv",
         ROOT / "tb/assertions.sv", ROOT / "tb/coverage.sv",
         ROOT / "tb/phase2_tb.sv"],
        "phase2_tb",
        log_dir,
    ))
    results.append(run_script_test(
        "reference_model",
        [sys.executable, str(ROOT / "scripts/validate_reference_model.py")],
        "reference-model",
        log_dir,
    ))

    for index in range(args.tests):
        seed = args.seed + index
        results.append(run_script_test(
            f"random_seed_{seed}",
            [sys.executable, str(ROOT / "scripts/randomized_test.py"),
             "--count", str(args.instructions), "--seed", str(seed)],
            "randomized",
            log_dir,
            seed=seed,
        ))

    total_runtime = time.perf_counter() - start
    json_path, markdown_path = write_reports(
        results, report_dir, started_at, total_runtime, args
    )
    passed = sum(result.passed for result in results)
    failed = len(results) - passed
    print(f"REGRESSION: {passed}/{len(results)} passed ({failed} failed)")
    print(f"REGRESSION RUNTIME: {total_runtime:.3f}s")
    print(f"JSON REPORT: {json_path}")
    print(f"MARKDOWN REPORT: {markdown_path}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
