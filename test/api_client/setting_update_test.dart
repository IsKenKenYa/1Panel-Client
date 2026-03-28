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

  group('设置更新API测试', () {
    test('1. 获取当前系统设置 - 作为基准', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      final rawResponse = await dio.post('/api/v2/core/settings/search');

      debugPrint('\n========================================');
      debugPrint('当前系统设置');
      debugPrint('========================================');

      if (rawResponse.data != null) {
        final jsonStr =
            const JsonEncoder.withIndent('  ').convert(rawResponse.data);
        debugPrint('原始响应:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('2. 测试更新API请求格式 - panelName', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试更新 panelName');
      debugPrint('========================================');

      final requestBody = {'key': 'panelName', 'value': 'TestPanel'};
      debugPrint('请求体: ${jsonEncode(requestBody)}');

      try {
        final rawResponse = await dio.post(
          '/api/v2/core/settings/update',
          data: requestBody,
        );

        debugPrint('状态码: ${rawResponse.statusCode}');
        debugPrint('响应数据类型: ${rawResponse.data.runtimeType}');

        if (rawResponse.data != null) {
          final jsonStr =
              const JsonEncoder.withIndent('  ').convert(rawResponse.data);
          debugPrint('响应数据:\n$jsonStr');
        }
      } catch (e) {
        debugPrint('请求错误: $e');
      }
      debugPrint('========================================\n');
    });

    test('3. 验证更新后的设置', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      final rawResponse = await dio.post('/api/v2/core/settings/search');

      debugPrint('\n========================================');
      debugPrint('更新后的系统设置');
      debugPrint('========================================');

      if (rawResponse.data != null) {
        final jsonStr =
            const JsonEncoder.withIndent('  ').convert(rawResponse.data);
        debugPrint('原始响应:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('4. 测试更新API请求格式 - theme', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试更新 theme');
      debugPrint('========================================');

      final requestBody = {'key': 'theme', 'value': 'dark'};
      debugPrint('请求体: ${jsonEncode(requestBody)}');

      try {
        final rawResponse = await dio.post(
          '/api/v2/core/settings/update',
          data: requestBody,
        );

        debugPrint('状态码: ${rawResponse.statusCode}');
        debugPrint('响应数据类型: ${rawResponse.data.runtimeType}');

        if (rawResponse.data != null) {
          final jsonStr =
              const JsonEncoder.withIndent('  ').convert(rawResponse.data);
          debugPrint('响应数据:\n$jsonStr');
        }
      } catch (e) {
        debugPrint('请求错误: $e');
      }
      debugPrint('========================================\n');
    });

    test('5. 测试终端设置更新', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试更新终端设置');
      debugPrint('========================================');

      final requestBody = {
        'fontSize': 16,
        'cursorStyle': 'block',
        'cursorBlink': 'true',
      };
      debugPrint('请求体: ${jsonEncode(requestBody)}');

      try {
        final rawResponse = await dio.post(
          '/api/v2/core/settings/terminal/update',
          data: requestBody,
        );

        debugPrint('状态码: ${rawResponse.statusCode}');
        debugPrint('响应数据类型: ${rawResponse.data.runtimeType}');

        if (rawResponse.data != null) {
          final jsonStr =
              const JsonEncoder.withIndent('  ').convert(rawResponse.data);
          debugPrint('响应数据:\n$jsonStr');
        }
      } catch (e) {
        debugPrint('请求错误: $e');
      }
      debugPrint('========================================\n');
    });

    test('6. 获取终端设置验证', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      final rawResponse =
          await dio.post('/api/v2/core/settings/terminal/search');

      debugPrint('\n========================================');
      debugPrint('当前终端设置');
      debugPrint('========================================');

      if (rawResponse.data != null) {
        final jsonStr =
            const JsonEncoder.withIndent('  ').convert(rawResponse.data);
        debugPrint('原始响应:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('7. 测试各种key的更新', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      final testCases = [
        {'key': 'language', 'value': 'zh'},
        {'key': 'sessionTimeout', 'value': '60'},
        {'key': 'developerMode', 'value': 'false'},
        {'key': 'ipv6', 'value': 'false'},
      ];

      for (final testCase in testCases) {
        debugPrint('\n----------------------------------------');
        debugPrint('测试更新 ${testCase['key']} = ${testCase['value']}');
        debugPrint('----------------------------------------');

        try {
          final rawResponse = await dio.post(
            '/api/v2/core/settings/update',
            data: testCase,
          );

          debugPrint('状态码: ${rawResponse.statusCode}');
          if (rawResponse.data != null) {
            final jsonStr =
                const JsonEncoder.withIndent('  ').convert(rawResponse.data);
            debugPrint('响应: $jsonStr');
          }
        } catch (e) {
          debugPrint('错误: $e');
        }
      }
    });

    test('8. 最终验证所有设置', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      final rawResponse = await dio.post('/api/v2/core/settings/search');

      debugPrint('\n========================================');
      debugPrint('最终系统设置');
      debugPrint('========================================');

      if (rawResponse.data != null) {
        final jsonStr =
            const JsonEncoder.withIndent('  ').convert(rawResponse.data);
        debugPrint('原始响应:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });
  });
}
