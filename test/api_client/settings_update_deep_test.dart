import 'dart:convert';
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

  group('深入分析 /settings/update 接口', () {
    test('1. 分析更新响应和实际效果', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('分析更新响应和实际效果');
      debugPrint('========================================');
      
      // 获取当前值
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      
      debugPrint('当前设置:');
      debugPrint('  panelName: ${data?['panelName']}');
      debugPrint('  developerMode: ${data?['developerMode']}');
      debugPrint('  sessionTimeout: ${data?['sessionTimeout']}');
      debugPrint('  theme: ${data?['theme']}');
      debugPrint('  language: ${data?['language']}');
      
      // 测试更新 sessionTimeout (这个值比较安全)
      final originalTimeout = data?['sessionTimeout'] as String? ?? '30';
      final newTimeout = originalTimeout == '60' ? '120' : '60';
      
      debugPrint('\n--- 尝试更新 sessionTimeout: $originalTimeout -> $newTimeout ---');
      
      final updateResponse = await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'sessionTimeout', 'value': newTimeout},
      );
      
      debugPrint('更新响应:');
      debugPrint('  statusCode: ${updateResponse.statusCode}');
      debugPrint('  data: ${jsonEncode(updateResponse.data)}');
      
      // 等待更长时间再验证
      debugPrint('\n等待2秒后验证...');
      await Future.delayed(const Duration(seconds: 2));
      
      final verifyResponse = await dio.post('/api/v2/core/settings/search');
      final verifyData = verifyResponse.data as Map<String, dynamic>;
      final verifySettings = verifyData['data'] as Map<String, dynamic>?;
      final currentTimeout = verifySettings?['sessionTimeout'] as String? ?? '';
      
      debugPrint('验证结果:');
      debugPrint('  当前 sessionTimeout: $currentTimeout');
      debugPrint('  期望值: $newTimeout');
      debugPrint('  是否匹配: ${currentTimeout == newTimeout}');
      
      // 恢复
      await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'sessionTimeout', 'value': originalTimeout},
      );
      
      debugPrint('========================================\n');
    });

    test('2. 检查 /settings/search 接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('检查 /settings/search 接口');
      debugPrint('========================================');
      
      final response = await dio.post('/api/v2/settings/search');
      final responseData = response.data as Map<String, dynamic>;
      
      debugPrint('响应: ${jsonEncode(responseData)}');
      
      debugPrint('========================================\n');
    });

    test('3. 对比 /core/settings/search 和 /settings/search', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('对比两个search接口');
      debugPrint('========================================');
      
      final coreResponse = await dio.post('/api/v2/core/settings/search');
      final coreData = coreResponse.data as Map<String, dynamic>;
      
      final settingsResponse = await dio.post('/api/v2/settings/search');
      final settingsData = settingsResponse.data as Map<String, dynamic>;
      
      debugPrint('/core/settings/search 返回字段:');
      if (coreData['data'] != null) {
        final keys = (coreData['data'] as Map<String, dynamic>).keys.toList();
        debugPrint('  ${keys.join(', ')}');
      }
      
      debugPrint('/settings/search 返回字段:');
      if (settingsData['data'] != null) {
        final keys = (settingsData['data'] as Map<String, dynamic>).keys.toList();
        debugPrint('  ${keys.join(', ')}');
      }
      
      debugPrint('========================================\n');
    });

    test('4. 测试不同的value格式', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试不同的value格式');
      debugPrint('========================================');
      
      final testCases = [
        {'key': 'sessionTimeout', 'value': '60'},
        {'key': 'sessionTimeout', 'value': 60},
        {'key': 'developerMode', 'value': 'Enable'},
        {'key': 'developerMode', 'value': 'true'},
        {'key': 'developerMode', 'value': true},
      ];
      
      for (final testCase in testCases) {
        debugPrint('\n--- 测试 ${testCase['key']} = ${testCase['value']} (${testCase['value'].runtimeType}) ---');
        try {
          final response = await dio.post(
            '/api/v2/settings/update',
            data: testCase,
          );
          final responseData = response.data as Map<String, dynamic>;
          debugPrint('响应: code=${responseData['code']}, message=${responseData['message']}');
        } catch (e) {
          debugPrint('错误: $e');
        }
      }
      
      debugPrint('========================================\n');
    });

    test('5. 结论', () async {
      debugPrint('\n========================================');
      debugPrint('结论');
      debugPrint('========================================');
      
      debugPrint('''
根据测试结果：

1. /settings/update 接口返回 code=200 success
   - 但实际值可能没有立即更新
   - 可能需要服务重启才能生效
   - 或者有缓存机制

2. 两个search接口:
   - /core/settings/search - 返回完整的系统设置
   - /settings/search - 需要进一步确认返回内容

3. 建议:
   - 对于面板设置，保持只读显示
   - 只有终端设置、端口、绑定地址可以实时编辑
   - 系统升级功能需要进一步测试

4. 最终结论:
   - 面板名称、主题、语言等设置虽然API返回成功
   - 但实际效果不确定，建议保持只读
   - 用户应通过Web界面修改这些设置
''');
      
      debugPrint('========================================\n');
    });
  });
}
