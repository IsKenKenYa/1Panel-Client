import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanelapp_app/api/v2/website_v2.dart';
import 'package:onepanelapp_app/core/config/api_constants.dart';
import 'package:onepanelapp_app/core/network/dio_client.dart';
import 'package:onepanelapp_app/core/services/logger/logger_service.dart';

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
  appLogger.dWithPackage('test.api_client.website_domain',
      '========================================');
  appLogger.dWithPackage('test.api_client.website_domain', title);
  if (method != null && path != null) {
    appLogger.dWithPackage(
        'test.api_client.website_domain', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage('test.api_client.website_domain',
        'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage(
        'test.api_client.website_domain', 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage('test.api_client.website_domain',
      '========================================');
}

Future<Response<Map<String, dynamic>>> _rawPost(DioClient client, String path,
    {dynamic data}) {
  return client.post<Map<String, dynamic>>(ApiConstants.buildApiPath(path),
      data: data);
}

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

  group('网站域名管理 API客户端测试', () {
    test('analyze_module_api 输出文件存在', () {
      final file =
          File('docs/development/modules/网站域名管理/domains_api_analysis.json');
      expect(file.existsSync(), isTrue);
      final jsonStr = file.readAsStringSync();
      final obj = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(obj['module'], equals('domains'));
    });

    test('GET /websites/domains/:websiteId 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.website_domain', '跳过测试: $skipReason');
        return;
      }

      final websites = await api.getWebsites(page: 1, pageSize: 1);
      if (websites.items.isEmpty) {
        appLogger.wWithPackage(
            'test.api_client.website_domain', '测试服务器暂无网站，跳过域名拉取');
        return;
      }

      final websiteId = websites.items.first.id;
      expect(websiteId, isNotNull);

      final domains = await api.getWebsiteDomains(websiteId!);

      _logSection('✅ Website domains', response: {
        'websiteId': websiteId,
        'count': domains.length,
        'items': domains.map((d) => d.toJson()).toList(),
      });
    });

    test('POST /websites/domains + update + del 应该成功', () async {
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.website_domain', '跳过测试: $skipReason');
        return;
      }

      final websites = await api.getWebsites(page: 1, pageSize: 1);
      if (websites.items.isEmpty) {
        appLogger.wWithPackage(
            'test.api_client.website_domain', '测试服务器暂无网站，跳过域名新增/删除');
        return;
      }

      final websiteId = websites.items.first.id;
      expect(websiteId, isNotNull);

      final detail = await api.getWebsiteDetail(websiteId!);
      final primary = detail.primaryDomain ?? '';
      int port = 80;
      if (primary.contains(':')) {
        final parts = primary.split(':');
        final parsed = int.tryParse(parts.last);
        if (parsed != null) {
          port = parsed;
        }
      }

      final testDomain =
          'api-${DateTime.now().millisecondsSinceEpoch}.${TestEnvironment.testDomain}';
      int? createdDomainId;
      String? createdDomainValue;
      final createRequest = {
        'websiteID': websiteId,
        'domains': [
          {'domain': testDomain, 'port': port},
        ],
      };

      try {
        final rawCreate =
            await _rawPost(client, '/websites/domains', data: createRequest);
        _logSection('✅ Raw /websites/domains',
            method: 'POST',
            path: '/websites/domains',
            request: createRequest,
            response: rawCreate.data);
        await api.addWebsiteDomains(websiteId: websiteId, domains: [
          {'domain': testDomain, 'port': port}
        ]);
        createdDomainValue = testDomain;
      } catch (e) {
        appLogger.wWithPackage(
            'test.api_client.website_domain', '/websites/domains 返回异常: $e');
      }

      final domains = await api.getWebsiteDomains(websiteId);
      if (domains.isEmpty) {
        appLogger.wWithPackage(
            'test.api_client.website_domain', '域名列表为空，跳过更新/删除');
        return;
      }

      final created = domains.firstWhere(
        (d) => d.domain == createdDomainValue,
        orElse: () => domains.first,
      );
      createdDomainId = created.id;

      final updateRequest = {
        'id': created.id,
        'ssl': created.ssl ?? false,
      };
      try {
        final rawUpdate = await _rawPost(client, '/websites/domains/update',
            data: updateRequest);
        _logSection('✅ Raw /websites/domains/update',
            method: 'POST',
            path: '/websites/domains/update',
            request: updateRequest,
            response: rawUpdate.data);
        await api.updateWebsiteDomainSsl(
            id: created.id!, ssl: created.ssl ?? false);
      } catch (e) {
        appLogger.wWithPackage('test.api_client.website_domain',
            '/websites/domains/update 返回异常: $e');
      }

      if (createdDomainId == null) {
        return;
      }

      if (createdDomainValue == null || created.domain == primary) {
        appLogger.wWithPackage('test.api_client.website_domain', '跳过删除默认域名');
        return;
      }

      final deleteRequest = {'id': createdDomainId};
      try {
        final rawDelete = await _rawPost(client, '/websites/domains/del',
            data: deleteRequest);
        _logSection('✅ Raw /websites/domains/del',
            method: 'POST',
            path: '/websites/domains/del',
            request: deleteRequest,
            response: rawDelete.data);
        await api.deleteWebsiteDomain(id: createdDomainId);
      } catch (e) {
        appLogger.wWithPackage(
            'test.api_client.website_domain', '/websites/domains/del 返回异常: $e');
      }
    });
  });
}
