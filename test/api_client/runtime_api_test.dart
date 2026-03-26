import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/api/v2/runtime_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';

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
  appLogger.dWithPackage('test.api_client.runtime', '========================================');
  appLogger.dWithPackage('test.api_client.runtime', title);
  if (method != null && path != null) {
    appLogger.dWithPackage('test.api_client.runtime', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(
      'test.api_client.runtime',
      'RequestBody: ${_prettyJson(request)}',
    );
  }
  if (response != null) {
    appLogger.dWithPackage(
      'test.api_client.runtime',
      'Response: ${_prettyJson(response)}',
    );
  }
  appLogger.dWithPackage('test.api_client.runtime', '========================================');
}

Future<Response<Map<String, dynamic>>> _rawGet(DioClient client, String path) {
  return client.get<Map<String, dynamic>>(ApiConstants.buildApiPath(path));
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
  late RuntimeV2Api api;
  bool canRun = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    final apiKey = TestEnvironment.config.getString('PANEL_API_KEY');
    canRun = apiKey.isNotEmpty && apiKey != 'your_api_key_here';

    if (canRun) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: apiKey,
      );
      api = RuntimeV2Api(client);
    }
  });

  group('Runtime API客户端测试', () {
    test('POST /runtimes/search 应该成功', () async {
      if (!canRun) {
        appLogger.wWithPackage('test.api_client.runtime', '跳过测试: 未检测到可用 API Key');
        return;
      }

      final request = const RuntimeSearch(page: 1, pageSize: 10).toJson();
      final raw = await _rawPost(client, '/runtimes/search', data: request);
      _logSection(
        '✅ Raw /runtimes/search',
        method: 'POST',
        path: '/runtimes/search',
        request: request,
        response: raw.data,
      );

      final result = await api.getRuntimes(
        const RuntimeSearch(page: 1, pageSize: 10),
      );
      _logSection(
        '✅ Parsed /runtimes/search',
        response: {
          'total': result.data?.total,
          'items': result.data?.items.map((item) => item.toJson()).toList(),
        },
      );

      expect(result.data, isNotNull);
    });

    test('GET /runtimes/:id 应该成功', () async {
      if (!canRun) {
        appLogger.wWithPackage('test.api_client.runtime', '跳过测试: 未检测到可用 API Key');
        return;
      }

      final runtimes = await api.getRuntimes(
        const RuntimeSearch(page: 1, pageSize: 10),
      );
      if (runtimes.data == null || runtimes.data!.items.isEmpty) {
        appLogger.wWithPackage('test.api_client.runtime', '测试环境暂无 runtime，跳过详情拉取');
        return;
      }

      final runtimeId = runtimes.data!.items.first.id;
      expect(runtimeId, isNotNull);

      final raw = await _rawGet(client, '/runtimes/$runtimeId');
      _logSection(
        '✅ Raw /runtimes/:id',
        method: 'GET',
        path: '/runtimes/$runtimeId',
        response: raw.data,
      );

      final detail = await api.getRuntime(runtimeId!);
      _logSection(
        '✅ Parsed /runtimes/:id',
        response: detail.data?.toJson(),
      );

      expect(detail.data, isNotNull);
    });

    test('修正后的 PHP 或 sync 接口应至少成功一条', () async {
      if (!canRun) {
        appLogger.wWithPackage('test.api_client.runtime', '跳过测试: 未检测到可用 API Key');
        return;
      }

      final runtimes = await api.getRuntimes(
        const RuntimeSearch(page: 1, pageSize: 20, type: 'php'),
      );
      RuntimeInfo? phpRuntime;
      for (final item in runtimes.data?.items ?? const <RuntimeInfo>[]) {
        if (item.type == 'php') {
          phpRuntime = item;
          break;
        }
      }

      if (phpRuntime?.id != null) {
        final id = phpRuntime!.id!;
        final raw = await _rawGet(client, '/runtimes/php/config/$id');
        _logSection(
          '✅ Raw /runtimes/php/config/:id',
          method: 'GET',
          path: '/runtimes/php/config/$id',
          response: raw.data,
        );

        final config = await api.loadPhpConfig(id);
        _logSection(
          '✅ Parsed /runtimes/php/config/:id',
          response: config.data?.toJson(),
        );

        expect(config.data, isNotNull);
        return;
      }

      final raw = await _rawPost(client, '/runtimes/sync', data: const <String, dynamic>{});
      _logSection(
        '✅ Raw /runtimes/sync',
        method: 'POST',
        path: '/runtimes/sync',
        request: const <String, dynamic>{},
        response: raw.data,
      );

      final sync = await api.syncRuntimeStatus();
      _logSection(
        '✅ Parsed /runtimes/sync',
        response: {'statusCode': sync.statusCode},
      );

      expect(sync.statusCode, 200);
    });
  });
}
