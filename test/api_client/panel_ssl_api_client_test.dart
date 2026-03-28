import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';

import '../core/test_config_manager.dart';

void main() {
  late SettingV2Api api;

  setUpAll(() async {
    await TestEnvironment.initialize();
    if (TestEnvironment.canRunIntegrationTests) {
      api = SettingV2Api(
        DioClient(
          baseUrl: TestEnvironment.baseUrl,
          apiKey: TestEnvironment.apiKey,
        ),
      );
    }
  });

  group('Panel SSL API客户端测试', () {
    test('GET /core/settings/ssl/info 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.panel_ssl', '跳过测试: $skipReason');
        return;
      }

      final info = await api.getSSLInfo();
      expect(info.data, isNotNull);
    });

    test('POST /core/settings/ssl/download 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.panel_ssl', '跳过测试: $skipReason');
        return;
      }

      final response = await api.downloadSSL();
      expect(response.data, isNotNull);
    });

    test('POST /core/settings/ssl/update 使用环境变量证书时应成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      final destructiveSkip = TestEnvironment.skipDestructive();
      if (skipReason != null || destructiveSkip != null) {
        appLogger.wWithPackage(
          'test.api_client.panel_ssl',
          '跳过测试: ${skipReason ?? destructiveSkip}',
        );
        return;
      }

      final domain = Platform.environment['TEST_PANEL_SSL_DOMAIN'] ??
          TestEnvironment.config.getString('TEST_PANEL_SSL_DOMAIN');
      final cert = Platform.environment['TEST_PANEL_SSL_CERT'] ??
          TestEnvironment.config.getString('TEST_PANEL_SSL_CERT');
      final key = Platform.environment['TEST_PANEL_SSL_KEY'] ??
          TestEnvironment.config.getString('TEST_PANEL_SSL_KEY');

      if (domain.isEmpty || cert.isEmpty || key.isEmpty) {
        appLogger.wWithPackage(
          'test.api_client.panel_ssl',
          '未配置 TEST_PANEL_SSL_DOMAIN / CERT / KEY，跳过 destructive update',
        );
        return;
      }

      await api.updateSSL(
        SSLUpdate(
          domain: domain,
          sslType: 'selfSigned',
          cert: cert,
          key: key,
        ),
      );
    });
  });
}
