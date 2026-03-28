import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/openresty_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';

import '../core/test_config_manager.dart';

String _prettyJson(Object? data) {
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data?.toString() ?? '';
  }
}

void _logSection(String title,
    {String? method, String? path, Object? request, Object? response}) {
  appLogger.dWithPackage(
      'test.api_client.openresty', '========================================');
  appLogger.dWithPackage('test.api_client.openresty', title);
  if (method != null && path != null) {
    appLogger.dWithPackage(
        'test.api_client.openresty', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(
        'test.api_client.openresty', 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage(
        'test.api_client.openresty', 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage(
      'test.api_client.openresty', '========================================');
}

Future<Response<Map<String, dynamic>>> _rawGet(DioClient client, String path) {
  return client.get<Map<String, dynamic>>(ApiConstants.buildApiPath(path));
}

Future<Response<Map<String, dynamic>>> _rawPost(DioClient client, String path,
    {dynamic data}) {
  return client.post<Map<String, dynamic>>(ApiConstants.buildApiPath(path),
      data: data);
}

void main() {
  late DioClient client;
  late OpenRestyV2Api api;
  late WebsiteV2Api websiteApi;

  setUpAll(() async {
    await TestEnvironment.initialize();

    if (TestEnvironment.canRunIntegrationTests) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = OpenRestyV2Api(client);
      websiteApi = WebsiteV2Api(client);
    }
  });

  group('OpenResty API客户端测试', () {
    test('配置验证 - 集成测试开关', () {
      appLogger.iWithPackage('test.api_client.openresty',
          '========================================');
      appLogger.iWithPackage('test.api_client.openresty', 'OpenResty API测试配置');
      appLogger.iWithPackage('test.api_client.openresty',
          '========================================');
      appLogger.iWithPackage(
          'test.api_client.openresty', '服务器地址: ${TestEnvironment.baseUrl}');
      appLogger.iWithPackage('test.api_client.openresty',
          'Integration: ${TestEnvironment.runIntegrationTests}');
      appLogger.iWithPackage('test.api_client.openresty',
          'Destructive: ${TestEnvironment.runDestructiveTests}');
      appLogger.iWithPackage('test.api_client.openresty',
          '========================================');
    });

    test('analyze_module_api 输出文件存在', () {
      final file = File(
          'docs/development/modules/网站管理-OpenResty/openresty_api_analysis.json');
      expect(file.existsSync(), isTrue);
      final jsonStr = file.readAsStringSync();
      final obj = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(obj['module'], equals('openresty'));
    });

    test('GET /openresty/status 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.openresty', '跳过测试: $skipReason');
        return;
      }

      final raw = await _rawGet(client, '/openresty/status');
      _logSection('✅ Raw /openresty/status',
          method: 'GET', path: '/openresty/status', response: raw.data);

      final response = await api.getOpenRestyStatus();
      _logSection('✅ Parsed /openresty/status',
          response: response.data?.toJson());
    });

    test('GET /openresty/modules 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.openresty', '跳过测试: $skipReason');
        return;
      }

      final raw = await _rawGet(client, '/openresty/modules');
      _logSection('✅ Raw /openresty/modules',
          method: 'GET', path: '/openresty/modules', response: raw.data);

      final response = await api.getOpenRestyModules();
      _logSection('✅ Parsed /openresty/modules',
          response: response.data?.toJson());
    });

    test('GET /openresty/https 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.openresty', '跳过测试: $skipReason');
        return;
      }

      final raw = await _rawGet(client, '/openresty/https');
      _logSection('✅ Raw /openresty/https',
          method: 'GET', path: '/openresty/https', response: raw.data);

      final response = await api.getOpenRestyHttps();
      _logSection('✅ Parsed /openresty/https',
          response: response.data?.toJson());
    });

    test('GET /openresty 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.openresty', '跳过测试: $skipReason');
        return;
      }

      final raw = await _rawGet(client, '/openresty');
      _logSection('✅ Raw /openresty',
          method: 'GET', path: '/openresty', response: raw.data);

      final response = await api.getOpenRestyConfig();
      _logSection('✅ Parsed /openresty', response: response.data?.toJson());
    });

    test('POST /openresty/scope 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.openresty', '跳过测试: $skipReason');
        return;
      }

      final websites = await websiteApi.getWebsites(page: 1, pageSize: 1);
      final websiteId = websites.items.isEmpty ? null : websites.items.first.id;

      final request = {
        'scope': NginxKey.indexKey.value,
        if (websiteId != null) 'websiteId': websiteId,
      };
      final raw = await _rawPost(client, '/openresty/scope', data: request);
      _logSection('✅ Raw /openresty/scope',
          method: 'POST',
          path: '/openresty/scope',
          request: request,
          response: raw.data);

      final response = await api.getOpenRestyScope(OpenrestyScopeRequest(
          scope: NginxKey.indexKey, websiteId: websiteId));
      _logSection('✅ Parsed /openresty/scope',
          response: response.data?.map((e) => e.toJson()).toList());
    });

    test('POST /openresty/build 应支持 destructive gate', () async {
      final skipReason = TestEnvironment.skipIntegration();
      final destructiveSkip = TestEnvironment.skipDestructive();
      if (skipReason != null || destructiveSkip != null) {
        appLogger.wWithPackage(
          'test.api_client.openresty',
          '跳过测试: ${skipReason ?? destructiveSkip}',
        );
        return;
      }

      await api.buildOpenResty(
        const OpenrestyBuildRequest(
          mirror: '',
          taskId: 's2-3-openresty-build-smoke',
        ),
      );
    });
  });
}
