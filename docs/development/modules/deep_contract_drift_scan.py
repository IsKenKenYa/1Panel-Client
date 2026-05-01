#!/usr/bin/env python3
"""
Deep contract drift scanner for Dart API clients.

Compares Swagger paths/methods/body requirements against calls found in
lib/api/v2/*_v2.dart and reports high-confidence drifts.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

ROOT = Path(__file__).resolve().parents[3]
SWAGGER_FILE = ROOT / "docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json"
API_DIR = ROOT / "lib/api/v2"

CALL_BLOCK_RE = re.compile(
    r"_client\.(get|post|put|delete|patch)(?:\s*<[^)]*>)?\s*\((.*?)\);",
    re.DOTALL,
)
PATH_RE = re.compile(r"ApiConstants\.buildApiPath\(\s*'([^']+)'\s*\)")

HTTP_METHODS = {"get", "post", "put", "delete", "patch"}


@dataclass
class LocalCall:
    file: str
    method: str
    path: str
    has_data: bool


@dataclass
class SwaggerOp:
    method: str
    body_required: bool


def normalize_path(path: str) -> str:
    parts = path.split("/")
    normalized: List[str] = []
    for part in parts:
        if not part:
            normalized.append(part)
            continue
        if part.startswith(":"):
            normalized.append("{}")
            continue
        if part.startswith("{") and part.endswith("}"):
            normalized.append("{}")
            continue
        if "$" in part:
            normalized.append("{}")
            continue
        normalized.append(part)
    return "/".join(normalized)


def load_swagger() -> Tuple[Dict[str, Dict[str, SwaggerOp]], Dict[str, List[str]]]:
    raw = json.loads(SWAGGER_FILE.read_text(encoding="utf-8"))
    paths = raw.get("paths", {})

    swagger: Dict[str, Dict[str, SwaggerOp]] = {}
    normalized_to_paths: Dict[str, List[str]] = {}

    for path, methods in paths.items():
        ops: Dict[str, SwaggerOp] = {}
        for method, op in methods.items():
            method_lower = method.lower()
            if method_lower not in HTTP_METHODS:
                continue
            body_required = False
            for param in op.get("parameters", []):
                if param.get("in") == "body" and bool(param.get("required")):
                    body_required = True
                    break
            ops[method_lower] = SwaggerOp(method=method_lower, body_required=body_required)
        if not ops:
            continue
        swagger[path] = ops
        normalized_to_paths.setdefault(normalize_path(path), []).append(path)

    return swagger, normalized_to_paths


def extract_local_calls() -> List[LocalCall]:
    calls: List[LocalCall] = []

    for file in sorted(API_DIR.glob("*_v2.dart")):
        text = file.read_text(encoding="utf-8")
        for match in CALL_BLOCK_RE.finditer(text):
            method = match.group(1).lower()
            block = match.group(2)
            path_match = PATH_RE.search(block)
            if not path_match:
                continue
            path = path_match.group(1)
            has_data = "data:" in block
            calls.append(
                LocalCall(
                    file=file.name,
                    method=method,
                    path=path,
                    has_data=has_data,
                )
            )

    return calls


def resolve_swagger_path(
    local_path: str,
    swagger_paths: Dict[str, Dict[str, SwaggerOp]],
    normalized_to_paths: Dict[str, List[str]],
) -> Optional[str]:
    if local_path in swagger_paths:
        return local_path

    normalized = normalize_path(local_path)
    candidates = normalized_to_paths.get(normalized, [])
    if not candidates:
        return None

    if len(candidates) == 1:
        return candidates[0]

    # Prefer candidates with same segment count.
    local_count = len([p for p in local_path.split("/") if p])
    same_count = [
        c for c in candidates if len([p for p in c.split("/") if p]) == local_count
    ]
    if len(same_count) == 1:
        return same_count[0]

    return candidates[0]


def build_findings() -> Dict[str, List[dict]]:
    swagger_paths, normalized_to_paths = load_swagger()
    local_calls = extract_local_calls()

    findings = {
        "path_missing": [],
        "method_mismatch": [],
        "body_missing": [],
    }

    for call in local_calls:
        resolved_path = resolve_swagger_path(call.path, swagger_paths, normalized_to_paths)
        if not resolved_path:
            findings["path_missing"].append(
                {
                    "file": call.file,
                    "method": call.method.upper(),
                    "path": call.path,
                }
            )
            continue

        swagger_ops = swagger_paths[resolved_path]
        if call.method not in swagger_ops:
            findings["method_mismatch"].append(
                {
                    "file": call.file,
                    "path": call.path,
                    "swaggerPath": resolved_path,
                    "clientMethod": call.method.upper(),
                    "swaggerMethods": sorted(m.upper() for m in swagger_ops),
                }
            )
            continue

        op = swagger_ops[call.method]
        if op.body_required and not call.has_data:
            findings["body_missing"].append(
                {
                    "file": call.file,
                    "method": call.method.upper(),
                    "path": call.path,
                    "swaggerPath": resolved_path,
                }
            )

    return findings


def summarize(findings: Dict[str, List[dict]]) -> Dict[str, int]:
    return {k: len(v) for k, v in findings.items()}


def write_output(output: Path, findings: Dict[str, List[dict]]) -> None:
    payload = {
        "generatedAt": datetime.now().isoformat(),
        "swaggerFile": str(SWAGGER_FILE),
        "apiDir": str(API_DIR),
        "summary": summarize(findings),
        "findings": findings,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Scan Dart API contract drifts")
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "docs/development/modules/audit/deep_contract_drift_scan_latest.json",
        help="Output json path",
    )
    args = parser.parse_args()

    findings = build_findings()
    write_output(args.output, findings)

    summary = summarize(findings)
    print("Deep contract drift summary:")
    for key, value in summary.items():
        print(f"- {key}: {value}")
    print(f"Report: {args.output}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
