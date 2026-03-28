import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';

import '../core/test_config_manager.dart';

String _prettyJson(Object? data) {
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data?.toString() ?? '';
  }
}

void _log(String title, {Object? request, Object? response}) {
  const pkg = 'test.api_client.website_lifecycle';
  appLogger.dWithPackage(pkg, '========================================');
  appLogger.dWithPackage(pkg, title);
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

  group('Website lifecycle API客户端测试', () {
    test('POST /websites/options should respond', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.website_lifecycle', '跳过测试: $skipReason');
        return;
      }

      final request = {'type': 'all'};
      final raw = await _rawPost(client, '/websites/options', data: request);
      _log('raw website options', request: request, response: raw.data);

      final response = await api.getWebsiteOptions(request);
      expect(response, isA<List<Map<String, dynamic>>>());
    });

    test('POST /websites/check should respond', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.website_lifecycle', '跳过测试: $skipReason');
        return;
      }

      final request = <String, dynamic>{};
      final raw = await _rawPost(client, '/websites/check', data: request);
      _log('raw website precheck', request: request, response: raw.data);

      final response = await api.preCheckWebsite(request);
      expect(response, isA<List<Map<String, dynamic>>>());
    });

    test(
        'POST /websites/update and /websites/default/server are destructive-gated',
        () async {
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.website_lifecycle', '跳过测试: $skipReason');
        return;
      }

      final websites = await api.getWebsites(page: 1, pageSize: 1);
      if (websites.items.isEmpty || websites.items.first.id == null) {
        appLogger.wWithPackage(
            'test.api_client.website_lifecycle', '无网站可用于写测试，跳过');
        return;
      }
      final detail = await api.getWebsiteDetail(websites.items.first.id!);

      final updateRequest = {
        'id': detail.id,
        'primaryDomain': detail.primaryDomain,
        'remark': detail.remark ?? '',
        'webSiteGroupId': detail.webSiteGroupId ?? 0,
        'IPV6': detail.ipv6 ?? false,
        'favorite': detail.favorite ?? false,
      };
      final rawUpdate =
          await _rawPost(client, '/websites/update', data: updateRequest);
      _log('raw website update',
          request: updateRequest, response: rawUpdate.data);
      await api.updateWebsite(updateRequest);

      final defaultRequest = {'id': detail.id};
      final rawDefault = await _rawPost(client, '/websites/default/server',
          data: defaultRequest);
      _log('raw set default website',
          request: defaultRequest, response: rawDefault.data);
      await api.changeDefaultServer(id: detail.id!);
    });
  });
}
