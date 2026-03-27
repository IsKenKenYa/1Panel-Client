import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/task_log_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/task_log_models.dart';

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
  appLogger.dWithPackage(
      'test.api_client.task_log', '========================================');
  appLogger.dWithPackage('test.api_client.task_log', title);
  if (method != null && path != null) {
    appLogger.dWithPackage(
        'test.api_client.task_log', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(
      'test.api_client.task_log',
      'RequestBody: ${_prettyJson(request)}',
    );
  }
  if (response != null) {
    appLogger.dWithPackage(
      'test.api_client.task_log',
      'Response: ${_prettyJson(response)}',
    );
  }
  appLogger.dWithPackage(
      'test.api_client.task_log', '========================================');
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
  late TaskLogV2Api api;
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
      api = TaskLogV2Api(client);
    }
  });

  group('Task Log API客户端测试', () {
    test('POST /logs/tasks/search 应该成功', () async {
      if (!canRun) {
        appLogger.wWithPackage(
            'test.api_client.task_log', '跳过测试: 未检测到可用 API Key');
        return;
      }

      final request = const TaskLogSearch(page: 1, pageSize: 10).toJson();
      final raw = await _rawPost(client, '/logs/tasks/search', data: request);
      _logSection(
        '✅ Raw /logs/tasks/search',
        method: 'POST',
        path: '/logs/tasks/search',
        request: request,
        response: raw.data,
      );

      final result = await api.searchTaskLogs(
        const TaskLogSearch(page: 1, pageSize: 10),
      );
      _logSection(
        '✅ Parsed /logs/tasks/search',
        response: {
          'total': result.data?.total,
          'items': result.data?.items.map((item) => item.toJson()).toList(),
        },
      );

      expect(result.data, isNotNull);
    });

    test('GET /logs/tasks/executing/count 应该成功', () async {
      if (!canRun) {
        appLogger.wWithPackage(
            'test.api_client.task_log', '跳过测试: 未检测到可用 API Key');
        return;
      }

      final raw = await _rawGet(client, '/logs/tasks/executing/count');
      _logSection(
        '✅ Raw /logs/tasks/executing/count',
        method: 'GET',
        path: '/logs/tasks/executing/count',
        response: raw.data,
      );

      final result = await api.getExecutingTaskCount();
      _logSection(
        '✅ Parsed /logs/tasks/executing/count',
        response: result.data,
      );

      expect(result.data, isA<int>());
    });
  });
}
