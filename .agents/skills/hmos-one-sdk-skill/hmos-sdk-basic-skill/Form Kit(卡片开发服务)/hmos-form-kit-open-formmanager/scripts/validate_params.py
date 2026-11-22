import argparse
import json
import os
from pathlib import Path

def validate_form_config(form_config_path: str) -> dict:
    """
    验证form_config.json配置文件
    
    Args:
        form_config_path: form_config.json文件路径
        
    Returns:
        验证结果字典，包含是否成功和错误信息
    """
    result = {
        'success': True,
        'errors': [],
        'warnings': []
    }
    
    try:
        with open(form_config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
    except FileNotFoundError:
        result['success'] = False
        result['errors'].append(f'配置文件不存在: {form_config_path}')
        return result
    except json.JSONDecodeError as e:
        result['success'] = False
        result['errors'].append(f'JSON格式错误: {str(e)}')
        return result
    
    if 'forms' not in config:
        result['success'] = False
        result['errors'].append('缺少forms字段')
        return result
    
    for form in config['forms']:
        if 'name' not in form:
            result['errors'].append(f'卡片缺少name字段')
            result['success'] = False
        
        if 'src' not in form:
            result['errors'].append(f'卡片{form.get("name", "unknown")}缺少src字段')
            result['success'] = False
        
        if 'defaultDimension' not in form:
            result['warnings'].append(f'卡片{form.get("name", "unknown")}缺少defaultDimension字段')
        
        if 'supportDimensions' not in form:
            result['warnings'].append(f'卡片{form.get("name", "unknown")}缺少supportDimensions字段')
    
    return result

def validate_want_params(bundle_name: str, ability_name: str, form_name: str = None, 
                         form_dimension: int = None, module_name: str = None) -> dict:
    """
    验证openFormManager的want参数
    
    Args:
        bundle_name: 应用包名
        ability_name: Ability名称
        form_name: 卡片名称(可选)
        form_dimension: 卡片尺寸(可选)
        module_name: 模块名称(可选)
        
    Returns:
        验证结果字典
    """
    result = {
        'success': True,
        'errors': [],
        'warnings': []
    }
    
    if not bundle_name:
        result['success'] = False
        result['errors'].append('bundleName不能为空')
    
    if not ability_name:
        result['success'] = False
        result['errors'].append('abilityName不能为空')
    
    if form_dimension is not None:
        if form_dimension not in [1, 2, 3, 4]:
            result['success'] = False
            result['errors'].append(f'form_dimension值{form_dimension}不在有效范围[1,2,3,4]内')
    
    if form_name and module_name:
        result['warnings'].append('完整参数已提供，将显示指定卡片')
    elif not form_name or not module_name:
        result['warnings'].append('参数不完整，将显示默认卡片')
    
    return result

def main():
    parser = argparse.ArgumentParser(description='openFormManager参数验证工具')
    parser.add_argument('--config', help='form_config.json文件路径')
    parser.add_argument('--bundle', help='bundleName')
    parser.add_argument('--ability', help='abilityName')
    parser.add_argument('--form-name', help='卡片名称')
    parser.add_argument('--dimension', type=int, help='卡片尺寸(1/2/3/4)')
    parser.add_argument('--module', help='模块名称')
    
    args = parser.parse_args()
    
    if args.config:
        print('验证form_config.json配置文件...')
        result = validate_form_config(args.config)
        print(json.dumps(result, indent=2, ensure_ascii=False))
    
    if args.bundle or args.ability:
        print('\n验证want参数...')
        result = validate_want_params(
            args.bundle, args.ability, args.form_name, 
            args.dimension, args.module
        )
        print(json.dumps(result, indent=2, ensure_ascii=False))

if __name__ == '__main__':
    main()