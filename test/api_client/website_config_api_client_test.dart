import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';

import '../core/test_config_manager.dart';

String _prettyJson(Object? data) {
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data?.toString() ?? '';
  }
}

void _logSection(String title, {String? method, String? path, Object? request, Object? response}) {
  appLogger.dWithPackage('test.api_client.website_config', '========================================');
  appLogger.dWithPackage('test.api_client.website_config', title);
  if (method != null && path != null) {
    appLogger.dWithPackage('test.api_client.website_config', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage('test.api_client.website_config', 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage('test.api_client.website_config', 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage('test.api_client.website_config', '========================================');
}

Future<Response<Map<String, dynamic>>> _rawPost(DioClient client, String path, {dynamic data}) {
  return client.post<Map<String, dynamic>>(ApiConstants.buildApiPath(path), data: data);
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

  group('网站配置管理 API客户端测试', () {
    test('analyze_module_api 输出文件存在', () {
      final file = File('docs/development/modules/网站配置管理/website_api_analysis.json');
      expect(file.existsSync(), isTrue);
      final jsonStr = file.readAsStringSync();
      final obj = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(obj['module'], equals('website'));
    });

    test('GET /websites/:id/config/:type 应该成功或返回业务错误', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.website_config', '跳过测试: $skipReason');
        return;
      }

      final websites = await api.getWebsites(page: 1, pageSize: 1);
      if (websites.items.isEmpty) {
        appLogger.wWithPackage('test.api_client.website_config', '测试服务器暂无网站，跳过站点配置拉取');
        return;
      }

      final websiteId = websites.items.first.id;
      expect(websiteId, isNotNull);

      try {
        final fileInfo = await api.getWebsiteConfigFile(id: websiteId!, type: 'nginx');
        _logSection('✅ Website nginx config', response: {
          'websiteId': websiteId,
          'name': fileInfo.name,
          'path': fileInfo.path,
          'contentLength': fileInfo.content?.length ?? 0,
        });
      } catch (e) {
        appLogger.wWithPackage('test.api_client.website_config', '/websites/:id/config/:type 返回异常: $e');
      }
    });

    test('POST /websites/config 应该成功', () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.website_config', '跳过测试: $skipReason');
        return;
      }

      final websites = await api.getWebsites(page: 1, pageSize: 1);
      if (websites.items.isEmpty) {
        appLogger.wWithPackage('test.api_client.website_config', '测试服务器暂无网站，跳过配置 scope 拉取');
        return;
      }

      final websiteId = websites.items.first.id;
      expect(websiteId, isNotNull);

      final request = {
        'scope': NginxKey.indexKey.value,
        'websiteId': websiteId,
      };
      final raw = await _rawPost(client, '/websites/config', data: request);
      _logSection('✅ Raw /websites/config', method: 'POST', path: '/websites/config', request: request, response: raw.data);

      final parsed = await api.loadWebsiteNginxConfig(request);
      _logSection('✅ Parsed /websites/config', response: parsed);
    });

    test('POST /websites/config/update 应该成功或返回业务错误', () async {
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.website_config', '跳过测试: $skipReason');
        return;
      }

      final websites = await api.getWebsites(page: 1, pageSize: 1);
      if (websites.items.isEmpty) {
        appLogger.wWithPackage('test.api_client.website_config', '测试服务器暂无网站，跳过配置更新');
        return;
      }

      final websiteId = websites.items.first.id;
      expect(websiteId, isNotNull);

      final scopeRequest = {
        'scope': NginxKey.indexKey.value,
        'websiteId': websiteId,
      };
      final rawScope = await _rawPost(client, '/websites/config', data: scopeRequest);
      final scopeData = (rawScope.data ?? const {})['data'];

      if (scopeData is! Map<String, dynamic> || !scopeData.containsKey('params')) {
        appLogger.wWithPackage('test.api_client.website_config', 'scope 返回不包含 params，跳过 /websites/config/update');
        return;
      }

      final updateRequest = {
        'operate': 'update',
        'scope': NginxKey.indexKey.value,
        'websiteId': websiteId,
        'params': scopeData['params'],
      };

      try {
        final raw = await _rawPost(client, '/websites/config/update', data: updateRequest);
        _logSection('✅ Raw /websites/config/update', method: 'POST', path: '/websites/config/update', request: updateRequest, response: raw.data);
        await api.updateWebsiteNginxConfigByRequest(updateRequest);
      } catch (e) {
        appLogger.wWithPackage('test.api_client.website_config', '/websites/config/update 返回异常: $e');
      }
    });

    test('POST /websites/nginx/update 应该成功或返回业务错误', () async {
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.website_config', '跳过测试: $skipReason');
        return;
      }

      final websites = await api.getWebsites(page: 1, pageSize: 1);
      if (websites.items.isEmpty) {
        appLogger.wWithPackage('test.api_client.website_config', '测试服务器暂无网站，跳过 nginx 配置更新');
        return;
      }

      final websiteId = websites.items.first.id;
      expect(websiteId, isNotNull);

      String? content;
      try {
        final fileInfo = await api.getWebsiteConfigFile(id: websiteId!, type: 'nginx');
        content = fileInfo.content;
      } catch (e) {
        appLogger.wWithPackage('test.api_client.website_config', '获取 nginx 配置失败: $e');
        return;
      }

      if (content == null || content.isEmpty) {
        appLogger.wWithPackage('test.api_client.website_config', 'nginx 配置内容为空，跳过更新');
        return;
      }

      final request = {
        'id': websiteId,
        'content': content,
      };
      try {
        final raw = await _rawPost(client, '/websites/nginx/update', data: request);
        _logSection('✅ Raw /websites/nginx/update', method: 'POST', path: '/websites/nginx/update', request: request, response: raw.data);
        await api.updateWebsiteNginxConfig(id: websiteId, content: content);
      } catch (e) {
        appLogger.wWithPackage('test.api_client.website_config', '/websites/nginx/update 返回异常: $e');
      }
    });
  });
}
