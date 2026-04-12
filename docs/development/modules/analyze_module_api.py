#!/usr/bin/env python3
"""
模块API端点分析脚本
从 1Panel 子模块中的 swagger.json 提取指定模块的API端点详细信息

用法:
    python analyze_module_api.py <模块关键词> [输出目录]

示例:
    python analyze_module_api.py dashboard
    python analyze_module_api.py container 仪表盘
    python analyze_module_api.py website 网站管理-OpenResty
    python analyze_module_api.py domains 网站域名管理
    python analyze_module_api.py website_ssl 网站SSL证书
    python analyze_module_api.py system_ssl SSL证书管理
"""
import json
import sys
import argparse
from pathlib import Path
from datetime import datetime

SCRIPT_DIR = Path(__file__).parent
OPENAPI_FILE = SCRIPT_DIR.parent.parent / "OpenSource" / "1Panel" / "core" / "cmd" / "server" / "docs" / "swagger.json"

MODULE_PATH_MAPPING = {
    'dashboard': '仪表盘',
    'container': '容器管理',
    'website': '网站管理-OpenResty',
    'openresty': 'openresty',
    'domains': '网站域名管理',
    'app': '应用管理',
    'database': '数据库管理',
    'file': '文件管理',
    'setting': '系统设置',
    'monitor': '监控管理',
    'backup': '备份账户管理',
    'runtime': '运行时管理',
    'ssh': 'SSH管理',
    'firewall': '防火墙管理',
    'cronjob': '计划任务管理',
    'ssl': 'SSL证书管理',
    'system_ssl': 'SSL证书管理',
    'website_ssl': '网站SSL证书',
    'log': '日志管理',
    'ai': 'AI管理',
    'host': '主机管理',
    'command': '命令管理',
    'process': '进程管理',
    'auth': '认证管理',
    'device': '设备管理',
    'toolbox': '工具箱',
    'group': '系统分组',
}

KEYWORD_MATCHERS = {
    'openresty': ['^/openresty'],
    'website': ['^/websites'],
    'domains': ['^/websites/domains'],
    'website_ssl': ['^/websites/ssl'],
    'system_ssl': ['^/core/settings/ssl'],
    'ssl': ['^/core/settings/ssl', '^/websites/ssl'],
    'host': ['^/hosts'],
    'database': ['^/databases'],
}


def _path_matches(path_lower, matcher):
    if matcher.startswith('^'):
        return path_lower.startswith(matcher[1:])
    return matcher in path_lower

def load_openapi():
    if not OPENAPI_FILE.exists():
        raise FileNotFoundError(
            "未找到 1Panel Swagger 文档，请先初始化子模块: "
            "git submodule update --init --recursive docs/OpenSource/1Panel"
        )
    with open(OPENAPI_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def get_all_supported_keywords():
    keywords = set(MODULE_PATH_MAPPING.keys()) | set(KEYWORD_MATCHERS.keys())
    return sorted(keywords)


def resolve_output_dir(keyword, output_dir=None):
    keyword = keyword.lower()
    if output_dir:
        return SCRIPT_DIR / output_dir
    if keyword in MODULE_PATH_MAPPING:
        return SCRIPT_DIR / MODULE_PATH_MAPPING[keyword]
    return SCRIPT_DIR / keyword

def extract_module_apis(openapi_data, keyword):
    paths = openapi_data.get('paths', {})
    tags_info = openapi_data.get('tags', [])
    module_apis = []
    keyword_lower = keyword.lower()
    matchers = KEYWORD_MATCHERS.get(keyword_lower, [f'/{keyword_lower}'])
    
    for path, methods in paths.items():
        path_lower = path.lower()
        if not any(_path_matches(path_lower, m) for m in matchers):
            continue

        api_info = {
            'path': path,
            'methods': []
        }
        
        for method, details in methods.items():
            if method in ['get', 'post', 'put', 'delete', 'patch']:
                method_info = {
                    'method': method.upper(),
                    'summary': details.get('summary', ''),
                    'description': details.get('description', ''),
                    'tags': details.get('tags', []),
                    'parameters': [],
                    'requestBody': None,
                    'responses': {},
                    'deprecated': details.get('deprecated', False)
                }
                
                for param in details.get('parameters', []):
                    param_info = {
                        'name': param.get('name'),
                        'in': param.get('in'),
                        'required': param.get('required', False),
                        'type': param.get('schema', {}).get('type', 'unknown'),
                        'description': param.get('description', '')
                    }
                    method_info['parameters'].append(param_info)
                
                if 'requestBody' in details:
                    rb = details['requestBody']
                    content = rb.get('content', {})
                    schema_ref = None
                    if content:
                        for content_type, content_schema in content.items():
                            if 'schema' in content_schema:
                                schema_ref = content_schema['schema'].get('$ref', '')
                                break
                    method_info['requestBody'] = {
                        'required': rb.get('required', False),
                        'description': rb.get('description', ''),
                        'contentTypes': list(content.keys()),
                        'schemaRef': schema_ref
                    }
                
                for code, resp in details.get('responses', {}).items():
                    method_info['responses'][code] = {
                        'description': resp.get('description', '')
                    }
                
                api_info['methods'].append(method_info)
        
        if api_info['methods']:
            module_apis.append(api_info)
    
    return module_apis

def generate_markdown_report(keyword, apis):
    total_methods = sum(len(api['methods']) for api in apis)
    
    lines = [
        f"# {keyword.upper()} 模块API端点详细分析",
        "",
        f"> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成",
        f"> 生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "## API端点总览",
        "",
        f"- 端点数量: **{len(apis)}**",
        f"- 方法总数: **{total_methods}**",
        "",
    ]
    
    get_count = sum(1 for api in apis for m in api['methods'] if m['method'] == 'GET')
    post_count = sum(1 for api in apis for m in api['methods'] if m['method'] == 'POST')
    put_count = sum(1 for api in apis for m in api['methods'] if m['method'] == 'PUT')
    delete_count = sum(1 for api in apis for m in api['methods'] if m['method'] == 'DELETE')
    
    lines.append("| 方法 | 数量 |")
    lines.append("|------|------|")
    if get_count > 0:
        lines.append(f"| GET | {get_count} |")
    if post_count > 0:
        lines.append(f"| POST | {post_count} |")
    if put_count > 0:
        lines.append(f"| PUT | {put_count} |")
    if delete_count > 0:
        lines.append(f"| DELETE | {delete_count} |")
    lines.append("")
    
    lines.append("## API端点详情")
    lines.append("")
    
    for api in apis:
        lines.append(f"### `{api['path']}`")
        lines.append("")
        
        for method in api['methods']:
            deprecated_mark = " ⚠️ *已废弃*" if method['deprecated'] else ""
            lines.append(f"#### {method['method']}{deprecated_mark}")
            lines.append("")
            
            if method['summary']:
                lines.append(f"**摘要**: {method['summary']}")
                lines.append("")
            
            if method['description']:
                lines.append(f"**描述**: {method['description']}")
                lines.append("")
            
            if method['tags']:
                lines.append(f"**标签**: {', '.join(method['tags'])}")
                lines.append("")
            
            if method['parameters']:
                lines.append("**参数**:")
                lines.append("")
                lines.append("| 名称 | 位置 | 类型 | 必填 | 描述 |")
                lines.append("|------|------|------|------|------|")
                for p in method['parameters']:
                    lines.append(f"| {p['name']} | {p['in']} | {p['type']} | {'是' if p['required'] else '否'} | {p['description']} |")
                lines.append("")
            
            if method['requestBody']:
                rb = method['requestBody']
                lines.append("**请求体**:")
                lines.append("")
                lines.append(f"- 必填: {'是' if rb['required'] else '否'}")
                lines.append(f"- 内容类型: {', '.join(rb['contentTypes'])}")
                if rb['description']:
                    lines.append(f"- 描述: {rb['description']}")
                if rb['schemaRef']:
                    lines.append(f"- Schema: `{rb['schemaRef']}`")
                lines.append("")
            
            if method['responses']:
                lines.append("**响应**:")
                lines.append("")
                for code, resp in method['responses'].items():
                    lines.append(f"- `{code}`: {resp['description']}")
                lines.append("")
            
            lines.append("---")
            lines.append("")
    
    return '\n'.join(lines)

def generate_json_report(keyword, apis):
    return json.dumps({
        'module': keyword,
        'generatedAt': datetime.now().isoformat(),
        'summary': {
            'endpointCount': len(apis),
            'methodCount': sum(len(api['methods']) for api in apis)
        },
        'endpoints': apis
    }, ensure_ascii=False, indent=2)


def collect_endpoint_signatures(apis):
    signatures = set()
    for api in apis:
        path = api.get('path')
        for method in api.get('methods', []):
            signatures.add((method.get('method', '').upper(), path))
    return signatures

def main():
    parser = argparse.ArgumentParser(
        description='从 1Panel 子模块 swagger.json 提取指定模块的API端点信息',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
    python analyze_module_api.py dashboard
    python analyze_module_api.py container
    python analyze_module_api.py website 网站管理-OpenResty
    python analyze_module_api.py domains 网站域名管理
    python analyze_module_api.py website_ssl 网站SSL证书
    python analyze_module_api.py system_ssl SSL证书管理
        """
    )
    parser.add_argument('keyword', help='模块关键词 (如: dashboard, container, website, domains, website_ssl, system_ssl)')
    parser.add_argument('output_dir', nargs='?', help='输出目录名称 (可选，默认自动匹配)')
    parser.add_argument('--json-only', action='store_true', help='只生成JSON文件')
    
    args = parser.parse_args()
    
    keyword = args.keyword.lower()
    
    print(f"正在加载 OpenAPI 规范文件: {OPENAPI_FILE}")
    try:
        openapi_data = load_openapi()
    except FileNotFoundError as e:
        print(f"错误: {e}", file=sys.stderr)
        sys.exit(1)
    
    print(f"正在提取 '{keyword}' 相关API端点...")
    module_apis = extract_module_apis(openapi_data, keyword)
    
    if not module_apis:
        print(f"未找到与 '{keyword}' 相关的API端点")
        sys.exit(1)
    
    total_methods = sum(len(api['methods']) for api in module_apis)
    print(f"找到 {len(module_apis)} 个端点, {total_methods} 个方法")
    
    output_dir = resolve_output_dir(keyword, args.output_dir)
    
    output_dir.mkdir(parents=True, exist_ok=True)
    
    if not args.json_only:
        md_report = generate_markdown_report(keyword, module_apis)
        md_file = output_dir / f"{keyword}_api_analysis.md"
        with open(md_file, 'w', encoding='utf-8') as f:
            f.write(md_report)
        print(f"Markdown报告: {md_file}")
    
    json_report = generate_json_report(keyword, module_apis)
    json_file = output_dir / f"{keyword}_api_analysis.json"
    with open(json_file, 'w', encoding='utf-8') as f:
        f.write(json_report)
    print(f"JSON报告: {json_file}")
    
    print("\n=== API端点摘要 ===")
    for api in module_apis:
        for method in api['methods']:
            deprecated = " [已废弃]" if method['deprecated'] else ""
            print(f"  {method['method']:6} {api['path']}{deprecated}")
            if method['summary']:
                print(f"         -> {method['summary']}")

if __name__ == "__main__":
    main()
