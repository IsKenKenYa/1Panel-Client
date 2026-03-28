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

  group('设置更新请求格式测试', () {
    test('1. 测试不同的请求格式', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试不同的请求格式');
      debugPrint('========================================');

      // 格式1: key-value
      debugPrint('\n--- 格式1: {"key": "panelName", "value": "Test"} ---');
      try {
        final response1 = await dio.post(
          '/api/v2/core/settings/update',
          data: {'key': 'panelName', 'value': 'Test'},
        );
        debugPrint('响应: ${jsonEncode(response1.data)}');
      } catch (e) {
        debugPrint('错误: $e');
      }

      // 格式2: 直接字段
      debugPrint('\n--- 格式2: {"panelName": "Test"} ---');
      try {
        final response2 = await dio.post(
          '/api/v2/core/settings/update',
          data: {'panelName': 'Test'},
        );
        debugPrint('响应: ${jsonEncode(response2.data)}');
      } catch (e) {
        debugPrint('错误: $e');
      }

      // 格式3: data包装
      debugPrint('\n--- 格式3: {"data": {"panelName": "Test"}} ---');
      try {
        final response3 = await dio.post(
          '/api/v2/core/settings/update',
          data: {
            'data': {'panelName': 'Test'}
          },
        );
        debugPrint('响应: ${jsonEncode(response3.data)}');
      } catch (e) {
        debugPrint('错误: $e');
      }

      debugPrint('========================================\n');
    });

    test('2. 测试sessionTimeout更新', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试sessionTimeout更新');
      debugPrint('========================================');

      // 格式1
      debugPrint('\n--- 格式1: {"key": "sessionTimeout", "value": "60"} ---');
      try {
        final response1 = await dio.post(
          '/api/v2/core/settings/update',
          data: {'key': 'sessionTimeout', 'value': '60'},
        );
        debugPrint('响应: ${jsonEncode(response1.data)}');
      } catch (e) {
        debugPrint('错误: $e');
      }

      // 格式2
      debugPrint('\n--- 格式2: {"sessionTimeout": "60"} ---');
      try {
        final response2 = await dio.post(
          '/api/v2/core/settings/update',
          data: {'sessionTimeout': '60'},
        );
        debugPrint('响应: ${jsonEncode(response2.data)}');
      } catch (e) {
        debugPrint('错误: $e');
      }

      debugPrint('========================================\n');
    });

    test('3. 测试developerMode更新', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试developerMode更新');
      debugPrint('========================================');

      // 格式1
      debugPrint('\n--- 格式1: {"key": "developerMode", "value": "Enable"} ---');
      try {
        final response1 = await dio.post(
          '/api/v2/core/settings/update',
          data: {'key': 'developerMode', 'value': 'Enable'},
        );
        debugPrint('响应: ${jsonEncode(response1.data)}');
      } catch (e) {
        debugPrint('错误: $e');
      }

      // 格式2
      debugPrint('\n--- 格式2: {"developerMode": "Enable"} ---');
      try {
        final response2 = await dio.post(
          '/api/v2/core/settings/update',
          data: {'developerMode': 'Enable'},
        );
        debugPrint('响应: ${jsonEncode(response2.data)}');
      } catch (e) {
        debugPrint('错误: $e');
      }

      debugPrint('========================================\n');
    });

    test('4. 检查是否有其他更新接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试其他更新接口');
      debugPrint('========================================');

      // 测试 /core/settings/bind/update
      debugPrint('\n--- 测试 /core/settings/bind/update ---');
      try {
        final response = await dio.post(
          '/api/v2/core/settings/bind/update',
          data: {'bindAddress': '0.0.0.0'},
        );
        debugPrint('响应: ${jsonEncode(response.data)}');
      } catch (e) {
        debugPrint('错误: $e');
      }

      // 测试 /core/settings/port/update
      debugPrint('\n--- 测试 /core/settings/port/update ---');
      try {
        final response = await dio.post(
          '/api/v2/core/settings/port/update',
          data: {'port': '9999'},
        );
        debugPrint('响应: ${jsonEncode(response.data)}');
      } catch (e) {
        debugPrint('错误: $e');
      }

      debugPrint('========================================\n');
    });

    test('5. 获取完整设置并分析字段', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('获取完整设置');
      debugPrint('========================================');

      final response = await dio.post('/api/v2/core/settings/search');
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
  });
}
