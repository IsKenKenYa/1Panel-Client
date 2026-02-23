import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanelapp_app/api/v2/openresty_v2.dart';
import 'package:onepanelapp_app/core/network/dio_client.dart';

import '../core/test_config_manager.dart';

void main() {
  late DioClient client;
  late OpenRestyV2Api api;

  setUpAll(() async {
    await TestEnvironment.initialize();

    if (TestEnvironment.canRunIntegrationTests) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = OpenRestyV2Api(client);
    }
  });

  group('OpenResty API客户端测试', () {
    test('配置验证 - 集成测试开关', () {
      debugPrint('\n========================================');
      debugPrint('OpenResty API测试配置');
      debugPrint('========================================');
      debugPrint('服务器地址: ${TestEnvironment.baseUrl}');
      debugPrint('Integration: ${TestEnvironment.runIntegrationTests}');
      debugPrint('Destructive: ${TestEnvironment.runDestructiveTests}');
      debugPrint('========================================\n');
    });

    test('analyze_module_api 输出文件存在', () {
      final file = File('docs/development/modules/网站管理-OpenResty/openresty_api_analysis.json');
      expect(file.existsSync(), isTrue);
      final jsonStr = file.readAsStringSync();
      final obj = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(obj['module'], equals('openresty'));
    });

    test(
      'GET /openresty/status 应该成功',
      () async {
        final skipReason = TestEnvironment.skipIntegration();
        if (skipReason != null) {
          debugPrint('⚠️  跳过测试: $skipReason');
          return;
        }

        final response = await api.getOpenRestyStatus();
        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);

        debugPrint('\n========================================');
        debugPrint('✅ OpenResty status');
        debugPrint('========================================');
        debugPrint('statusCode: ${response.statusCode}');
        debugPrint('data: ${response.data}');
        debugPrint('========================================\n');
      },
    );

    test(
      'GET /openresty/modules 应该成功',
      () async {
        final skipReason = TestEnvironment.skipIntegration();
        if (skipReason != null) {
          debugPrint('⚠️  跳过测试: $skipReason');
          return;
        }

        final response = await api.getOpenRestyModules();
        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);

        debugPrint('\n========================================');
        debugPrint('✅ OpenResty modules');
        debugPrint('========================================');
        debugPrint('statusCode: ${response.statusCode}');
        debugPrint('data: ${response.data}');
        debugPrint('========================================\n');
      },
    );

    test(
      'GET /openresty/https 应该成功',
      () async {
        final skipReason = TestEnvironment.skipIntegration();
        if (skipReason != null) {
          debugPrint('⚠️  跳过测试: $skipReason');
          return;
        }

        final response = await api.getOpenRestyHttps();
        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);

        debugPrint('\n========================================');
        debugPrint('✅ OpenResty https');
        debugPrint('========================================');
        debugPrint('statusCode: ${response.statusCode}');
        debugPrint('data: ${response.data}');
        debugPrint('========================================\n');
      },
    );

    test(
      'GET /openresty 应该成功',
      () async {
        final skipReason = TestEnvironment.skipIntegration();
        if (skipReason != null) {
          debugPrint('⚠️  跳过测试: $skipReason');
          return;
        }

        final response = await api.getOpenRestyConfig();
        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);

        debugPrint('\n========================================');
        debugPrint('✅ OpenResty config file');
        debugPrint('========================================');
        debugPrint('statusCode: ${response.statusCode}');
        debugPrint('data: ${response.data}');
        debugPrint('========================================\n');
      },
    );
  });
}

