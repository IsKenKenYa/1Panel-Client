import argparse
import sys
import os

def check_api_version(api_version):
    minimum_version = 20
    if api_version < minimum_version:
        print(f"API版本不兼容: 当前版本 {api_version}, 最低要求版本 {minimum_version}")
        return False
    print(f"API版本兼容: 当前版本 {api_version} >= {minimum_version}")
    return True

def check_permission(permission_name):
    required_permission = "ohos.permission.LINKTURBO"
    if permission_name != required_permission:
        print(f"权限不匹配: 当前权限 {permission_name}, 需要权限 {required_permission}")
        return False
    print(f"权限匹配: {permission_name}")
    return True

def validate_event_type(event_type):
    valid_types = ["multiPathRecommendation"]
    if event_type not in valid_types:
        print(f"事件类型无效: {event_type}")
        print(f"有效事件类型: {', '.join(valid_types)}")
        return False
    print(f"事件类型有效: {event_type}")
    return True

def main():
    parser = argparse.ArgumentParser(description="多网建议监听技能验证工具")
    
    parser.add_argument("--api-version", type=int, help="检查API版本兼容性")
    parser.add_argument("--permission", type=str, help="检查权限声明")
    parser.add_argument("--event-type", type=str, help="验证事件类型")
    parser.add_argument("--all", action="store_true", help="执行所有检查")
    
    args = parser.parse_args()
    
    if args.all:
        print("执行所有检查...")
        check_api_version(20)
        check_permission("ohos.permission.LINKTURBO")
        validate_event_type("multiPathRecommendation")
        return
    
    if args.api_version:
        check_api_version(args.api_version)
    
    if args.permission:
        check_permission(args.permission)
    
    if args.event_type:
        validate_event_type(args.event_type)
    
    if not any([args.api_version, args.permission, args.event_type, args.all]):
        parser.print_help()

if __name__ == "__main__":
    main()