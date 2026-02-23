import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanelapp_app/api/v2/website_v2.dart';
import 'package:onepanelapp_app/core/network/dio_client.dart';

import '../core/test_config_manager.dart';

void main() {
  late DioClient client;
  late WebsiteV2Api api;

  setUpAll(() async {
    await TestEnvironment.initialize();

    if (TestEnvironment.canRunIntegrationTests) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = WebsiteV2Api(client);
    }
  });

  group('网站SSL证书 API客户端测试', () {
    test('analyze_module_api 输出文件存在', () {
      final file = File('docs/development/modules/网站SSL证书/ssl_api_analysis.json');
      expect(file.existsSync(), isTrue);
      final jsonStr = file.readAsStringSync();
      final obj = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(obj['module'], equals('ssl'));
    });

    test(
      'GET /websites/:id/https 应该成功',
      () async {
        final skipReason = TestEnvironment.skipIntegration();
        if (skipReason != null) {
          debugPrint('⚠️  跳过测试: $skipReason');
          return;
        }

        final websites = await api.getWebsites(page: 1, pageSize: 1);
        if (websites.items.isEmpty) {
          debugPrint('⚠️  测试服务器暂无网站，跳过站点 https 配置拉取');
          return;
        }

        final websiteId = websites.items.first.id;
        expect(websiteId, isNotNull);

        final https = await api.getWebsiteHttps(websiteId!);

        debugPrint('\n========================================');
        debugPrint('✅ Website https');
        debugPrint('========================================');
        debugPrint('websiteId: $websiteId');
        debugPrint('keys: ${https.keys.toList()}');
        debugPrint('data: $https');
        debugPrint('========================================\n');
      },
    );
  });
}
