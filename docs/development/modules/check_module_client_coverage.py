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
CLIENT_ROUTE_PATTERNS = [
    # _client.post(... ApiConstants.buildApiPath('/path') ...)
    re.compile(
        r"_client\s*\.\s*(get|post|put|delete|patch)(?:<[^\(]*>)?\s*\(\s*ApiConstants\.buildApiPath\(\s*['\"]([^'\"]+)['\"]\s*\)",
        re.IGNORECASE | re.MULTILINE | re.DOTALL,
    ),
    # _client.post('${ApiConstants.buildApiPath('/base')}/$id/...')
    re.compile(
        r"_client\s*\.\s*(get|post|put|delete|patch)(?:<[^\(]*>)?\s*\(\s*['\"]\$\{ApiConstants\.buildApiPath\(\s*['\"]([^'\"]+)['\"]\s*\)\}([^'\"]*)['\"]",
        re.IGNORECASE | re.MULTILINE | re.DOTALL,
    ),
    # _client.post(ApiConstants.buildApiPath('/path/$var'))
    re.compile(
        r"_client\s*\.\s*(get|post|put|delete|patch)(?:<[^\(]*>)?\s*\(\s*ApiConstants\.buildApiPath\(\s*['\"]([^'\"]*\$[^'\"]*)['\"]\s*\)",
        re.IGNORECASE | re.MULTILINE | re.DOTALL,
    ),
    # _client.post(_withNode('/path', ...))
    re.compile(
        r"_client\s*\.\s*(get|post|put|delete|patch)(?:<[^\(]*>)?\s*\(\s*_withNode\(\s*['\"]([^'\"]+)['\"]",
        re.IGNORECASE | re.MULTILINE | re.DOTALL,
    ),
]

MODULE_CLIENT_FILES = {
    'dashboard': ['dashboard_v2.dart'],
    'container': ['container_v2.dart'],
    'website': ['website_v2.dart', 'ssl_v2.dart'],
    'openresty': ['openresty_v2.dart'],
    'domains': ['website_v2.dart'],
    'app': ['app_v2.dart', 'dashboard_v2.dart'],
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
    'website_ssl': ['ssl_v2.dart'],
    'log': ['logs_v2.dart', 'task_log_v2.dart'],
    'ai': ['ai_v2.dart'],
    'host': [
        'host_v2.dart',
        'monitor_v2.dart',
        'ssh_v2.dart',
        'firewall_v2.dart',
        'host_tool_v2.dart',
        'disk_management_v2.dart',
    ],
    'command': ['command_v2.dart'],
    'process': ['process_v2.dart'],
    'auth': ['auth_v2.dart', 'website_v2.dart'],
    'device': ['toolbox_v2.dart'],
    'toolbox': ['toolbox_v2.dart', 'host_tool_v2.dart', 'disk_management_v2.dart'],
    'group': ['system_group_v2.dart'],
}

MODULE_CLIENT_PATH_FILTERS = {
    'website': {
        'include': ['/websites'],
        'exclude': ['/websites/domains', '/websites/ssl', '/websites/auths'],
    },
    'domains': {
        'include': ['/websites/domains'],
    },
    'website_ssl': {
        'include': ['/websites/ssl'],
    },
    'system_ssl': {
        'include': ['/core/settings/ssl'],
    },
    'ssl': {
        'include': ['/websites/ssl', '/core/settings/ssl'],
    },
    'auth': {
        'include': ['/websites/auths', '/core/auth'],
    },
    'app': {
        'include': [
            '/apps',
            '/core/settings/apps',
            '/dashboard/app',
            '/ai/agents/channel/pairing/approve',
        ],
    },
    'device': {
        'include': ['/toolbox/device'],
    },
    'backup': {
        'include': ['/backups', '/core/backups'],
    },
}

EXTRA_ENDPOINT_CLASSIFICATIONS = {
    'ai': {
        ('POST', '/ai/agents/browser/get'): '保留：移动端浏览器托管配置读取，真实客户端能力；待上游 Swagger 模块补齐后移出白名单。',
        ('POST', '/ai/agents/browser/update'): '保留：移动端浏览器托管配置写入，真实客户端能力；待上游 Swagger 模块补齐后移出白名单。',
        ('POST', '/ai/agents/channel/feishu/approve'): '保留：移动端通道配对审批能力，属于客户端增强；待 AI 渠道契约稳定后迁移到正式模块端点。',
        ('POST', '/ai/agents/models/test'): '保留：模型连接测试用于移动端配置校验；待上游 OpenAPI 暴露后清理白名单。',
    },
    'auth': {
        ('GET', '/core/auth/demo'): '保留：登录前演示模式探测，启动链路需要；待 auth Swagger 补齐后移出白名单。',
        ('GET', '/core/auth/issafety'): '保留：登录前安全状态探测，移动端安全提示需要；待 auth Swagger 补齐后移出白名单。',
        ('GET', '/core/auth/language'): '保留：登录前语言探测，首屏本地化需要；待 auth Swagger 补齐后移出白名单。',
    },
    'command': {
        ('GET', '/cronjobs/script/options'): '保留：命令/脚本选择器兼容入口；迁移计划是收口到 cronjob/script 独立客户端。',
        ('POST', '/core/commands/command'): '保留：运行时真实路由为 POST，客户端严格 POST，不做 Swagger GET 回退。',
        ('POST', '/core/commands/list'): '保留：运行时真实列表接口，供 legacy getCommand/listCommands 使用。',
        ('POST', '/core/commands/tree'): '保留：运行时真实 tree 接口，客户端严格 POST，不做 Swagger GET 回退。',
        ('POST', '/core/script'): '保留：脚本库 legacy wrapper；迁移计划是完全由 script_library_v2.dart 承接。',
        ('POST', '/core/script/del'): '保留：脚本库 legacy wrapper；迁移计划是完全由 script_library_v2.dart 承接。',
        ('POST', '/core/script/search'): '保留：脚本库 legacy wrapper；迁移计划是完全由 script_library_v2.dart 承接。',
        ('POST', '/core/script/sync'): '保留：脚本库 legacy wrapper；迁移计划是完全由 script_library_v2.dart 承接。',
        ('POST', '/core/script/update'): '保留：脚本库 legacy wrapper；迁移计划是完全由 script_library_v2.dart 承接。',
    },
    'container': {
        ('POST', '/containers/command'): '保留：容器命令执行入口，客户端终端/命令能力使用；待容器 OpenAPI 补齐后移出白名单。',
    },
    'database': {
        ('GET', '/databases/redis/check'): '保留：Redis 可用性探测；待数据库模块契约补齐后移出白名单。',
        ('GET', '/databases/{var}/connection/test'): '保留：数据库连接测试；待数据库模块契约补齐后移出白名单。',
        ('GET', '/databases/{var}/privileges'): '保留：数据库权限读取；待权限管理契约补齐后移出白名单。',
        ('POST', '/databases/update'): '保留：数据库通用更新入口；迁移计划是按具体数据库类型拆分调用点。',
        ('POST', '/databases/{var}/backups'): '保留：数据库备份快捷入口；待 backup/database 归属收敛后移出白名单。',
        ('POST', '/databases/{var}/password/reset'): '保留：数据库密码重置能力；待数据库模块契约补齐后移出白名单。',
        ('POST', '/databases/{var}/privileges'): '保留：数据库权限写入；待权限管理契约补齐后移出白名单。',
    },
    'file': {
        ('POST', '/files/download'): '保留：客户端文件下载主链路；待下载契约补齐或统一下载服务落地后清理。',
    },
    'host': {
        ('GET', '/settings/ssh/conn'): '保留：SSH 连接配置读取，当前由主机/SSH 设置共用；归属后续收口到 ssh/setting。',
        ('POST', '/core/hosts/test/byid/{var}'): '保留：真实主机连接测试路由；当前 OpenAPI 归一化结果未命中，客户端以真实 API 为准。',
        ('POST', '/hosts/test/byid'): '保留：旧版主机连接测试兼容回退；真实 core 路径失败时才使用。',
        ('POST', '/settings/ssh'): '保留：SSH 设置写入，当前由主机/SSH 设置共用；归属后续收口到 ssh/setting。',
        ('POST', '/settings/ssh/check/info'): '保留：SSH 表单即时校验；归属后续收口到 ssh/setting。',
        ('POST', '/settings/ssh/conn/default'): '保留：SSH 默认连接配置写入；归属后续收口到 ssh/setting。',
        ('POST', '/toolbox/fail2ban/operate/sshd'): '保留：SSH 安全联动 fail2ban；归属后续收口到 toolbox/ssh 安全子模块。',
    },
    'log': {
        ('GET', '/logs/tasks/executing/count'): '保留：任务日志执行中数量徽标；待日志 Swagger 补齐后移出白名单。',
        ('POST', '/logs/tasks/search'): '保留：任务日志列表查询；待日志 Swagger 补齐后移出白名单。',
    },
    'setting': {
        ('GET', '/backups/options'): '保留：设置页备份账号选项依赖；归属后续收口到 backup 设置子模块。',
        ('GET', '/core/settings/mfa/status'): '保留：移动端 MFA 状态增强能力；待上游契约补齐后移出白名单。',
        ('GET', '/dashboard/base/os'): '保留：设置页系统基础信息展示复用 dashboard 端点；不在 setting Swagger 内重复建客户端。',
        ('POST', '/backups/del'): '保留：设置页备份账号删除入口；归属后续收口到 backup 设置子模块。',
        ('POST', '/core/settings/mfa/unbind'): '保留：移动端 MFA 解绑增强能力；待上游契约补齐后移出白名单。',
        ('POST', '/core/settings/reset'): '保留：设置重置入口；待 setting Swagger 补齐后移出白名单。',
    },
    'ssl': {
        ('GET', '/websites/ssl/application/{var}/status'): '保留：证书申请状态轮询；待网站证书契约补齐后移出白名单。',
        ('GET', '/websites/ssl/options'): '保留：证书选项读取；待网站证书契约补齐后移出白名单。',
        ('POST', '/websites/ssl/auto-renew'): '保留：移动端证书自动续签开关；待网站证书契约补齐后移出白名单。',
        ('POST', '/websites/ssl/validate'): '保留：证书表单校验；待网站证书契约补齐后移出白名单。',
    },
    'toolbox': {
        ('GET', '/hosts/disks'): '保留：磁盘管理当前由 toolbox 聚合；后续收口到独立 disk_management_v2 归属。',
        ('GET', '/hosts/tool/supervisor/process'): '保留：Supervisor 进程读取；后续收口到 process/toolbox 明确归属。',
        ('GET', '/toolbox/clean/data'): '保留：清理工具数据读取；待 toolbox Swagger 补齐后移出白名单。',
        ('GET', '/toolbox/clean/tree'): '保留：清理工具树读取；待 toolbox Swagger 补齐后移出白名单。',
        ('POST', '/hosts/disks/mount'): '保留：磁盘挂载操作；后续收口到独立 disk_management_v2 归属。',
        ('POST', '/hosts/disks/partition'): '保留：磁盘分区操作；后续收口到独立 disk_management_v2 归属。',
        ('POST', '/hosts/disks/unmount'): '保留：磁盘卸载操作；后续收口到独立 disk_management_v2 归属。',
        ('POST', '/hosts/tool'): '保留：主机工具聚合操作；待 toolbox 契约拆分后迁移。',
        ('POST', '/hosts/tool/config'): '保留：主机工具配置写入；待 toolbox 契约拆分后迁移。',
        ('POST', '/hosts/tool/init'): '保留：主机工具初始化；待 toolbox 契约拆分后迁移。',
        ('POST', '/hosts/tool/operate'): '保留：主机工具操作；待 toolbox 契约拆分后迁移。',
        ('POST', '/hosts/tool/supervisor/process'): '保留：Supervisor 进程操作；后续收口到 process/toolbox 明确归属。',
        ('POST', '/hosts/tool/supervisor/process/file'): '保留：Supervisor 进程配置文件操作；后续收口到 process/toolbox 明确归属。',
        ('POST', '/toolbox/clean/log'): '保留：清理工具日志读取；待 toolbox Swagger 补齐后移出白名单。',
    },
    'website_ssl': {
        ('GET', '/websites/ssl/application/{var}/status'): '保留：证书申请状态轮询；待网站证书契约补齐后移出白名单。',
        ('GET', '/websites/ssl/options'): '保留：证书选项读取；待网站证书契约补齐后移出白名单。',
        ('POST', '/websites/ssl/auto-renew'): '保留：移动端证书自动续签开关；待网站证书契约补齐后移出白名单。',
        ('POST', '/websites/ssl/validate'): '保留：证书表单校验；待网站证书契约补齐后移出白名单。',
    },
}

MISSING_ENDPOINT_CLASSIFICATIONS = {
    'command': {
        ('GET', '/core/commands/command'): '有意缺失：运行时真实接口为 POST /core/commands/command，客户端严格 POST，不做 GET 回退。',
        ('GET', '/core/commands/tree'): '有意缺失：运行时真实接口为 POST /core/commands/tree，客户端严格 POST，不做 GET 回退。',
    },
}

LEGACY_EXTRA_ALLOWLIST = {
    module: set(entries.keys())
    for module, entries in EXTRA_ENDPOINT_CLASSIFICATIONS.items()
}

KNOWN_MISSING_ALLOWLIST = {
    module: set(entries.keys())
    for module, entries in MISSING_ENDPOINT_CLASSIFICATIONS.items()
}

PATH_PARAM_BRACE_PATTERN = re.compile(r'\{[^/{}]+\}')
PATH_PARAM_COLON_PATTERN = re.compile(r'/:([A-Za-z_][A-Za-z0-9_]*)')
PATH_PARAM_DOLLAR_PATTERN = re.compile(r'/\$\{[^/]+\}|/\$[A-Za-z_][A-Za-z0-9_]*')


def _normalize_path(path):
    normalized = path.split('?', 1)[0]
    normalized = PATH_PARAM_DOLLAR_PATTERN.sub('/{var}', normalized)
    normalized = PATH_PARAM_COLON_PATTERN.sub('/{var}', normalized)
    normalized = PATH_PARAM_BRACE_PATTERN.sub('{var}', normalized)
    return normalized


def _classification_reason(bucket, keyword, method, path):
    if bucket == 'extra':
        return EXTRA_ENDPOINT_CLASSIFICATIONS.get(keyword, {}).get((method, path))
    if bucket == 'missing':
        return MISSING_ENDPOINT_CLASSIFICATIONS.get(keyword, {}).get((method, path))
    return None


def _to_json_rows(signatures, keyword=None, bucket=None):
    rows = []
    for method, path in sorted(signatures):
        row = {'method': method, 'path': path}
        if keyword is not None and bucket is not None:
            reason = _classification_reason(bucket, keyword, method, path)
            if reason:
                row['reason'] = reason
        rows.append(row)
    return rows


def _normalize_signatures(signatures):
    return {(method.upper(), _normalize_path(path)) for method, path in signatures}


def _apply_module_path_filters(keyword, signatures):
    filters = MODULE_CLIENT_PATH_FILTERS.get(keyword)
    if not filters:
        return signatures

    include_prefixes = tuple(filters.get('include', []))
    exclude_prefixes = tuple(filters.get('exclude', []))

    filtered = set()
    for method, path in signatures:
        if include_prefixes and not path.startswith(include_prefixes):
            continue
        if exclude_prefixes and path.startswith(exclude_prefixes):
            continue
        filtered.add((method, path))
    return filtered


def _load_client_signatures(file_paths):
    signatures = set()
    missing_files = []

    for file_name in file_paths:
        file_path = API_V2_DIR / file_name
        if not file_path.exists():
            missing_files.append(str(file_path))
            continue

        content = file_path.read_text(encoding='utf-8')
        for pattern in CLIENT_ROUTE_PATTERNS:
            for groups in pattern.findall(content):
                if len(groups) == 2:
                    method, path = groups
                else:
                    method, base, suffix = groups
                    path = f'{base}{suffix}'

                method_upper = method.upper()
                if method_upper in METHOD_SET:
                    signatures.add((method_upper, _normalize_path(path)))

    return signatures, missing_files


def _build_result(keyword, openapi_data):
    module_apis = extract_module_apis(openapi_data, keyword)
    swagger_signatures = _normalize_signatures(collect_endpoint_signatures(module_apis))

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
            'allowedMissingInClient': [],
            'extraInClient': [],
            'allowedExtraInClient': [],
        }

    client_signatures, missing_files = _load_client_signatures(client_files)
    client_signatures = _apply_module_path_filters(keyword, client_signatures)
    allowlist = _normalize_signatures(LEGACY_EXTRA_ALLOWLIST.get(keyword, set()))
    missing_allowlist = _normalize_signatures(
        KNOWN_MISSING_ALLOWLIST.get(keyword, set())
    )

    missing = swagger_signatures - client_signatures
    allowed_missing = missing & missing_allowlist
    unexpected_missing = missing - missing_allowlist
    extra = client_signatures - swagger_signatures
    allowed_extra = extra & allowlist
    unexpected_extra = extra - allowlist

    if missing_files:
        status = 'missing_client_file'
    elif unexpected_missing:
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
        'missingInClient': _to_json_rows(unexpected_missing),
        'allowedMissingInClient': _to_json_rows(
            allowed_missing,
            keyword=keyword,
            bucket='missing',
        ),
        'extraInClient': _to_json_rows(unexpected_extra),
        'allowedExtraInClient': _to_json_rows(
            allowed_extra,
            keyword=keyword,
            bucket='extra',
        ),
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

        if item.get('allowedMissingInClient'):
            lines.append('')
            lines.append('**已确认不实现的 Swagger 端点**:')
            for endpoint in item['allowedMissingInClient']:
                reason = endpoint.get('reason')
                suffix = f"：{reason}" if reason else ''
                lines.append(
                    f"- `{endpoint['method']} {endpoint['path']}`{suffix}"
                )

        if item['extraInClient']:
            lines.append('')
            lines.append('**客户端额外端点（未在 Swagger 中）**:')
            for endpoint in item['extraInClient']:
                lines.append(f"- `{endpoint['method']} {endpoint['path']}`")

        if item['allowedExtraInClient']:
            lines.append('')
            lines.append('**客户端兼容白名单端点**:')
            for endpoint in item['allowedExtraInClient']:
                reason = endpoint.get('reason')
                suffix = f"：{reason}" if reason else ''
                lines.append(
                    f"- `{endpoint['method']} {endpoint['path']}`{suffix}"
                )

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
