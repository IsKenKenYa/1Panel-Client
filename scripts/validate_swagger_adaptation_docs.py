#!/usr/bin/env python3
"""Validate adaptation status consistency across development docs.

Checks:
1) Row-level status counts in checklist table match checklist summary table.
2) Checklist row count is exactly 52 (51 tags + 1 untagged).
3) Matrix and API coverage docs reference checklist as canonical source.
4) Matrix and API coverage summary counts match checklist counts.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

CHECKLIST_PATH = ROOT / "docs" / "development" / "swagger_adaptation_status_checklist.md"
MATRIX_PATH = ROOT / "docs" / "development" / "requirement_tracking_matrix.md"
COVERAGE_PATH = ROOT / "docs" / "development" / "api_coverage.md"

EXPECTED_TOTAL_ROWS = 52
STATUS_KEYS = ("已适配", "部分适配", "未适配")
SUMMARY_RE = re.compile(r"`(\d+)\s*已适配\s*/\s*(\d+)\s*部分适配\s*/\s*(\d+)\s*未适配`")


def _read_text(path: Path) -> str:
    if not path.exists():
        raise FileNotFoundError(f"Missing file: {path}")
    return path.read_text(encoding="utf-8")


def _section_lines(text: str, heading: str) -> list[str]:
    lines = text.splitlines()
    start = None
    for idx, line in enumerate(lines):
        if line.strip() == heading:
            start = idx + 1
            break
    if start is None:
        raise ValueError(f"Heading not found: {heading}")

    end = len(lines)
    for idx in range(start, len(lines)):
        if lines[idx].startswith("## "):
            end = idx
            break
    return lines[start:end]


def _split_markdown_row(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def _extract_checklist_row_counts(checklist_text: str) -> tuple[dict[str, int], int]:
    lines = _section_lines(checklist_text, "## 清单")
    counts = {key: 0 for key in STATUS_KEYS}
    row_total = 0

    for line in lines:
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue

        cells = _split_markdown_row(stripped)
        if len(cells) < 6:
            continue

        if cells[0] == "Tag":
            continue
        if set(cells[0]) == {"-"}:
            continue

        status = cells[3]
        if status not in counts:
            raise ValueError(f"Unknown status in checklist row: {status}")

        counts[status] += 1
        row_total += 1

    return counts, row_total


def _extract_checklist_summary_counts(checklist_text: str) -> dict[str, int]:
    lines = _section_lines(checklist_text, "## 汇总")
    counts = {key: 0 for key in STATUS_KEYS}

    for line in lines:
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue

        cells = _split_markdown_row(stripped)
        if len(cells) < 2:
            continue

        if cells[0] == "主状态":
            continue
        if set(cells[0]) == {"-"}:
            continue

        status = cells[0]
        if status not in counts:
            continue

        try:
            counts[status] = int(cells[1])
        except ValueError as exc:
            raise ValueError(f"Invalid summary count for {status}: {cells[1]}") from exc

    return counts


def _extract_inline_summary_counts(doc_text: str, doc_name: str) -> dict[str, int]:
    match = SUMMARY_RE.search(doc_text)
    if not match:
        raise ValueError(f"Summary line not found in {doc_name}")

    adapted, partial, unmapped = [int(value) for value in match.groups()]
    return {
        "已适配": adapted,
        "部分适配": partial,
        "未适配": unmapped,
    }


def _format_counts(counts: dict[str, int]) -> str:
    return f"{counts['已适配']} 已适配 / {counts['部分适配']} 部分适配 / {counts['未适配']} 未适配"


def main() -> int:
    errors: list[str] = []

    checklist_text = _read_text(CHECKLIST_PATH)
    matrix_text = _read_text(MATRIX_PATH)
    coverage_text = _read_text(COVERAGE_PATH)

    row_counts, row_total = _extract_checklist_row_counts(checklist_text)
    summary_counts = _extract_checklist_summary_counts(checklist_text)

    if row_total != EXPECTED_TOTAL_ROWS:
        errors.append(
            f"Checklist rows expected {EXPECTED_TOTAL_ROWS}, got {row_total}"
        )

    if row_counts != summary_counts:
        errors.append(
            "Checklist summary mismatch: "
            f"rows={_format_counts(row_counts)} vs summary={_format_counts(summary_counts)}"
        )

    canonical_path = "docs/development/swagger_adaptation_status_checklist.md"
    if canonical_path not in matrix_text:
        errors.append("Matrix doc missing canonical checklist path reference")
    if canonical_path not in coverage_text:
        errors.append("API coverage doc missing canonical checklist path reference")

    matrix_counts = _extract_inline_summary_counts(matrix_text, "requirement_tracking_matrix.md")
    coverage_counts = _extract_inline_summary_counts(coverage_text, "api_coverage.md")

    if matrix_counts != row_counts:
        errors.append(
            "Matrix summary mismatch: "
            f"matrix={_format_counts(matrix_counts)} vs checklist={_format_counts(row_counts)}"
        )

    if coverage_counts != row_counts:
        errors.append(
            "API coverage summary mismatch: "
            f"api_coverage={_format_counts(coverage_counts)} vs checklist={_format_counts(row_counts)}"
        )

    if errors:
        print("Swagger adaptation docs validation failed:")
        for item in errors:
            print(f"- {item}")
        return 1

    print("Swagger adaptation docs validation passed.")
    print(f"Frozen baseline: {_format_counts(row_counts)}")
    print(f"Checklist rows: {row_total}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # pragma: no cover
        print(f"Validation script error: {exc}", file=sys.stderr)
        raise SystemExit(1)
