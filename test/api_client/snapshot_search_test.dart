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

  group('快照搜索API响应结构测试', () {
    test('POST /settings/snapshot/search - 检查响应结构', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      final response =
          await dio.post('/api/v2/settings/snapshot/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });

      debugPrint('\n========================================');
      debugPrint('POST /settings/snapshot/search 完整响应');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');

      if (response.data != null) {
        final jsonStr =
            const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('完整响应数据:\n$jsonStr');

        final data = response.data as Map<String, dynamic>;
        debugPrint('\n--- 数据结构分析 ---');
        debugPrint('顶层 keys: ${data.keys.toList()}');

        if (data['data'] != null) {
          final innerData = data['data'];
          debugPrint('data 类型: ${innerData.runtimeType}');
          if (innerData is Map) {
            debugPrint('data keys: ${innerData.keys.toList()}');
          }
        }
      }
      debugPrint('========================================\n');
    });
  });
}
