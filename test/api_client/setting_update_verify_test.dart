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
    hasApiKey = TestEnvironment.apiKey.isNotEmpty &&
        TestEnvironment.apiKey != 'your_api_key_here';

    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
    }
  });

  group('设置更新验证测试', () {
    test('1. 获取当前面板名称并尝试修改', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      // Step 1: 获取当前设置
      debugPrint('\n========================================');
      debugPrint('Step 1: 获取当前面板名称');
      debugPrint('========================================');

      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final originalPanelName = data?['panelName'] as String? ?? '';

      debugPrint('当前面板名称: "$originalPanelName"');

      // Step 2: 尝试修改面板名称
      debugPrint('\n========================================');
      debugPrint('Step 2: 尝试修改面板名称');
      debugPrint('========================================');

      final newPanelName = 'TestPanel_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('新面板名称: "$newPanelName"');

      try {
        final updateResponse = await dio.post(
          '/api/v2/core/settings/update',
          data: {'key': 'panelName', 'value': newPanelName},
        );

        debugPrint('更新响应状态码: ${updateResponse.statusCode}');
        debugPrint('更新响应数据: ${jsonEncode(updateResponse.data)}');

        // Step 3: 验证是否修改成功
        debugPrint('\n========================================');
        debugPrint('Step 3: 验证修改是否生效');
        debugPrint('========================================');

        await Future.delayed(const Duration(milliseconds: 500));

        final verifyResponse = await dio.post('/api/v2/core/settings/search');
        final verifyData = verifyResponse.data as Map<String, dynamic>;
        final verifySettings = verifyData['data'] as Map<String, dynamic>?;
        final currentPanelName = verifySettings?['panelName'] as String? ?? '';

        debugPrint('验证后的面板名称: "$currentPanelName"');
        debugPrint('修改是否成功: ${currentPanelName == newPanelName}');

        // Step 4: 恢复原始值
        debugPrint('\n========================================');
        debugPrint('Step 4: 恢复原始面板名称');
        debugPrint('========================================');

        final restoreResponse = await dio.post(
          '/api/v2/core/settings/update',
          data: {'key': 'panelName', 'value': originalPanelName},
        );

        debugPrint('恢复响应状态码: ${restoreResponse.statusCode}');
      } catch (e) {
        debugPrint('更新受限: $e');
      }
      debugPrint('========================================\n');
    });

    test('2. 测试会话超时设置修改', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试会话超时设置修改');
      debugPrint('========================================');

      // 获取当前值
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final originalTimeout = data?['sessionTimeout'] as String? ?? '30';

      debugPrint('当前会话超时: $originalTimeout 分钟');

      // 尝试修改
      final newTimeout = '60';
      debugPrint('尝试修改为: $newTimeout 分钟');

      try {
        final updateResponse = await dio.post(
          '/api/v2/core/settings/update',
          data: {'key': 'sessionTimeout', 'value': newTimeout},
        );

        debugPrint('更新响应: ${jsonEncode(updateResponse.data)}');

        // 验证
        await Future.delayed(const Duration(milliseconds: 500));

        final verifyResponse = await dio.post('/api/v2/core/settings/search');
        final verifyData = verifyResponse.data as Map<String, dynamic>;
        final verifySettings = verifyData['data'] as Map<String, dynamic>?;
        final currentTimeout =
            verifySettings?['sessionTimeout'] as String? ?? '';

        debugPrint('验证后的会话超时: $currentTimeout 分钟');
        debugPrint('修改是否成功: ${currentTimeout == newTimeout}');

        // 恢复
        await dio.post(
          '/api/v2/core/settings/update',
          data: {'key': 'sessionTimeout', 'value': originalTimeout},
        );
      } catch (e) {
        debugPrint('更新受限: $e');
      }

      debugPrint('========================================\n');
    });

    test('3. 测试开发者模式开关', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试开发者模式开关');
      debugPrint('========================================');

      // 获取当前值
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final originalValue = data?['developerMode'] as String? ?? 'Disable';

      debugPrint('当前开发者模式: $originalValue');

      // 尝试切换
      final newValue = originalValue == 'Enable' ? 'Disable' : 'Enable';
      debugPrint('尝试修改为: $newValue');

      try {
        final updateResponse = await dio.post(
          '/api/v2/core/settings/update',
          data: {'key': 'developerMode', 'value': newValue},
        );

        debugPrint('更新响应: ${jsonEncode(updateResponse.data)}');

        // 验证
        await Future.delayed(const Duration(milliseconds: 500));

        final verifyResponse = await dio.post('/api/v2/core/settings/search');
        final verifyData = verifyResponse.data as Map<String, dynamic>;
        final verifySettings = verifyData['data'] as Map<String, dynamic>?;
        final currentValue = verifySettings?['developerMode'] as String? ?? '';

        debugPrint('验证后的开发者模式: $currentValue');
        debugPrint('修改是否成功: ${currentValue == newValue}');

        // 恢复
        await dio.post(
          '/api/v2/core/settings/update',
          data: {'key': 'developerMode', 'value': originalValue},
        );
      } catch (e) {
        debugPrint('更新受限: $e');
      }

      debugPrint('========================================\n');
    });

    test('4. 测试终端设置更新', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试终端设置更新');
      debugPrint('========================================');

      // 获取当前终端设置
      final searchResponse =
          await dio.post('/api/v2/core/settings/terminal/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;

      debugPrint('当前终端设置: ${jsonEncode(data)}');

      // 尝试更新字体大小
      final updateResponse = await dio.post(
        '/api/v2/core/settings/terminal/update',
        data: {'fontSize': '16'},
      );

      debugPrint('更新响应: ${jsonEncode(updateResponse.data)}');

      // 验证
      await Future.delayed(const Duration(milliseconds: 500));

      final verifyResponse =
          await dio.post('/api/v2/core/settings/terminal/search');
      final verifyData = verifyResponse.data as Map<String, dynamic>;
      final verifySettings = verifyData['data'] as Map<String, dynamic>?;

      debugPrint('验证后的终端设置: ${jsonEncode(verifySettings)}');
      debugPrint('========================================\n');
    });

    test('5. 打印完整的设置结构', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('完整的系统设置结构');
      debugPrint('========================================');

      final searchResponse = await dio.post('/api/v2/core/settings/search');

      if (searchResponse.data != null) {
        final jsonStr =
            const JsonEncoder.withIndent('  ').convert(searchResponse.data);
        debugPrint(jsonStr);
      }
      debugPrint('========================================\n');
    });

    test('6. 检查API返回的所有可修改字段', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('可修改字段列表');
      debugPrint('========================================');

      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;

      if (data != null) {
        final editableFields = [
          'panelName',
          'port',
          'bindAddress',
          'theme',
          'language',
          'sessionTimeout',
          'developerMode',
          'ipv6',
          'securityEntrance',
          'bindDomain',
          'allowIPs',
          'complexityVerification',
          'expirationDays',
        ];

        for (final field in editableFields) {
          final value = data[field];
          debugPrint('$field: $value (${value.runtimeType})');
        }
      }
      debugPrint('========================================\n');
    });
  });
}
