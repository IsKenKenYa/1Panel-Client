#!/usr/bin/env python3
"""
检查模块 Swagger 与 Dart API 客户端覆盖差异。

用途:
1. 对比 Swagger 模块端点与 lib/api/v2 客户端 method/path 覆盖
2. 输出缺失端点（Swagger 有但客户端无）
3. 输出额外端点（客户端有但 Swagger 无，可配置兼容白名单）

用法:
    python3 check_module_client_coverage.py
    python3 check_module_client_coverage.py ai
    python3 check_module_client_coverage.py --all
    python3 check_module_client_coverage.py --json
"""

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path

from analyze_module_api import (
    OPENAPI_FILE,
    collect_endpoint_signatures,
    extract_module_apis,
    get_all_supported_keywords,
    load_openapi,
)


SCRIPT_DIR = Path(__file__).parent
API_V2_DIR = SCRIPT_DIR.parent.parent.parent / 'lib' / 'api' / 'v2'

METHOD_SET = {'GET', 'POST', 'PUT', 'DELETE', 'PATCH'}
CLIENT_ROUTE_PATTERN = re.compile(
    r"_client\.(get|post|put|delete|patch)\s*\(\s*ApiConstants\.buildApiPath\(\s*['\"]([^'\"]+)['\"]\s*\)",
    re.IGNORECASE | re.MULTILINE,
)

MODULE_CLIENT_FILES = {
    'dashboard': ['dashboard_v2.dart'],
    'container': ['container_v2.dart'],
    'website': ['website_v2.dart'],
    'openresty': ['openresty_v2.dart'],
    'domains': ['website_v2.dart'],
    'app': ['app_v2.dart'],
    'database': ['database_v2.dart'],
    'file': ['file_v2.dart'],
    'setting': ['setting_v2.dart'],
    'monitor': ['monitor_v2.dart'],
    'backup': ['backup_account_v2.dart', 'snapshot_v2.dart'],
    'runtime': ['runtime_v2.dart'],
    'ssh': ['ssh_v2.dart'],
    'firewall': ['firewall_v2.dart'],
    'cronjob': ['cronjob_v2.dart'],
    'ssl': ['ssl_v2.dart'],
    'system_ssl': ['ssl_v2.dart'],
    'website_ssl': ['website_v2.dart'],
    'log': ['logs_v2.dart', 'task_log_v2.dart'],
    'ai': ['ai_v2.dart'],
    'host': ['host_v2.dart'],
    'command': ['command_v2.dart'],
    'process': ['process_v2.dart'],
    'auth': ['auth_v2.dart'],
    'device': ['toolbox_v2.dart'],
    'toolbox': ['toolbox_v2.dart', 'host_tool_v2.dart', 'disk_management_v2.dart'],
    'group': ['system_group_v2.dart'],
}

LEGACY_EXTRA_ALLOWLIST = {
    'ai': {
        ('POST', '/ai/agents/browser/get'),
        ('POST', '/ai/agents/browser/update'),
        ('POST', '/ai/agents/channel/feishu/approve'),
    },
}


def _to_json_rows(signatures):
    return [{'method': method, 'path': path} for method, path in sorted(signatures)]


def _load_client_signatures(file_paths):
    signatures = set()
    missing_files = []

    for file_name in file_paths:
        file_path = API_V2_DIR / file_name
        if not file_path.exists():
            missing_files.append(str(file_path))
            continue

        content = file_path.read_text(encoding='utf-8')
        for method, path in CLIENT_ROUTE_PATTERN.findall(content):
            method_upper = method.upper()
            if method_upper in METHOD_SET:
                signatures.add((method_upper, path))

    return signatures, missing_files


def _build_result(keyword, openapi_data):
    module_apis = extract_module_apis(openapi_data, keyword)
    swagger_signatures = collect_endpoint_signatures(module_apis)

    client_files = MODULE_CLIENT_FILES.get(keyword)
    if not client_files:
        return {
            'module': keyword,
            'status': 'no_client_mapping',
            'swaggerEndpointCount': len(swagger_signatures),
            'clientEndpointCount': 0,
            'clientFiles': [],
            'missingClientFiles': [],
            'missingInClient': _to_json_rows(swagger_signatures),
            'extraInClient': [],
            'allowedExtraInClient': [],
        }

    client_signatures, missing_files = _load_client_signatures(client_files)
    allowlist = LEGACY_EXTRA_ALLOWLIST.get(keyword, set())

    missing = swagger_signatures - client_signatures
    extra = client_signatures - swagger_signatures
    allowed_extra = extra & allowlist
    unexpected_extra = extra - allowlist

    if missing_files:
        status = 'missing_client_file'
    elif missing:
        status = 'missing_in_client'
    elif unexpected_extra:
        status = 'extra_in_client'
    else:
        status = 'aligned'

    return {
        'module': keyword,
        'status': status,
        'swaggerEndpointCount': len(swagger_signatures),
        'clientEndpointCount': len(client_signatures),
        'clientFiles': [str(API_V2_DIR / name) for name in client_files],
        'missingClientFiles': missing_files,
        'missingInClient': _to_json_rows(missing),
        'extraInClient': _to_json_rows(unexpected_extra),
        'allowedExtraInClient': _to_json_rows(allowed_extra),
    }


def _render_markdown(results):
    lines = [
        '# 模块 Swagger-客户端覆盖检查报告',
        '',
        f"> 基于 `{OPENAPI_FILE}` 与 `lib/api/v2/*.dart` 生成",
        f"> 生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        '',
        '## 汇总',
        '',
        '| 模块 | 状态 | Swagger端点 | 客户端端点 | 缺失 | 额外 |',
        '|------|------|-------------|------------|------|------|',
    ]

    for item in results:
        lines.append(
            f"| {item['module']} | {item['status']} | {item['swaggerEndpointCount']} | "
            f"{item['clientEndpointCount']} | {len(item['missingInClient'])} | {len(item['extraInClient'])} |"
        )

    lines.append('')
    lines.append('## 详情')
    lines.append('')

    for item in results:
        lines.append(f"### {item['module']}")
        lines.append('')
        lines.append(f"- 状态: `{item['status']}`")
        lines.append(f"- Swagger 端点数: `{item['swaggerEndpointCount']}`")
        lines.append(f"- 客户端端点数: `{item['clientEndpointCount']}`")

        if item['clientFiles']:
            lines.append('- 客户端文件:')
            for path in item['clientFiles']:
                lines.append(f"  - `{path}`")

        if item['missingClientFiles']:
            lines.append('- 缺失客户端文件:')
            for path in item['missingClientFiles']:
                lines.append(f"  - `{path}`")

        if item['missingInClient']:
            lines.append('')
            lines.append('**Swagger 有但客户端缺失**:')
            for endpoint in item['missingInClient']:
                lines.append(f"- `{endpoint['method']} {endpoint['path']}`")

        if item['extraInClient']:
            lines.append('')
            lines.append('**客户端额外端点（未在 Swagger 中）**:')
            for endpoint in item['extraInClient']:
                lines.append(f"- `{endpoint['method']} {endpoint['path']}`")

        if item['allowedExtraInClient']:
            lines.append('')
            lines.append('**客户端兼容白名单端点**:')
            for endpoint in item['allowedExtraInClient']:
                lines.append(f"- `{endpoint['method']} {endpoint['path']}`")

        if (
            not item['missingInClient']
            and not item['extraInClient']
            and not item['missingClientFiles']
        ):
            lines.append('- 无覆盖差异')

        lines.append('')

    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description='检查 Swagger 与 Dart 客户端覆盖差异')
    parser.add_argument('keyword', nargs='?', help='模块关键词，可选')
    parser.add_argument('--all', action='store_true', help='检查所有支持模块')
    parser.add_argument('--json', action='store_true', help='JSON 输出')
    args = parser.parse_args()

    try:
      openapi_data = load_openapi()
    except FileNotFoundError as exc:
      print(f'错误: {exc}', file=sys.stderr)
      sys.exit(1)

    if args.all or not args.keyword:
        keywords = get_all_supported_keywords()
    else:
        keywords = [args.keyword.lower()]

    results = [_build_result(keyword, openapi_data) for keyword in keywords]
    results.sort(key=lambda item: (item['status'], item['module']))

    if args.json:
        print(
            json.dumps(
                {
                    'generatedAt': datetime.now().isoformat(),
                    'swaggerFile': str(OPENAPI_FILE),
                    'results': results,
                },
                ensure_ascii=False,
                indent=2,
            )
        )
    else:
        print(_render_markdown(results))

    not_aligned = [
        item['module']
        for item in results
        if item['status'] != 'aligned'
    ]

    if not_aligned:
        print('\n需要处理的模块:')
        for module in not_aligned:
            print(f'- {module}')
        sys.exit(2)


if __name__ == '__main__':
    main()
