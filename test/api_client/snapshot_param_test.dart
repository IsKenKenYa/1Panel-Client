import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

Map<String, dynamic> _snapshotCreatePayload(String description) =>
    <String, dynamic>{
      'description': description,
      'sourceAccountIDs': '1',
      'downloadAccountID': 1,
    };

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

  group('快照API参数格式测试', () {
    test('测试不同的order参数值', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试不同的order参数值');
      debugPrint('========================================');

      final orderValues = [
        'descending',
        'ascending',
        'desc',
        'asc',
      ];

      for (final order in orderValues) {
        debugPrint('\n--- 测试 order = "$order" ---');
        try {
          final response = await dio.post(
            '/api/v2/settings/snapshot/search',
            data: {
              'page': 1,
              'pageSize': 10,
              'orderBy': 'createdAt',
              'order': order,
            },
          );
          final responseData = response.data as Map<String, dynamic>;
          debugPrint(
              '响应: code=${responseData['code']}, message=${responseData['message']}');

          if (responseData['code'] == 200 && responseData['data'] != null) {
            final data = responseData['data'] as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>? ?? [];
            debugPrint('✅ 成功! 快照数量: ${items.length}');
          }
        } catch (e) {
          debugPrint('错误: $e');
        }
      }

      debugPrint('========================================\n');
    });

    test('测试不同的参数结构', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试不同的参数结构');
      debugPrint('========================================');

      final testCases = [
        {
          'desc': '扁平结构',
          'data': {
            'page': 1,
            'pageSize': 10,
            'orderBy': 'createdAt',
            'order': 'descending',
          }
        },
        {
          'desc': '扁平结构 desc',
          'data': {
            'page': 1,
            'pageSize': 10,
            'orderBy': 'createdAt',
            'order': 'desc',
          }
        },
      ];

      for (final testCase in testCases) {
        debugPrint('\n--- ${testCase['desc']} ---');
        debugPrint('参数: ${jsonEncode(testCase['data'])}');
        try {
          final response = await dio.post(
            '/api/v2/settings/snapshot/search',
            data: testCase['data'],
          );
          final responseData = response.data as Map<String, dynamic>;
          debugPrint(
              '响应: code=${responseData['code']}, message=${responseData['message']}');

          if (responseData['code'] == 200 && responseData['data'] != null) {
            final data = responseData['data'] as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>? ?? [];
            debugPrint('✅ 成功! 快照数量: ${items.length}');
          }
        } catch (e) {
          debugPrint('错误: $e');
        }
      }

      debugPrint('========================================\n');
    });

    test('测试快照创建和删除', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试快照创建');
      debugPrint('========================================');

      final createResponse = await dio.post(
        '/api/v2/settings/snapshot',
        data: _snapshotCreatePayload(
          'API Test ${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      final createData = createResponse.data as Map<String, dynamic>;
      debugPrint(
          '创建响应: code=${createData['code']}, message=${createData['message']}');
      debugPrint('创建成功: ${createData['code'] == 200}');

      debugPrint('========================================\n');
    });
  });
}
