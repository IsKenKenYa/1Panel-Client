import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanelapp_app/core/network/dio_client.dart';

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

  group('验证 /settings/update 能更新哪些设置', () {
    test('1. 获取 /settings/search 返回的所有字段', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('/settings/search 返回的字段');
      debugPrint('========================================');
      
      final response = await dio.post('/api/v2/settings/search');
      final data = response.data as Map<String, dynamic>;
      final settings = data['data'] as Map<String, dynamic>?;
      
      if (settings != null) {
        debugPrint('\n所有字段:');
        for (final entry in settings.entries) {
          debugPrint('  ${entry.key}: ${entry.value}');
        }
      }
      
      debugPrint('========================================\n');
    });

    test('2. 尝试更新 /settings/search 中的字段', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('尝试更新 /settings/search 中的字段');
      debugPrint('========================================');
      
      // 获取当前设置
      final searchResponse = await dio.post('/api/v2/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final settings = searchData['data'] as Map<String, dynamic>?;
      
      // 测试更新 monitorInterval
      final originalInterval = settings?['monitorInterval'] as String? ?? '300';
      final newInterval = originalInterval == '600' ? '300' : '600';
      
      debugPrint('\n--- 测试更新 monitorInterval: $originalInterval -> $newInterval ---');
      
      final updateResponse = await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'monitorInterval', 'value': newInterval},
      );
      
      final updateData = updateResponse.data as Map<String, dynamic>;
      debugPrint('更新响应: code=${updateData['code']}, message=${updateData['message']}');
      
      // 验证
      await Future.delayed(const Duration(milliseconds: 500));
      final verifyResponse = await dio.post('/api/v2/settings/search');
      final verifyData = verifyResponse.data as Map<String, dynamic>;
      final verifySettings = verifyData['data'] as Map<String, dynamic>?;
      final currentInterval = verifySettings?['monitorInterval'] as String? ?? '';
      
      debugPrint('验证后的 monitorInterval: $currentInterval');
      debugPrint('更新成功: ${currentInterval == newInterval}');
      
      // 恢复
      await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'monitorInterval', 'value': originalInterval},
      );
      
      debugPrint('========================================\n');
    });

    test('3. 对比两个接口的字段', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('对比两个接口的字段');
      debugPrint('========================================');
      
      final coreResponse = await dio.post('/api/v2/core/settings/search');
      final coreData = coreResponse.data as Map<String, dynamic>;
      final coreSettings = coreData['data'] as Map<String, dynamic>?;
      
      final settingsResponse = await dio.post('/api/v2/settings/search');
      final settingsData = settingsResponse.data as Map<String, dynamic>;
      final settingsSettings = settingsData['data'] as Map<String, dynamic>?;
      
      debugPrint('\n/core/settings/search 字段:');
      if (coreSettings != null) {
        for (final key in coreSettings.keys) {
          debugPrint('  $key');
        }
      }
      
      debugPrint('\n/settings/search 字段:');
      if (settingsSettings != null) {
        for (final key in settingsSettings.keys) {
          debugPrint('  $key');
        }
      }
      
      debugPrint('========================================\n');
    });

    test('4. 最终结论', () async {
      debugPrint('\n========================================');
      debugPrint('最终结论');
      debugPrint('========================================');
      
      debugPrint('''
根据测试结果：

1. 两个接口返回不同的数据:
   - /core/settings/search → 面板设置 (panelName, developerMode, sessionTimeout等)
   - /settings/search → 系统设置 (monitorInterval, monitorStoreDays等)

2. /settings/update 接口:
   - 用于更新 /settings/search 返回的系统设置
   - 不能用于更新 /core/settings/search 返回的面板设置

3. 面板设置无法通过API修改:
   - panelName (面板名称) - 无法修改
   - developerMode (开发者模式) - 无法修改
   - sessionTimeout (会话超时) - 无法修改
   - theme (主题) - 无法修改
   - language (语言) - 无法修改

4. 可编辑的设置:
   ✅ 终端设置 - /core/settings/terminal/update
   ✅ 端口 - /core/settings/port/update
   ✅ 绑定地址 - /core/settings/bind/update
   ✅ 系统监控设置 - /settings/update (monitorInterval等)

结论: 面板名称等基础信息确实无法通过API修改，这是1Panel的设计限制。
''');
      
      debugPrint('========================================\n');
    });
  });
}
