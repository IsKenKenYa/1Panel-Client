import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../api_client_test_base.dart';
import '../core/test_config_manager.dart';
import 'package:onepanelapp_app/api/v2/website_v2.dart';
import 'package:onepanelapp_app/core/config/api_constants.dart';
import 'package:onepanelapp_app/core/network/dio_client.dart';
import 'package:onepanelapp_app/core/services/logger/logger_service.dart';
import 'package:onepanelapp_app/data/models/common_models.dart';
import 'package:onepanelapp_app/data/models/website_models.dart';

String _prettyJson(Object? data) {
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data?.toString() ?? '';
  }
}

void _logSection(String title, {String? method, String? path, Object? request, Object? response}) {
  appLogger.dWithPackage('test.api_client.website', '========================================');
  appLogger.dWithPackage('test.api_client.website', title);
  if (method != null && path != null) {
    appLogger.dWithPackage('test.api_client.website', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage('test.api_client.website', 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage('test.api_client.website', 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage('test.api_client.website', '========================================');
}

Future<Response<Map<String, dynamic>>> _rawGet(DioClient client, String path) {
  return client.get<Map<String, dynamic>>(ApiConstants.buildApiPath(path));
}

Future<Response<Map<String, dynamic>>> _rawPost(DioClient client, String path, {dynamic data}) {
  return client.post<Map<String, dynamic>>(ApiConstants.buildApiPath(path), data: data);
}

void main() {
  late DioClient client;
  late WebsiteV2Api api;
  bool canRun = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    canRun = TestEnvironment.canRunIntegrationTests;

    if (canRun) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = WebsiteV2Api(client);
    }
  });

  group('Website API客户端测试', () {
    test('配置验证 - API密钥与集成测试开关', () {
      appLogger.iWithPackage('test.api_client.website', '========================================');
      appLogger.iWithPackage('test.api_client.website', 'Website API测试配置');
      appLogger.iWithPackage('test.api_client.website', '========================================');
      appLogger.iWithPackage('test.api_client.website', '服务器地址: ${TestEnvironment.baseUrl}');
      appLogger.iWithPackage('test.api_client.website', 'Integration: ${TestEnvironment.runIntegrationTests}');
      appLogger.iWithPackage('test.api_client.website', 'Destructive: ${TestEnvironment.runDestructiveTests}');
      appLogger.iWithPackage('test.api_client.website', '========================================');

      expect(canRun, equals(TestEnvironment.canRunIntegrationTests));
    });

    test('POST /websites/search 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.website', '跳过测试: $skipReason');
        return;
      }

      final request = WebsiteSearch(page: 1, pageSize: 10).toJson();
      final raw = await _rawPost(client, '/websites/search', data: request);
      _logSection('✅ Raw /websites/search', method: 'POST', path: '/websites/search', request: request, response: raw.data);

      final result = await api.getWebsites(page: 1, pageSize: 10);
      _logSection(
        '✅ Parsed /websites/search',
        response: {
          'total': result.total,
          'page': result.page,
          'pageSize': result.pageSize,
          'items': result.items.map((e) => e.toJson()).toList(),
        },
      );

      expect(result, isA<PageResult<WebsiteInfo>>());
    });

    test('GET /websites/:id 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.website', '跳过测试: $skipReason');
        return;
      }

      final websites = await api.getWebsites(page: 1, pageSize: 1);
      if (websites.items.isEmpty) {
        appLogger.wWithPackage('test.api_client.website', '测试服务器暂无网站，跳过详情拉取');
        return;
      }

      final websiteId = websites.items.first.id;
      expect(websiteId, isNotNull);

      final raw = await _rawGet(client, '/websites/$websiteId');
      _logSection('✅ Raw /websites/:id', method: 'GET', path: '/websites/$websiteId', response: raw.data);

      final detail = await api.getWebsiteDetail(websiteId!);
      _logSection('✅ Parsed /websites/:id', response: detail.toJson());
    });
  });

  group('Website API性能测试', () {
    test('getWebsites响应时间应该小于3秒', () async {
      if (!canRun) {
        appLogger.wWithPackage('test.api_client.website', '跳过测试: API密钥未配置或集成测试未开启');
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
