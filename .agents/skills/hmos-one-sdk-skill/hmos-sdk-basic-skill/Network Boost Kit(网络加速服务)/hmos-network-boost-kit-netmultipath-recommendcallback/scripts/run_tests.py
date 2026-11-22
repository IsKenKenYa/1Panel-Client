import subprocess
import sys
import os

def run_tests():
    test_dir = os.path.join(os.path.dirname(__file__), '..', 'tests')
    
    test_files = [
        'test_subscribe_success.py',
        'test_unsubscribe_success.py',
        'test_callback_handling.py',
        'test_multiple_subscription.py',
        'test_unsubscribe_specific_callback.py',
        'test_unsubscribe_all_callbacks.py',
        'test_permission_denied.py',
        'test_api_version_incompatible.py',
        'test_invalid_parameter.py',
        'test_internal_exception.py',
        'test_system_exception.py'
    ]
    
    print("开始运行测试用例...")
    print("=" * 60)
    
    passed_tests = 0
    failed_tests = 0
    
    for test_file in test_files:
        test_path = os.path.join(test_dir, test_file)
        if not os.path.exists(test_path):
            print(f"测试文件不存在: {test_file}")
            continue
        
        print(f"\n运行测试: {test_file}")
        print("-" * 60)
        
        try:
            result = subprocess.run(
                [sys.executable, test_path],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                print(f"✓ {test_file} - 通过")
                passed_tests += 1
            else:
                print(f"✗ {test_file} - 失败")
                print(f"错误输出:\n{result.stderr}")
                failed_tests += 1
        except subprocess.TimeoutExpired:
            print(f"✗ {test_file} - 超时")
            failed_tests += 1
        except Exception as e:
            print(f"✗ {test_file} - 执行错误: {str(e)}")
            failed_tests += 1
    
    print("\n" + "=" * 60)
    print(f"测试结果总结:")
    print(f"通过: {passed_tests} 个")
    print(f"失败: {failed_tests} 个")
    print(f"总计: {passed_tests + failed_tests} 个")
    print("=" * 60)
    
    return passed_tests, failed_tests

if __name__ == "__main__":
    passed, failed = run_tests()
    sys.exit(0 if failed == 0 else 1)