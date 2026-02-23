import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../api_client_test_base.dart';
import '../core/test_config_manager.dart';
import 'package:onepanelapp_app/api/v2/website_v2.dart';
import 'package:onepanelapp_app/core/network/dio_client.dart';
import 'package:onepanelapp_app/data/models/common_models.dart';
import 'package:onepanelapp_app/data/models/website_models.dart';

void main() {
  late DioClient client;
  late WebsiteV2Api api;
  bool hasApiKey = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty && TestEnvironment.apiKey != 'your_api_key_here';
    
    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = WebsiteV2Api(client);
    }
  });

  group('Website API客户端测试', () {
    test('配置验证 - API密钥已配置', () {
      debugPrint('\n========================================');
      debugPrint('Website API测试配置');
      debugPrint('========================================');
      debugPrint('服务器地址: ${TestEnvironment.baseUrl}');
      debugPrint('API密钥: ${hasApiKey ? "已配置" : "未配置"}');
      debugPrint('========================================\n');
      
      expect(hasApiKey, equals(TestEnvironment.canRunIntegrationTests));
    });

    group('getWebsites - 获取网站列表', () {
      test('应该成功获取网站列表', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getWebsites(page: 1, pageSize: 10);

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<PageResult<WebsiteInfo>>());

        final result = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ 网站列表测试成功');
        debugPrint('========================================');
        debugPrint('总数: ${result.total}');
        debugPrint('当前页: ${result.items.length} 个网站');

        if (result.items.isNotEmpty) {
          debugPrint('\n网站列表:');
          for (var i = 0; i < (result.items.length > 5 ? 5 : result.items.length); i++) {
            final site = result.items[i];
            debugPrint('  - ${site.domain} (${site.status})');
          }
        }
        debugPrint('========================================\n');
      });
    });
  });

  group('Website API性能测试', () {
    test('getWebsites响应时间应该小于3秒', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final timer = TestPerformanceTimer('getWebsites');
      timer.start();
      await api.getWebsites(page: 1, pageSize: 10);
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });
  });
}
