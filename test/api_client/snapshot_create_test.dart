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

  group('快照创建API测试', () {
    test('POST /settings/snapshot - 使用正确格式创建快照', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试: POST /settings/snapshot 创建快照');
      debugPrint('========================================');

      // 测试不同的请求格式
      final testCases = [
        {
          'description': '测试快照',
          'sourceAccountIDs': '1',
          'downloadAccountID': 1,
        },
        {
          'sourceAccountIDs': '1',
          'downloadAccountID': 1,
        },
      ];

      for (var i = 0; i < testCases.length; i++) {
        debugPrint('\n--- 测试用例 ${i + 1}: ${testCases[i]} ---');
        try {
          final response = await dio.post(
            '/api/v2/settings/snapshot',
            data: testCases[i],
          );
          debugPrint('成功! 状态码: ${response.statusCode}');
          if (response.data != null) {
            final jsonStr =
                const JsonEncoder.withIndent('  ').convert(response.data);
            debugPrint('响应数据:\n$jsonStr');
          }
          break; // 成功就退出
        } catch (e) {
          debugPrint('失败: $e');
        }
      }
      debugPrint('========================================\n');
    });
  });
}
