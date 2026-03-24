import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../api_client_test_base.dart';
import '../core/test_config_manager.dart';
import 'package:onepanelapp_app/api/v2/database_v2.dart';
import 'package:onepanelapp_app/core/network/dio_client.dart';
import 'package:onepanelapp_app/data/models/common_models.dart';
import 'package:onepanelapp_app/data/models/database_models.dart';

void main() {
  late DioClient client;
  late DatabaseV2Api api;
  bool hasApiKey = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty && TestEnvironment.apiKey != 'your_api_key_here';
    
    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = DatabaseV2Api(client);
    }
  });

  group('Database API客户端测试', () {
    test('配置验证 - API密钥已配置', () {
      debugPrint('\n========================================');
      debugPrint('Database API测试配置');
      debugPrint('========================================');
      debugPrint('服务器地址: ${TestEnvironment.baseUrl}');
      debugPrint('API密钥: ${hasApiKey ? "已配置" : "未配置"}');
      debugPrint('========================================\n');
      
      expect(hasApiKey, equals(TestEnvironment.canRunIntegrationTests));
    });

    group('searchDatabases - 搜索数据库', () {
      test('应该成功获取数据库列表', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final request = DatabaseSearch(
          page: 1,
          pageSize: 10,
        );
        final response = await api.searchDatabases(request);

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<PageResult<DatabaseInfo>>());

        final result = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ 数据库列表测试成功');
        debugPrint('========================================');
        debugPrint('总数: ${result.total}');
        debugPrint('当前页: ${result.items.length} 个数据库');

        if (result.items.isNotEmpty) {
          debugPrint('\n数据库列表:');
          for (var i = 0; i < (result.items.length > 5 ? 5 : result.items.length); i++) {
            final db = result.items[i];
            debugPrint('  - ${db.name} (${db.type}) - ${db.status}');
          }
        }
        debugPrint('========================================\n');
      });
    });
  });

  group('Database API性能测试', () {
    test('searchDatabases响应时间应该小于3秒', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final timer = TestPerformanceTimer('searchDatabases');
      timer.start();
      await api.searchDatabases(DatabaseSearch(page: 1, pageSize: 10));
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });
  });
}
