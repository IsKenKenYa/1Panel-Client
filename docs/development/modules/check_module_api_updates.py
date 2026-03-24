#!/usr/bin/env python3
"""
模块 API 变更检查脚本

用途:
1. 对比当前 Swagger 与已生成的 `{模块}_api_analysis.json`
2. 检查每个模块是否出现新增/删除 API 端点
3. 输出增量报告，提示哪些模块需要重新运行 analyze_module_api.py

用法:
    python3 check_module_api_updates.py
    python3 check_module_api_updates.py website
    python3 check_module_api_updates.py --all
    python3 check_module_api_updates.py --json
"""

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

from analyze_module_api import (
    OPENAPI_FILE,
    collect_endpoint_signatures,
    extract_module_apis,
    get_all_supported_keywords,
    load_openapi,
    resolve_output_dir,
)


SCRIPT_DIR = Path(__file__).parent


def load_existing_analysis(keyword):
    output_dir = resolve_output_dir(keyword)
    json_file = output_dir / f"{keyword}_api_analysis.json"
    if not json_file.exists():
        return None, json_file

    with open(json_file, "r", encoding="utf-8") as f:
        return json.load(f), json_file


def build_delta(keyword, openapi_data):
    current_apis = extract_module_apis(openapi_data, keyword)
    current_signatures = collect_endpoint_signatures(current_apis)
    existing_report, existing_file = load_existing_analysis(keyword)

    existing_signatures = set()
    if existing_report:
        existing_signatures = collect_endpoint_signatures(existing_report.get("endpoints", []))

    added = sorted(current_signatures - existing_signatures)
    removed = sorted(existing_signatures - current_signatures)
    unchanged = sorted(current_signatures & existing_signatures)

    status = "unchanged"
    if existing_report is None:
        status = "missing_baseline"
    elif added or removed:
        status = "updated"

    return {
        "module": keyword,
        "status": status,
        "baselineFile": str(existing_file),
        "currentEndpointCount": len(current_signatures),
        "baselineEndpointCount": len(existing_signatures),
        "added": [{"method": method, "path": path} for method, path in added],
        "removed": [{"method": method, "path": path} for method, path in removed],
        "unchangedCount": len(unchanged),
    }


def render_markdown(results):
    lines = [
        "# 模块 API 变更检查报告",
        "",
        f"> 基于 `{OPENAPI_FILE}` 对比现有模块分析产物生成",
        f"> 生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "## 汇总",
        "",
        "| 模块 | 状态 | 当前端点数 | 基线端点数 | 新增 | 删除 |",
        "|------|------|------------|------------|------|------|",
    ]

    for result in results:
        lines.append(
            f"| {result['module']} | {result['status']} | "
            f"{result['currentEndpointCount']} | {result['baselineEndpointCount']} | "
            f"{len(result['added'])} | {len(result['removed'])} |"
        )

    lines.append("")
    lines.append("## 详情")
    lines.append("")

    for result in results:
        lines.append(f"### {result['module']}")
        lines.append("")
        lines.append(f"- 状态: `{result['status']}`")
        lines.append(f"- 基线文件: `{result['baselineFile']}`")
        lines.append(f"- 当前端点数: `{result['currentEndpointCount']}`")
        lines.append(f"- 基线端点数: `{result['baselineEndpointCount']}`")

        if result["status"] == "missing_baseline":
            lines.append("- 建议: 尚无基线分析文件，请先运行 `analyze_module_api.py`")

        if result["added"]:
            lines.append("")
            lines.append("**新增端点**:")
            lines.append("")
            for item in result["added"]:
                lines.append(f"- `{item['method']} {item['path']}`")

        if result["removed"]:
            lines.append("")
            lines.append("**已删除端点**:")
            lines.append("")
            for item in result["removed"]:
                lines.append(f"- `{item['method']} {item['path']}`")

        if not result["added"] and not result["removed"] and result["status"] == "unchanged":
            lines.append("- 无新增或删除端点")

        lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="检查模块 API 分析文件是否落后于当前 Swagger")
    parser.add_argument("keyword", nargs="?", help="模块关键词，可选")
    parser.add_argument("--all", action="store_true", help="检查所有支持的模块")
    parser.add_argument("--json", action="store_true", help="以 JSON 打印结果")
    args = parser.parse_args()

    try:
        openapi_data = load_openapi()
    except FileNotFoundError as exc:
        print(f"错误: {exc}", file=sys.stderr)
        sys.exit(1)

    if args.all or not args.keyword:
        keywords = get_all_supported_keywords()
    else:
        keywords = [args.keyword.lower()]

    results = [build_delta(keyword, openapi_data) for keyword in keywords]
    results.sort(key=lambda item: (item["status"], item["module"]))

    if args.json:
        print(json.dumps({
            "generatedAt": datetime.now().isoformat(),
            "swaggerFile": str(OPENAPI_FILE),
            "results": results,
        }, ensure_ascii=False, indent=2))
    else:
        print(render_markdown(results))

    updated_modules = [item["module"] for item in results if item["status"] == "updated"]
    missing_modules = [item["module"] for item in results if item["status"] == "missing_baseline"]

    if updated_modules:
        print("\n建议重新生成分析文件的模块:")
        for module in updated_modules:
            print(f"- {module}")

    if missing_modules:
        print("\n缺少基线分析文件的模块:")
        for module in missing_modules:
            print(f"- {module}")


if __name__ == "__main__":
    main()
