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

  group('Release Notes API测试', () {
    test('POST /core/settings/upgrade/notes - 获取版本说明', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      // 先获取版本列表
      final releasesResponse =
          await dio.get('/api/v2/core/settings/upgrade/releases');
      final releasesData = releasesResponse.data as Map<String, dynamic>;
      final releases = releasesData['data'] as List<dynamic>?;

      if (releases == null || releases.isEmpty) {
        debugPrint('⚠️  没有可用版本');
        return;
      }

      final firstVersion = releases.first['version'] as String?;
      debugPrint('\n========================================');
      debugPrint('测试版本: $firstVersion');
      debugPrint('========================================');

      // 测试获取版本说明
      final response = await dio.post(
        '/api/v2/core/settings/upgrade/notes',
        data: {'version': firstVersion},
      );

      debugPrint('\n--- 原始响应 ---');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据类型: ${response.data.runtimeType}');

      if (response.data != null) {
        final jsonStr =
            const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('原始数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });
  });
}
