import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/firewall_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';

import '../core/test_config_manager.dart';

String _prettyJson(Object? data) {
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data?.toString() ?? '';
  }
}

void _logSection(
  String title, {
  String? method,
  String? path,
  Object? request,
  Object? response,
}) {
  const pkg = 'test.api_client.firewall';
  appLogger.dWithPackage(pkg, '========================================');
  appLogger.dWithPackage(pkg, title);
  if (method != null && path != null) {
    appLogger.dWithPackage(pkg, 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(pkg, 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage(pkg, 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage(pkg, '========================================');
}

Future<Response<Map<String, dynamic>>> _rawPost(
  DioClient client,
  String path, {
  dynamic data,
}) {
  return client.post<Map<String, dynamic>>(
    ApiConstants.buildApiPath(path),
    data: data,
  );
}

Map<String, dynamic> _pageResultToJson(PageResult<FirewallRule> result) {
  return {
    'total': result.total,
    'page': result.page,
    'pageSize': result.pageSize,
    'totalPages': result.totalPages,
    'items': result.items.map((rule) => rule.toJson()).toList(),
  };
}

void main() {
  late DioClient client;
  late FirewallV2Api api;
  bool canRun = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    canRun = TestEnvironment.canRunIntegrationTests;

    if (canRun) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = FirewallV2Api(client);
    }
  });

  group('Firewall API客户端测试', () {
    test('配置验证 - API密钥与集成测试开关', () {
      const pkg = 'test.api_client.firewall';
      appLogger.iWithPackage(pkg, '========================================');
      appLogger.iWithPackage(pkg, 'Firewall API测试配置');
      appLogger.iWithPackage(pkg, '========================================');
      appLogger.iWithPackage(pkg, '服务器地址: ${TestEnvironment.baseUrl}');
      appLogger.iWithPackage(
          pkg, 'Integration: ${TestEnvironment.runIntegrationTests}');
      appLogger.iWithPackage(
          pkg, 'Destructive: ${TestEnvironment.runDestructiveTests}');
      appLogger.iWithPackage(pkg, '========================================');

      expect(canRun, equals(TestEnvironment.canRunIntegrationTests));
    });

    test('POST /hosts/firewall/base 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.firewall', '跳过测试: $skipReason');
        return;
      }

      const request = {'name': 'base'};
      final raw = await _rawPost(
        client,
        '/hosts/firewall/base',
        data: request,
      );
      _logSection(
        '✅ Raw /hosts/firewall/base',
        method: 'POST',
        path: '/hosts/firewall/base',
        request: request,
        response: raw.data,
      );

      final parsed = await api.loadFirewallBaseInfo(tab: 'base');
      _logSection(
        '✅ Parsed /hosts/firewall/base',
        response: parsed.data?.toJson(),
      );

      expect(parsed.statusCode, equals(200));
      expect(parsed.data, isNotNull);
    });

    test('POST /hosts/firewall/search 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.firewall', '跳过测试: $skipReason');
        return;
      }

      const request = FirewallRuleSearch(
        page: 1,
        pageSize: 10,
      );
      final raw = await _rawPost(
        client,
        '/hosts/firewall/search',
        data: request.toJson(),
      );
      _logSection(
        '✅ Raw /hosts/firewall/search',
        method: 'POST',
        path: '/hosts/firewall/search',
        request: request.toJson(),
        response: raw.data,
      );

      final parsed = await api.searchFirewallRules(request);
      _logSection(
        '✅ Parsed /hosts/firewall/search',
        response: parsed.data == null ? null : _pageResultToJson(parsed.data!),
      );

      expect(parsed.statusCode, equals(200));
      expect(parsed.data, isNotNull);
      expect(parsed.data, isA<PageResult<FirewallRule>>());
    });
  });
}
