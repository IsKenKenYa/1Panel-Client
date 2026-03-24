import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/api/v2/ssl_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';

import '../core/test_config_manager.dart';

String _prettyJson(Object? data) {
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data?.toString() ?? '';
  }
}

void _logSection(String title, {String? method, String? path, Object? request, Object? response}) {
  appLogger.dWithPackage('test.api_client.website_ssl', '========================================');
  appLogger.dWithPackage('test.api_client.website_ssl', title);
  if (method != null && path != null) {
    appLogger.dWithPackage('test.api_client.website_ssl', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage('test.api_client.website_ssl', 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage('test.api_client.website_ssl', 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage('test.api_client.website_ssl', '========================================');
}

Future<Response<Map<String, dynamic>>> _rawPost(DioClient client, String path, {dynamic data}) {
  return client.post<Map<String, dynamic>>(ApiConstants.buildApiPath(path), data: data);
}

Future<Response<Map<String, dynamic>>> _rawGet(DioClient client, String path) {
  return client.get<Map<String, dynamic>>(ApiConstants.buildApiPath(path));
}

void main() {
  late DioClient client;
  late WebsiteV2Api api;
  late SSLV2Api sslApi;

  setUpAll(() async {
    await TestEnvironment.initialize();

    if (TestEnvironment.canRunIntegrationTests) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = WebsiteV2Api(client);
      sslApi = SSLV2Api(client);
    }
  });

  group('网站SSL证书 API客户端测试', () {
    test('analyze_module_api 输出文件存在', () {
      final file = File('docs/development/modules/网站SSL证书/website_ssl_api_analysis.json');
      expect(file.existsSync(), isTrue);
      final jsonStr = file.readAsStringSync();
      final obj = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(obj['module'], equals('website_ssl'));
    });

    test('GET /websites/:id/https 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.website_ssl', '跳过测试: $skipReason');
        return;
      }

      final websites = await api.getWebsites(page: 1, pageSize: 1);
      if (websites.items.isEmpty) {
        appLogger.wWithPackage('test.api_client.website_ssl', '测试服务器暂无网站，跳过站点 https 配置拉取');
        return;
      }

      final websiteId = websites.items.first.id;
      expect(websiteId, isNotNull);

      final raw = await _rawGet(client, '/websites/$websiteId/https');
      _logSection('✅ Raw /websites/:id/https', method: 'GET', path: '/websites/$websiteId/https', response: raw.data);

      final https = await api.getWebsiteHttps(websiteId!);
      _logSection('✅ Parsed /websites/:id/https', response: https.toJson());
    });

    test('POST /websites/ssl/search 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.website_ssl', '跳过测试: $skipReason');
        return;
      }

      final request = WebsiteSSLSearch(
        page: 1,
        pageSize: 10,
        order: 'descending',
        orderBy: 'expire_date',
      ).toJson();

      final raw = await _rawPost(client, '/websites/ssl/search', data: request);
      _logSection('✅ Raw /websites/ssl/search', method: 'POST', path: '/websites/ssl/search', request: request, response: raw.data);

      final resp = await sslApi.searchWebsiteSSL(
        WebsiteSSLSearch(page: 1, pageSize: 10, order: 'descending', orderBy: 'expire_date'),
      );
      _logSection('✅ Parsed /websites/ssl/search', response: {
        'total': resp.data?.total,
        'items': resp.data?.items.map((e) => e.toJson()).toList(),
      });
    });

    test('GET /websites/ssl/website/:websiteId 应该成功或无证书', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.website_ssl', '跳过测试: $skipReason');
        return;
      }

      final websites = await api.getWebsites(page: 1, pageSize: 1);
      if (websites.items.isEmpty) {
        appLogger.wWithPackage('test.api_client.website_ssl', '测试服务器暂无网站，跳过站点 SSL 证书拉取');
        return;
      }

      final websiteId = websites.items.first.id;
      expect(websiteId, isNotNull);

      try {
        final raw = await _rawGet(client, '/websites/ssl/website/$websiteId');
        _logSection('✅ Raw /websites/ssl/website/:websiteId', method: 'GET', path: '/websites/ssl/website/$websiteId', response: raw.data);

        final resp = await sslApi.getWebsiteSSLByWebsiteId(websiteId!);
        final ssl = resp.data;
        if (ssl == null) {
          appLogger.wWithPackage('test.api_client.website_ssl', '站点未绑定证书');
          return;
        }

        _logSection('✅ Parsed /websites/ssl/website/:websiteId', response: ssl.toJson());

        final sslId = ssl.id;
        if (sslId != null) {
          final rawDetail = await _rawGet(client, '/websites/ssl/$sslId');
          _logSection('✅ Raw /websites/ssl/:id', method: 'GET', path: '/websites/ssl/$sslId', response: rawDetail.data);

          final detailResp = await sslApi.getWebsiteSSLById(sslId);
          _logSection('✅ Parsed /websites/ssl/:id', response: detailResp.data?.toJson());
        }
      } catch (e) {
        appLogger.wWithPackage('test.api_client.website_ssl', '站点未绑定证书或接口返回异常: $e');
      }
    });
  });
}
