#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Network Boost Kit权限配置检查脚本
用于检查module.json5中是否正确配置了Network Boost Kit所需的权限
"""

import json
import os
import sys
from typing import List, Dict, Set

class PermissionChecker:
    """权限检查器"""
    
    REQUIRED_PERMISSIONS = {
        'ohos.permission.GET_NETWORK_INFO',
        'ohos.permission.INTERNET'
    }
    
    OPTIONAL_PERMISSIONS = {
        'ohos.permission.LINKTURBO'
    }
    
    ALL_PERMISSIONS = REQUIRED_PERMISSIONS | OPTIONAL_PERMISSIONS
    
    def __init__(self, module_json5_path: str):
        """初始化检查器
        
        Args:
            module_json5_path: module.json5文件路径
        """
        self.module_json5_path = module_json5_path
        self.module_data = None
        self.configured_permissions = set()
        
    def load_module_json5(self) -> bool:
        """加载module.json5文件
        
        Returns:
            是否加载成功
        """
        try:
            if not os.path.exists(self.module_json5_path):
                print(f"错误: 文件不存在 - {self.module_json5_path}")
                return False
                
            with open(self.module_json5_path, 'r', encoding='utf-8') as f:
                content = f.read()
                # 移除注释（JSON5支持注释）
                lines = []
                for line in content.split('\n'):
                    # 移除单行注释
                    if '//' in line:
                        line = line[:line.index('//')]
                    lines.append(line)
                clean_content = '\n'.join(lines)
                
                # 解析JSON
                self.module_data = json.loads(clean_content)
                return True
                
        except json.JSONDecodeError as e:
            print(f"错误: JSON解析失败 - {e}")
            return False
        except Exception as e:
            print(f"错误: 读取文件失败 - {e}")
            return False
            
    def extract_permissions(self) -> Set[str]:
        """提取已配置的权限
        
        Returns:
            已配置的权限集合
        """
        if not self.module_data:
            return set()
            
        self.configured_permissions = set()
        
        module = self.module_data.get('module', {})
        request_permissions = module.get('requestPermissions', [])
        
        for permission_item in request_permissions:
            if isinstance(permission_item, dict):
                permission_name = permission_item.get('name', '')
                if permission_name:
                    self.configured_permissions.add(permission_name)
            elif isinstance(permission_item, str):
                self.configured_permissions.add(permission_item)
                
        return self.configured_permissions
        
    def check_required_permissions(self) -> Dict[str, bool]:
        """检查必需权限
        
        Returns:
            权限检查结果字典
        """
        results = {}
        for permission in self.REQUIRED_PERMISSIONS:
            results[permission] = permission in self.configured_permissions
        return results
        
    def check_optional_permissions(self) -> Dict[str, bool]:
        """检查可选权限
        
        Returns:
            权限检查结果字典
        """
        results = {}
        for permission in self.OPTIONAL_PERMISSIONS:
            results[permission] = permission in self.configured_permissions
        return results
        
    def check_extra_permissions(self) -> Set[str]:
        """检查额外权限（不在Network Boost Kit权限列表中的权限）
        
        Returns:
            额外权限集合
        """
        return self.configured_permissions - self.ALL_PERMISSIONS
        
    def generate_report(self) -> Dict:
        """生成检查报告
        
        Returns:
            检查报告字典
        """
        required_results = self.check_required_permissions()
        optional_results = self.check_optional_permissions()
        extra_permissions = self.check_extra_permissions()
        
        all_required_passed = all(required_results.values())
        
        report = {
            'status': 'success' if all_required_passed else 'failed',
            'module_path': self.module_json5_path,
            'required_permissions': required_results,
            'optional_permissions': optional_results,
            'extra_permissions': list(extra_permissions),
            'summary': {
                'total_configured': len(self.configured_permissions),
                'required_passed': sum(required_results.values()),
                'required_total': len(required_results),
                'optional_passed': sum(optional_results.values()),
                'optional_total': len(optional_results),
                'all_required_passed': all_required_passed
            }
        }
        
        return report
        
    def print_report(self, report: Dict):
        """打印检查报告
        
        Args:
            report: 检查报告字典
        """
        print("\n" + "="*60)
        print("Network Boost Kit 权限配置检查报告")
        print("="*60)
        print(f"\n文件路径: {report['module_path']}")
        print(f"\n状态: {'✓ 通过' if report['summary']['all_required_passed'] else '✗ 失败'}")
        
        print("\n必需权限:")
        for permission, configured in report['required_permissions'].items():
            status = "✓ 已配置" if configured else "✗ 未配置"
            print(f"  {permission}: {status}")
            
        print("\n可选权限:")
        for permission, configured in report['optional_permissions'].items():
            status = "✓ 已配置" if configured else "○ 未配置"
            print(f"  {permission}: {status}")
            
        if report['extra_permissions']:
            print("\n额外权限:")
            for permission in report['extra_permissions']:
                print(f"  {permission}")
                
        print("\n统计:")
        summary = report['summary']
        print(f"  总配置权限数: {summary['total_configured']}")
        print(f"  必需权限: {summary['required_passed']}/{summary['required_total']}")
        print(f"  可选权限: {summary['optional_passed']}/{summary['optional_total']}")
        
        print("\n" + "="*60)
        
        if not summary['all_required_passed']:
            print("\n建议:")
            print("  请在module.json5的requestPermissions中添加缺失的必需权限:")
            for permission, configured in report['required_permissions'].items():
                if not configured:
                    print(f"    - {permission}")
            print("\n示例配置:")
            print('  {')
            print('    "module": {')
            print('      "requestPermissions": [')
            print('        {"name": "ohos.permission.GET_NETWORK_INFO"},')
            print('        {"name": "ohos.permission.INTERNET"}')
            print('      ]')
            print('    }')
            print('  }')


def main():
    """主函数"""
    if len(sys.argv) < 2:
        print("用法: python check_permissions.py <module.json5路径>")
        print("示例: python check_permissions.py entry/src/main/module.json5")
        sys.exit(1)
        
    module_json5_path = sys.argv[1]
    
    checker = PermissionChecker(module_json5_path)
    
    if not checker.load_module_json5():
        sys.exit(1)
        
    checker.extract_permissions()
    report = checker.generate_report()
    checker.print_report(report)
    
    if report['status'] == 'failed':
        sys.exit(1)


if __name__ == '__main__':
    main()