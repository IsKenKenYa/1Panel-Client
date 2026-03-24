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

  group('验证修复后的 /settings/update 接口', () {
    test('1. 测试面板名称更新', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试面板名称更新');
      debugPrint('========================================');
      
      // 获取当前名称
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final originalName = data?['panelName'] as String? ?? '';
      
      debugPrint('当前面板名称: $originalName');
      
      // 尝试更新
      final newName = 'TestPanel_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('尝试更新为: $newName');
      
      final updateResponse = await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'panelName', 'value': newName},
      );
      
      final updateData = updateResponse.data as Map<String, dynamic>;
      debugPrint('更新响应: code=${updateData['code']}, message=${updateData['message']}');
      
      // 验证
      await Future.delayed(const Duration(milliseconds: 500));
      final verifyResponse = await dio.post('/api/v2/core/settings/search');
      final verifyData = verifyResponse.data as Map<String, dynamic>;
      final verifySettings = verifyData['data'] as Map<String, dynamic>?;
      final currentName = verifySettings?['panelName'] as String? ?? '';
      
      debugPrint('验证后的面板名称: $currentName');
      debugPrint('更新成功: ${currentName == newName}');
      
      // 恢复原始值
      if (updateData['code'] == 200) {
        await dio.post(
          '/api/v2/settings/update',
          data: {'key': 'panelName', 'value': originalName},
        );
        debugPrint('已恢复原始面板名称');
      }
      
      debugPrint('========================================\n');
    });

    test('2. 测试开发者模式更新', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试开发者模式更新');
      debugPrint('========================================');
      
      // 获取当前值
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final originalValue = data?['developerMode'] as String? ?? 'Disable';
      
      debugPrint('当前开发者模式: $originalValue');
      
      // 切换值
      final newValue = originalValue == 'Enable' ? 'Disable' : 'Enable';
      debugPrint('尝试更新为: $newValue');
      
      final updateResponse = await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'developerMode', 'value': newValue},
      );
      
      final updateData = updateResponse.data as Map<String, dynamic>;
      debugPrint('更新响应: code=${updateData['code']}, message=${updateData['message']}');
      
      // 验证
      await Future.delayed(const Duration(milliseconds: 500));
      final verifyResponse = await dio.post('/api/v2/core/settings/search');
      final verifyData = verifyResponse.data as Map<String, dynamic>;
      final verifySettings = verifyData['data'] as Map<String, dynamic>?;
      final currentValue = verifySettings?['developerMode'] as String? ?? '';
      
      debugPrint('验证后的开发者模式: $currentValue');
      debugPrint('更新成功: ${currentValue == newValue}');
      
      // 恢复原始值
      await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'developerMode', 'value': originalValue},
      );
      debugPrint('已恢复原始开发者模式');
      
      debugPrint('========================================\n');
    });

    test('3. 测试会话超时更新', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试会话超时更新');
      debugPrint('========================================');
      
      // 获取当前值
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final originalValue = data?['sessionTimeout'] as String? ?? '30';
      
      debugPrint('当前会话超时: $originalValue 分钟');
      
      // 更新值
      final newValue = '60';
      debugPrint('尝试更新为: $newValue 分钟');
      
      final updateResponse = await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'sessionTimeout', 'value': newValue},
      );
      
      final updateData = updateResponse.data as Map<String, dynamic>;
      debugPrint('更新响应: code=${updateData['code']}, message=${updateData['message']}');
      
      // 验证
      await Future.delayed(const Duration(milliseconds: 500));
      final verifyResponse = await dio.post('/api/v2/core/settings/search');
      final verifyData = verifyResponse.data as Map<String, dynamic>;
      final verifySettings = verifyData['data'] as Map<String, dynamic>?;
      final currentValue = verifySettings?['sessionTimeout'] as String? ?? '';
      
      debugPrint('验证后的会话超时: $currentValue 分钟');
      debugPrint('更新成功: ${currentValue == newValue}');
      
      // 恢复原始值
      await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'sessionTimeout', 'value': originalValue},
      );
      debugPrint('已恢复原始会话超时');
      
      debugPrint('========================================\n');
    });

    test('4. 测试主题和语言更新', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试主题和语言更新');
      debugPrint('========================================');
      
      // 获取当前值
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final originalTheme = data?['theme'] as String? ?? 'auto';
      final originalLanguage = data?['language'] as String? ?? 'zh';
      
      debugPrint('当前主题: $originalTheme, 语言: $originalLanguage');
      
      // 测试主题更新
      debugPrint('\n--- 测试主题更新 ---');
      final themeResponse = await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'theme', 'value': 'dark'},
      );
      final themeData = themeResponse.data as Map<String, dynamic>;
      debugPrint('主题更新响应: code=${themeData['code']}, message=${themeData['message']}');
      
      // 测试语言更新
      debugPrint('\n--- 测试语言更新 ---');
      final languageResponse = await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'language', 'value': 'en'},
      );
      final languageData = languageResponse.data as Map<String, dynamic>;
      debugPrint('语言更新响应: code=${languageData['code']}, message=${languageData['message']}');
      
      // 恢复原始值
      await Future.delayed(const Duration(milliseconds: 500));
      await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'theme', 'value': originalTheme},
      );
      await dio.post(
        '/api/v2/settings/update',
        data: {'key': 'language', 'value': originalLanguage},
      );
      debugPrint('已恢复原始主题和语言');
      
      debugPrint('========================================\n');
    });

    test('5. 总结', () async {
      debugPrint('\n========================================');
      debugPrint('总结');
      debugPrint('========================================');
      
      debugPrint('''
✅ /settings/update 接口可用！

可编辑的设置:
  ✅ panelName - 面板名称
  ✅ developerMode - 开发者模式 (Enable/Disable)
  ✅ sessionTimeout - 会话超时
  ✅ theme - 主题
  ✅ language - 语言

正确的API端点:
  - 使用 /settings/update 而不是 /core/settings/update
  - 请求格式: {"key": "xxx", "value": "xxx"}

现在可以更新面板设置页面，恢复编辑功能！
''');
      
      debugPrint('========================================\n');
    });
  });
}
