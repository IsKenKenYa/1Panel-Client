import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/api/v2/logs_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/logs_models.dart';

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
  appLogger.dWithPackage('test.api_client.logs', '========================================');
  appLogger.dWithPackage('test.api_client.logs', title);
  if (method != null && path != null) {
    appLogger.dWithPackage('test.api_client.logs', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(
      'test.api_client.logs',
      'RequestBody: ${_prettyJson(request)}',
    );
  }
  if (response != null) {
    appLogger.dWithPackage(
      'test.api_client.logs',
      'Response: ${_prettyJson(response)}',
    );
  }
  appLogger.dWithPackage('test.api_client.logs', '========================================');
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
  late LogsV2Api api;
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
      api = LogsV2Api(client);
    }
  });

  group('Logs API客户端测试', () {
    test('POST /core/logs/login 应该成功', () async {
      if (!canRun) {
        appLogger.wWithPackage('test.api_client.logs', '跳过测试: 未检测到可用 API Key');
        return;
      }

      final request = const LoginLogSearchRequest(page: 1, pageSize: 10).toJson();
      final raw = await _rawPost(client, '/core/logs/login', data: request);
      _logSection(
        '✅ Raw /core/logs/login',
        method: 'POST',
        path: '/core/logs/login',
        request: request,
        response: raw.data,
      );

      final result = await api.searchLoginLogs(
        const LoginLogSearchRequest(page: 1, pageSize: 10),
      );
      _logSection(
        '✅ Parsed /core/logs/login',
        response: {
          'total': result.data?.total,
          'items': result.data?.items.map((item) => item.toJson()).toList(),
        },
      );

      expect(result.data, isNotNull);
    });

    test('POST /core/logs/operation 应该成功', () async {
      if (!canRun) {
        appLogger.wWithPackage('test.api_client.logs', '跳过测试: 未检测到可用 API Key');
        return;
      }

      final request =
          const OperationLogSearchRequest(page: 1, pageSize: 10).toJson();
      final raw = await _rawPost(client, '/core/logs/operation', data: request);
      _logSection(
        '✅ Raw /core/logs/operation',
        method: 'POST',
        path: '/core/logs/operation',
        request: request,
        response: raw.data,
      );

      final result = await api.searchOperationLogs(
        const OperationLogSearchRequest(page: 1, pageSize: 10),
      );
      _logSection(
        '✅ Parsed /core/logs/operation',
        response: {
          'total': result.data?.total,
          'items': result.data?.items.map((item) => item.toJson()).toList(),
        },
      );

      expect(result.data, isNotNull);
    });

    test('GET /logs/system/files 应该成功', () async {
      if (!canRun) {
        appLogger.wWithPackage('test.api_client.logs', '跳过测试: 未检测到可用 API Key');
        return;
      }

      final raw = await _rawGet(client, '/logs/system/files');
      _logSection(
        '✅ Raw /logs/system/files',
        method: 'GET',
        path: '/logs/system/files',
        response: raw.data,
      );

      final result = await api.getSystemLogFiles();
      _logSection(
        '✅ Parsed /logs/system/files',
        response: result.data,
      );

      expect(result.data, isA<List<String>>());
    });
  });
}
