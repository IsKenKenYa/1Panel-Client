#!/usr/bin/env python3
# scripts/verify_skill_structure.py
# 技能目录结构验证脚本

import os
import json
from pathlib import Path

def verify_skill_structure(skill_path):
    """
    验证技能目录结构是否完整
    
    Args:
        skill_path: 技能目录路径
    
    Returns:
        验证结果字典
    """
    result = {
        'valid': True,
        'errors': [],
        'warnings': [],
        'files': {}
    }
    
    # 必需文件列表
    required_files = {
        'SKILL.md': '主技能定义文件',
        'references/api_reference_links.md': 'API参考链接汇总',
        'references/api_guide_summary.md': 'API指南摘要',
        'assets/WgtImgUpdateEntryFormAbility.ets': 'FormExtensionAbility示例代码',
        'assets/WidgetImageUpdateCard.ets': '卡片页面示例代码',
        'assets/module.json5': '模块配置示例',
        'assets/form_config.json': '卡片配置示例'
    }
    
    # 测试文件列表
    test_files = {
        'tests/test_local_image_refresh.ts': '本地图片刷新测试',
        'tests/test_network_image_refresh.ts': '网络图片刷新测试',
        'tests/test_multiple_images.ts': '多图片显示测试',
        'tests/test_image_size_limit.ts': '图片大小限制测试',
        'tests/test_image_count_limit.ts': '图片数量限制测试',
        'tests/test_download_time_limit.ts': '下载时间限制测试',
        'tests/test_permission_missing.ts': '权限未申请测试',
        'tests/test_invalid_url.ts': '网络链接无效测试',
        'tests/test_file_open_failed.ts': '文件打开失败测试',
        'tests/test_download_timeout.ts': '下载超时测试'
    }
    
    # 检查必需文件
    for file_path, description in required_files.items():
        full_path = os.path.join(skill_path, file_path)
        if os.path.exists(full_path):
            result['files'][file_path] = {
                'exists': True,
                'description': description,
                'size': os.path.getsize(full_path)
            }
            print(f"[OK] {file_path}: {description}")
        else:
            result['valid'] = False
            result['errors'].append(f"缺少必需文件：{file_path} ({description})")
            print(f"[ERROR] 缺少：{file_path} ({description})")
    
    # 检查测试文件
    for file_path, description in test_files.items():
        full_path = os.path.join(skill_path, file_path)
        if os.path.exists(full_path):
            result['files'][file_path] = {
                'exists': True,
                'description': description,
                'size': os.path.getsize(full_path)
            }
            print(f"[OK] {file_path}: {description}")
        else:
            result['warnings'].append(f"缺少测试文件：{file_path} ({description})")
            print(f"[WARN] 缺少：{file_path} ({description})")
    
    # 检查目录结构
    required_dirs = ['assets', 'references', 'tests', 'scripts']
    for dir_name in required_dirs:
        dir_path = os.path.join(skill_path, dir_name)
        if os.path.isdir(dir_path):
            print(f"[OK] 目录：{dir_name}/")
        else:
            result['valid'] = False
            result['errors'].append(f"缺少必需目录：{dir_name}/")
            print(f"[ERROR] 缺少目录：{dir_name}/")
    
    # 验证SKILL.md格式
    skill_md_path = os.path.join(skill_path, 'SKILL.md')
    if os.path.exists(skill_md_path):
        try:
            with open(skill_md_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
                # 检查必需章节
                required_sections = [
                    'name:',
                    'description:',
                    '## 功能描述',
                    '## 使用场景',
                    '## 调用规范和规则',
                    '## 调用流程和步骤',
                    '## 错误码说明',
                    '## 编译和修复问题',
                    '## 常见问题与解决方法',
                    '## 输出结果报告',
                    '## 参考文档',
                    '## 完整示例代码',
                    '## 测试用例'
                ]
                
                missing_sections = []
                for section in required_sections:
                    if section not in content:
                        missing_sections.append(section)
                
                if missing_sections:
                    result['warnings'].append(f"SKILL.md缺少章节：{', '.join(missing_sections)}")
                else:
                    print("[OK] SKILL.md包含所有必需章节")
                
        except Exception as e:
            result['errors'].append(f"读取SKILL.md失败：{str(e)}")
    
    return result

def print_summary(result):
    """
    打印验证结果摘要
    
    Args:
        result: 验证结果字典
    """
    print("\n" + "=" * 50)
    print("验证结果摘要")
    print("=" * 50)
    
    if result['valid']:
        print("状态: [PASS] 通过")
    else:
        print("状态: [FAIL] 失败")
    
    print(f"\n文件统计：{len(result['files'])} 个文件已检查")
    
    if result['errors']:
        print(f"\n错误数：{len(result['errors'])}")
        for error in result['errors']:
            print(f"  - {error}")
    
    if result['warnings']:
        print(f"\n警告数：{len(result['warnings'])}")
        for warning in result['warnings']:
            print(f"  - {warning}")
    
    print("\n" + "=" * 50)

def main():
    """
    主函数
    """
    skill_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    print(f"技能目录：{skill_path}")
    print("=" * 50)
    
    result = verify_skill_structure(skill_path)
    print_summary(result)
    
    # 保存验证结果
    result_path = os.path.join(skill_path, 'scripts', 'verification_result.json')
    with open(result_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    
    print(f"\n验证结果已保存至：{result_path}")
    
    return 0 if result['valid'] else 1

if __name__ == '__main__':
    import sys
    sys.exit(main())