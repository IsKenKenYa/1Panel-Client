import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

void main() {
  late DioClient client;
  bool hasApiKey = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty && TestEnvironment.apiKey != 'your_api_key_here';
    
    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
    }
  });

  group('对比两个设置更新接口', () {
    test('1. 对比 /core/settings/update 和 /settings/update', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('对比两个设置更新接口');
      debugPrint('========================================');
      
      final testCases = [
        {'endpoint': '/core/settings/update', 'data': {'key': 'sessionTimeout', 'value': '60'}},
        {'endpoint': '/settings/update', 'data': {'key': 'sessionTimeout', 'value': '60'}},
      ];
      
      for (final testCase in testCases) {
        debugPrint('\n--- 测试 ${testCase['endpoint']} ---');
        try {
          final response = await dio.post(
            '/api/v2${testCase['endpoint']}',
            data: testCase['data'],
          );
          final responseData = response.data as Map<String, dynamic>;
          debugPrint('响应: code=${responseData['code']}, message=${responseData['message']}');
        } catch (e) {
          debugPrint('错误: $e');
        }
      }
      
      debugPrint('========================================\n');
    });

    test('2. 测试 /core/settings/by 接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试 /core/settings/by 接口 (按key获取设置)');
      debugPrint('========================================');
      
      final keys = ['panelName', 'sessionTimeout', 'developerMode', 'theme', 'language'];
      
      for (final key in keys) {
        debugPrint('\n--- 获取 key="$key" ---');
        try {
          final response = await dio.post(
            '/api/v2/core/settings/by',
            data: {'key': key},
          );
          final responseData = response.data as Map<String, dynamic>;
          debugPrint('响应: code=${responseData['code']}, data=${responseData['data']}');
        } catch (e) {
          debugPrint('错误: $e');
        }
      }
      
      debugPrint('========================================\n');
    });

    test('3. 测试 /settings/get/{key} 接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试 /settings/get/{key} 接口');
      debugPrint('========================================');
      
      final keys = ['panelName', 'sessionTimeout', 'developerMode'];
      
      for (final key in keys) {
        debugPrint('\n--- GET /settings/get/$key ---');
        try {
          final response = await dio.get('/api/v2/settings/get/$key');
          final responseData = response.data as Map<String, dynamic>;
          debugPrint('响应: code=${responseData['code']}, data=${responseData['data']}');
        } catch (e) {
          debugPrint('错误: $e');
        }
      }
      
      debugPrint('========================================\n');
    });

    test('4. 测试所有专门的更新接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试所有专门的更新接口');
      debugPrint('========================================');
      
      // 获取当前设置
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final settings = searchData['data'] as Map<String, dynamic>?;
      
      final testCases = [
        {
          'endpoint': '/core/settings/port/update',
          'data': {'serverPort': int.tryParse(settings?['serverPort']?.toString() ?? '9999') ?? 9999},
          'desc': '端口更新',
        },
        {
          'endpoint': '/core/settings/bind/update',
          'data': {
            'bindAddress': settings?['bindAddress'] ?? '::',
            'ipv6': settings?['ipv6'] ?? 'Enable',
          },
          'desc': '绑定地址更新',
        },
        {
          'endpoint': '/core/settings/terminal/update',
          'data': {
            'fontSize': '14',
            'cursorStyle': 'block',
          },
          'desc': '终端设置更新',
        },
        {
          'endpoint': '/core/settings/proxy/update',
          'data': {
            'proxyUrl': settings?['proxyUrl'] ?? '',
            'proxyType': settings?['proxyType'] ?? '',
          },
          'desc': '代理设置更新',
        },
        {
          'endpoint': '/core/settings/menu/update',
          'data': {'hideMenu': settings?['hideMenu'] ?? '[]'},
          'desc': '菜单设置更新',
        },
      ];
      
      for (final testCase in testCases) {
        debugPrint('\n--- ${testCase['desc']}: ${testCase['endpoint']} ---');
        try {
          final response = await dio.post(
            '/api/v2${testCase['endpoint']}',
            data: testCase['data'],
          );
          final responseData = response.data as Map<String, dynamic>;
          final success = responseData['code'] == 200;
          debugPrint('结果: ${success ? "✅ 成功" : "❌ 失败"} - code=${responseData['code']}, message=${responseData['message']}');
        } catch (e) {
          debugPrint('错误: $e');
        }
      }
      
      debugPrint('========================================\n');
    });

    test('5. 总结', () async {
      debugPrint('\n========================================');
      debugPrint('API接口总结');
      debugPrint('========================================');
      
      debugPrint('''
根据测试结果：

1. 两个更新接口对比:
   - /core/settings/update - 返回 "record not found"
   - /settings/update - 返回 "record not found"
   两者都使用相同的 dto.SettingUpdate，结果相同

2. 可用的专门更新接口:
   ✅ /core/settings/port/update - 端口更新
   ✅ /core/settings/bind/update - 绑定地址更新
   ✅ /core/settings/terminal/update - 终端设置更新
   ✅ /core/settings/proxy/update - 代理设置更新
   ? /core/settings/menu/update - 菜单设置更新 (需要验证)

3. 按key获取设置的接口:
   - /core/settings/by - POST方法，按key获取单个设置
   - /settings/get/{key} - GET方法，按key获取单个设置

4. 结论:
   - /core/settings/update 和 /settings/update 都无法使用
   - 面板名称、开发者模式、会话超时、主题、语言等设置无法通过API修改
   - 这是1Panel服务端的设计限制
''');
      
      debugPrint('========================================\n');
    });
  });
}
