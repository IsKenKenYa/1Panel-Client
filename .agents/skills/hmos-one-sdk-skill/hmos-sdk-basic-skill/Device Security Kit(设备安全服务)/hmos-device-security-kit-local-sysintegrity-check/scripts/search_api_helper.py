#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Device Security Kit - 本地系统完整性检测 API搜索脚本
用于在HarmonyOS API参考文档中搜索checkSysIntegrityOnLocal相关API
"""

import sys
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SEARCH_API_SCRIPT = os.path.join(SCRIPT_DIR, '..', '..', '..', '..', '..', '..', '..', '..', '..', 'C', 'Users', 'z00810349', '.config', 'opencode', 'skills', 'api-coding-skill-creator', 'scripts', 'search_api.py')

def search_check_sysintegrity_onlocal():
    """搜索checkSysIntegrityOnLocal API"""
    
    api_name = 'checkSysIntegrityOnLocal'
    search_dir = 'D:\\z00810349\\APIDevice\\output\\md_output\\harmonyos-references'
    
    cmd = f'python "{SEARCH_API_SCRIPT}" {api_name} -d "{search_dir}" --verify -v'
    
    print(f"Executing: {cmd}")
    os.system(cmd)

def search_safety_detect():
    """搜索SafetyDetect模块"""
    
    api_name = 'safetyDetect'
    search_dir = 'D:\\z00810349\\APIDevice\\output\\md_output\\harmonyos-references'
    
    cmd = f'python "{SEARCH_API_SCRIPT}" {api_name} -d "{search_dir}" -m --verify -v'
    
    print(f"Executing: {cmd}")
    os.system(cmd)

def main():
    """主函数"""
    
    print("=" * 80)
    print("Device Security Kit - 本地系统完整性检测 API搜索工具")
    print("=" * 80)
    
    print("\n可用的搜索选项:")
    print("1. 搜索checkSysIntegrityOnLocal API")
    print("2. 搜索SafetyDetect模块")
    
    choice = input("\n请选择搜索类型 (1/2): ").strip()
    
    if choice == '1':
        search_check_sysintegrity_onlocal()
    elif choice == '2':
        search_safety_detect()
    else:
        print("无效的选择，执行默认搜索...")
        search_check_sysintegrity_onlocal()

if __name__ == '__main__':
    main()