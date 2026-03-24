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

  group('快照操作API测试', () {
    test('POST /settings/snapshot/search - 搜索快照', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      final response = await dio.post('/api/v2/settings/snapshot/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      
      debugPrint('\n========================================');
      debugPrint('POST /settings/snapshot/search 响应');
      debugPrint('状态码: ${response.statusCode}');
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('原始数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('POST /settings/snapshot/recover - 恢复快照', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      final searchResponse = await dio.post('/api/v2/settings/snapshot/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      
      final data = searchResponse.data as Map<String, dynamic>;
      final innerData = data['data'] as Map<String, dynamic>?;
      final items = innerData?['items'] as List<dynamic>?;
      
      if (items == null || items.isEmpty) {
        debugPrint('⚠️  没有可用的快照进行恢复测试');
        return;
      }
      
      final snapshotId = items.first['id'];
      debugPrint('\n========================================');
      debugPrint('测试: POST /settings/snapshot/recover 恢复快照 ID: $snapshotId');
      debugPrint('========================================');
      
      try {
        final response = await dio.post('/api/v2/settings/snapshot/recover', data: {'id': snapshotId});
        debugPrint('成功! 状态码: ${response.statusCode}');
        if (response.data != null) {
          final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
          debugPrint('响应数据:\n$jsonStr');
        }
      } catch (e) {
        debugPrint('失败: $e');
      }
      debugPrint('========================================\n');
    });

    test('POST /settings/snapshot/rollback - 回滚快照', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      final searchResponse = await dio.post('/api/v2/settings/snapshot/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      
      final data = searchResponse.data as Map<String, dynamic>;
      final innerData = data['data'] as Map<String, dynamic>?;
      final items = innerData?['items'] as List<dynamic>?;
      
      if (items == null || items.isEmpty) {
        debugPrint('⚠️  没有可用的快照进行回滚测试');
        return;
      }
      
      final snapshotId = items.first['id'];
      debugPrint('\n========================================');
      debugPrint('测试: POST /settings/snapshot/rollback 回滚快照 ID: $snapshotId');
      debugPrint('========================================');
      
      try {
        final response = await dio.post('/api/v2/settings/snapshot/rollback', data: {'id': snapshotId});
        debugPrint('成功! 状态码: ${response.statusCode}');
        if (response.data != null) {
          final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
          debugPrint('响应数据:\n$jsonStr');
        }
      } catch (e) {
        debugPrint('失败: $e');
      }
      debugPrint('========================================\n');
    });

    test('POST /settings/snapshot/description/update - 更新快照描述', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      final searchResponse = await dio.post('/api/v2/settings/snapshot/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      
      final data = searchResponse.data as Map<String, dynamic>;
      final innerData = data['data'] as Map<String, dynamic>?;
      final items = innerData?['items'] as List<dynamic>?;
      
      if (items == null || items.isEmpty) {
        debugPrint('⚠️  没有可用的快照进行更新描述测试');
        return;
      }
      
      final snapshotId = items.first['id'];
      debugPrint('\n========================================');
      debugPrint('测试: POST /settings/snapshot/description/update 更新描述 ID: $snapshotId');
      debugPrint('========================================');
      
      try {
        final response = await dio.post('/api/v2/settings/snapshot/description/update', data: {
          'id': snapshotId,
          'description': '测试描述更新',
        });
        debugPrint('成功! 状态码: ${response.statusCode}');
        if (response.data != null) {
          final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
          debugPrint('响应数据:\n$jsonStr');
        }
      } catch (e) {
        debugPrint('失败: $e');
      }
      debugPrint('========================================\n');
    });
  });
}
