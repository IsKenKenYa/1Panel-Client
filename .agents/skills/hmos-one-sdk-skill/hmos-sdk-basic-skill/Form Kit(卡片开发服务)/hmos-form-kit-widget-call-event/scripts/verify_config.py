# scripts/verify_config.py
# 验证卡片call事件配置脚本

import json
import sys
import os

def verify_module_json5(module_json5_path):
    """验证module.json5配置是否正确"""
    
    if not os.path.exists(module_json5_path):
        print(f"Error: module.json5 file not found at {module_json5_path}")
        return False
    
    try:
        with open(module_json5_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse module.json5: {e}")
        return False
    
    errors = []
    
    # 检查后台运行权限
    if 'module' not in config:
        errors.append("Missing 'module' section in module.json5")
    else:
        if 'requestPermissions' not in config['module']:
            errors.append("Missing 'requestPermissions' in module.json5")
        else:
            permissions = config['module']['requestPermissions']
            has_background_permission = False
            for perm in permissions:
                if perm.get('name') == 'ohos.permission.KEEP_BACKGROUND_RUNNING':
                    has_background_permission = True
                    break
            
            if not has_background_permission:
                errors.append("Missing 'ohos.permission.KEEP_BACKGROUND_RUNNING' permission")
        
        # 检查UIAbility配置
        if 'abilities' not in config['module']:
            errors.append("Missing 'abilities' section in module.json5")
        else:
            abilities = config['module']['abilities']
            has_singleton_ability = False
            
            for ability in abilities:
                if ability.get('name') == 'WidgetEventCallEntryAbility':
                    has_singleton_ability = True
                    
                    if ability.get('launchType') != 'singleton':
                        errors.append(f"UIAbility '{ability.get('name')}' must have launchType='singleton'")
                    
                    if 'srcEntry' not in ability:
                        errors.append(f"UIAbility '{ability.get('name')}' missing 'srcEntry' field")
                    
                    break
            
            if not has_singleton_ability:
                errors.append("Missing 'WidgetEventCallEntryAbility' in abilities configuration")
    
    if errors:
        print("Configuration verification failed:")
        for error in errors:
            print(f"  - {error}")
        return False
    
    print("Configuration verification passed!")
    print("  ✓ Background running permission configured")
    print("  ✓ UIAbility launchType is singleton")
    print("  ✓ UIAbility srcEntry configured")
    
    return True

def verify_widget_implementation(widget_ets_path):
    """验证卡片页面实现是否正确"""
    
    if not os.path.exists(widget_ets_path):
        print(f"Error: Widget page file not found at {widget_ets_path}")
        return False
    
    with open(widget_ets_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    errors = []
    
    # 检查是否使用了postCardAction
    if 'postCardAction' not in content:
        errors.append("Missing postCardAction call in widget page")
    
    # 检查是否有call事件
    if "action: 'call'" not in content:
        errors.append("Missing 'call' action in postCardAction")
    
    # 检查是否有method参数
    if 'method:' not in content:
        errors.append("Missing 'method' parameter in postCardAction params")
    
    # 检查是否有abilityName
    if 'abilityName:' not in content:
        errors.append("Missing 'abilityName' parameter in postCardAction")
    
    if errors:
        print("Widget implementation verification failed:")
        for error in errors:
            print(f"  - {error}")
        return False
    
    print("Widget implementation verification passed!")
    print("  ✓ postCardAction properly used")
    print("  ✓ Call action configured")
    print("  ✓ Method parameter defined")
    print("  ✓ AbilityName specified")
    
    return True

def verify_uiability_implementation(uiability_ets_path):
    """验证UIAbility实现是否正确"""
    
    if not os.path.exists(uiability_ets_path):
        print(f"Error: UIAbility file not found at {uiability_ets_path}")
        return False
    
    with open(uiability_ets_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    errors = []
    
    # 检查是否导入rpc模块
    if "import { rpc } from '@kit.IPCKit'" not in content:
        errors.append("Missing rpc module import")
    
    # 检查是否实现了Parcelable
    if 'implements rpc.Parcelable' not in content:
        errors.append("Missing Parcelable implementation")
    
    # 检查是否注册了callee监听
    if 'this.callee.on' not in content:
        errors.append("Missing callee.on registration in onCreate")
    
    # 检查是否在onDestroy中解除监听
    if 'this.callee.off' not in content:
        errors.append("Missing callee.off unregistration in onDestroy")
    
    # 检查marshalling和unmarshalling方法
    if 'marshalling' not in content:
        errors.append("Missing marshalling method in Parcelable implementation")
    
    if 'unmarshalling' not in content:
        errors.append("Missing unmarshalling method in Parcelable implementation")
    
    if errors:
        print("UIAbility implementation verification failed:")
        for error in errors:
            print(f"  - {error}")
        return False
    
    print("UIAbility implementation verification passed!")
    print("  ✓ Rpc module imported")
    print("  ✓ Parcelable implemented")
    print("  ✓ Callee methods registered")
    print("  ✓ Callee methods unregistered in onDestroy")
    print("  ✓ Marshalling/unmarshalling methods defined")
    
    return True

def main():
    """主验证流程"""
    
    print("=" * 60)
    print("卡片call事件配置验证工具")
    print("=" * 60)
    print()
    
    # 配置文件路径(示例)
    module_json5_path = "src/main/module.json5"
    widget_ets_path = "src/main/ets/widgeteventcall/pages/WidgetEventCallCard.ets"
    uiability_ets_path = "src/main/ets/widgeteventcallentryability/WidgetEventCallEntryAbility.ets"
    
    # 验证配置文件
    print("1. Verifying module.json5 configuration...")
    config_valid = verify_module_json5(module_json5_path)
    print()
    
    # 验证卡片页面实现
    print("2. Verifying widget page implementation...")
    widget_valid = verify_widget_implementation(widget_ets_path)
    print()
    
    # 验证UIAbility实现
    print("3. Verifying UIAbility implementation...")
    uiability_valid = verify_uiability_implementation(uiability_ets_path)
    print()
    
    # 输出总结
    print("=" * 60)
    if config_valid and widget_valid and uiability_valid:
        print("✓ All verifications passed!")
        print("  Configuration: PASS")
        print("  Widget Page: PASS")
        print("  UIAbility: PASS")
        print()
        print("The widget call event implementation is ready to use.")
        return 0
    else:
        print("✗ Verification failed!")
        print("  Configuration:", "PASS" if config_valid else "FAIL")
        print("  Widget Page:", "PASS" if widget_valid else "FAIL")
        print("  UIAbility:", "PASS" if uiability_valid else "FAIL")
        print()
        print("Please fix the errors before proceeding.")
        return 1

if __name__ == "__main__":
    sys.exit(main())