#!/usr/bin/env python3
"""
OpenAPI V2 分析脚本
用于提取和分析 1Panel 子模块 Swagger 规范中的所有API端点
"""

import json
import sys
from collections import defaultdict
from pathlib import Path

DEFAULT_SWAGGER_PATH = (
    Path(__file__).resolve().parent.parent
    / 'docs'
    / 'OpenSource'
    / '1Panel'
    / 'core'
    / 'cmd'
    / 'server'
    / 'docs'
    / 'swagger.json'
)

def analyze_openapi(json_path: str):
    """分析OpenAPI JSON文件"""
    source_path = Path(json_path)
    if not source_path.exists():
        raise FileNotFoundError(
            f"未找到 Swagger 文档: {source_path}\n"
            "请先初始化子模块: git submodule update --init --recursive docs/OpenSource/1Panel"
        )
    with open(source_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    paths = data.get('paths', {})
    definitions = data.get('definitions', {})
    
    # 按标签分组统计
    tag_endpoints = defaultdict(list)
    tag_stats = defaultdict(lambda: {'endpoints': 0, 'methods': defaultdict(int)})
    
    # 提取所有端点
    all_endpoints = []
    
    for endpoint_path, methods in paths.items():
        for method, details in methods.items():
            if method in ['get', 'post', 'put', 'delete', 'patch']:
                tags = details.get('tags', ['untagged'])
                summary = details.get('summary', '')
                operation_id = details.get('operationId', '')
                
                endpoint_info = {
                    'path': endpoint_path,
                    'method': method.upper(),
                    'tags': tags,
                    'summary': summary,
                    'operation_id': operation_id,
                    'parameters': details.get('parameters', []),
                    'responses': details.get('responses', {})
                }
                
                all_endpoints.append(endpoint_info)
                
                for tag in tags:
                    tag_endpoints[tag].append(endpoint_info)
                    tag_stats[tag]['endpoints'] += 1
                    tag_stats[tag]['methods'][method.upper()] += 1
    
    # 计算优先级
    priority_map = {
        'P0': ['Auth', 'Dashboard', 'App', 'Container', 'Website', 'File', 
               'System Setting', 'Database', 'Database Mysql', 'Database PostgreSQL',
               'Database Redis', 'Database Common', 'Runtime', 'Monitor', 'Backup Account'],
        'P1': ['Cronjob', 'Firewall', 'SSH', 'Website SSL', 'AI', 'Container Image',
               'Host', 'OpenResty', 'Command', 'Container Docker', 'Container Compose',
               'Container Network', 'Container Volume', 'Logs', 'Process', 'TaskLog',
               'Website CA', 'Website Acme', 'Website DNS', 'Website Domain', 
               'Website Nginx', 'Website HTTPS', 'Website PHP', 'Container Compose-template',
               'Container Image-repo', 'ScriptLibrary'],
        'P2': ['Clam', 'Device', 'FTP', 'McpServer', 'System Group', 'Fail2ban',
               'Host tool', 'Disk Management', 'PHP Extensions', 'untagged', 'Menu Setting']
    }
    
    def get_priority(tag):
        for priority, tags in priority_map.items():
            if tag in tags:
                return priority
        return 'P2'
    
    # 输出统计结果
    print("=" * 80)
    print("1Panel V2 OpenAPI 分析报告")
    print("=" * 80)
    print(f"\n总端点数: {len(all_endpoints)}")
    print(f"标签数: {len(tag_stats)}")
    print(f"定义数: {len(definitions)}")
    
    print("\n" + "=" * 80)
    print("按标签统计 (按端点数排序)")
    print("=" * 80)
    
    sorted_tags = sorted(tag_stats.items(), key=lambda x: x[1]['endpoints'], reverse=True)
    
    for tag, stats in sorted_tags:
        priority = get_priority(tag)
        methods_str = ', '.join([f"{m}: {c}" for m, c in stats['methods'].items()])
        print(f"\n[{priority}] {tag}:")
        print(f"  端点数: {stats['endpoints']}")
        print(f"  方法: {methods_str}")
    
    # 输出JSON格式的详细数据
    output = {
        'summary': {
            'total_endpoints': len(all_endpoints),
            'total_tags': len(tag_stats),
            'total_definitions': len(definitions)
        },
        'tags': {},
        'endpoints_by_priority': {
            'P0': [],
            'P1': [],
            'P2': []
        }
    }
    
    for tag, stats in sorted_tags:
        priority = get_priority(tag)
        output['tags'][tag] = {
            'priority': priority,
            'endpoints': stats['endpoints'],
            'methods': dict(stats['methods'])
        }
        output['endpoints_by_priority'][priority].extend(tag_endpoints[tag])
    
    # 保存详细分析结果
    output_path = Path.cwd() / 'openapi_analysis.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    
    print(f"\n详细分析结果已保存到: {output_path}")
    
    return output

if __name__ == '__main__':
    json_path = sys.argv[1] if len(sys.argv) > 1 else str(DEFAULT_SWAGGER_PATH)
    try:
        analyze_openapi(json_path)
    except FileNotFoundError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
