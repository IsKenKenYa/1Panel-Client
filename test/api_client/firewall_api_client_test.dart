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
  // v2.5.1 面板移除了旧版 V1 防火墙端点（/hosts/firewall/base|search 等），
  // 服务器返回 404 时按版本差异软跳过；统一防火墙 V2 由
  // firewall_v2_alignment_test.dart 覆盖。
  bool v1EndpointsRemoved = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    canRun = TestEnvironment.canRunIntegrationTests;

    if (canRun) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = FirewallV2Api(client);
      try {
        await _rawPost(
          client,
          '/hosts/firewall/search',
          data: const FirewallRuleSearch(page: 1, pageSize: 1, type: 'address').toJson(),
        );
      } catch (e) {
        if (e.toString().contains('404')) {
          v1EndpointsRemoved = true;
        } else {
          rethrow;
        }
      }
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
      if (v1EndpointsRemoved) {
        appLogger.wWithPackage(
          'test.api_client.firewall',
          '跳过测试: 服务器已移除旧版 V1 防火墙端点',
        );
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
      if (v1EndpointsRemoved) {
        appLogger.wWithPackage(
          'test.api_client.firewall',
          '跳过测试: 服务器已移除旧版 V1 防火墙端点',
        );
        return;
      }

      const request = FirewallRuleSearch(
        page: 1,
        pageSize: 10,
        type: 'address',
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
