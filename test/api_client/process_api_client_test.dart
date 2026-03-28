import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/process_v2.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/network/process_ws_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/process_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      'test.api_client.process', '========================================');
  appLogger.dWithPackage('test.api_client.process', title);
  if (method != null && path != null) {
    appLogger.dWithPackage('test.api_client.process', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(
        'test.api_client.process', 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage(
        'test.api_client.process', 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage(
      'test.api_client.process', '========================================');
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

Future<Response<Map<String, dynamic>>> _rawGet(
  DioClient client,
  String path,
) {
  return client.get<Map<String, dynamic>>(ApiConstants.buildApiPath(path));
}

Future<void> _prepareWsConfig() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final config = ApiConfig(
    id: 'test-server',
    name: 'Test',
    url: TestEnvironment.baseUrl,
    apiKey: TestEnvironment.config.getString('PANEL_API_KEY'),
    isDefault: true,
  );
  await ApiConfigManager.saveConfig(config);
  await ApiConfigManager.setCurrentConfig(config.id);
}

void main() {
  late DioClient client;
  late ProcessV2Api api;
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
      api = ProcessV2Api(client);
      await _prepareWsConfig();
    }
  });

  group('Process API客户端测试', () {
    test('POST /process/listening 应成功', () async {
      if (!canRun) return;
      final raw = await _rawPost(client, '/process/listening');
      _logSection(
        '✅ Raw /process/listening',
        method: 'POST',
        path: '/process/listening',
        response: raw.data,
      );
      final result = await api.getListeningProcesses();
      _logSection(
        '✅ Parsed /process/listening',
        response: result.data
            ?.map((item) => {'pid': item.pid, 'ports': item.ports})
            .toList(),
      );
      expect(result.data, isNotNull);
    });

    test('GET /process/ws 应支持进程 websocket 查询', () async {
      if (!canRun) return;
      final wsClient = ProcessWsClient();
      await wsClient.connect();
      final future =
          wsClient.messages.first.timeout(const Duration(seconds: 10));
      await wsClient
          .send(const {'type': 'ps', 'pid': null, 'name': '', 'username': ''});
      final result = await future;
      _logSection('✅ Parsed /process/ws ps', response: result);
      expect(result, isA<List<dynamic>>());
      await wsClient.close();
    });

    test('GET /process/{pid} 应成功', () async {
      if (!canRun) return;
      final wsClient = ProcessWsClient();
      await wsClient.connect();
      final future =
          wsClient.messages.first.timeout(const Duration(seconds: 10));
      await wsClient
          .send(const {'type': 'ps', 'pid': null, 'name': '', 'username': ''});
      final rows = await future as List<dynamic>;
      await wsClient.close();
      if (rows.isEmpty) return;
      final pid = (rows.first as Map<String, dynamic>)['PID'] as int?;
      if (pid == null) return;

      final raw = await _rawGet(client, '/process/$pid');
      _logSection(
        '✅ Raw /process/{pid}',
        method: 'GET',
        path: '/process/$pid',
        response: raw.data,
      );
      final result = await api.getProcessByPid(pid);
      _logSection(
        '✅ Parsed /process/{pid}',
        response: {'pid': result.data?.pid, 'name': result.data?.name},
      );
      expect(result.data?.pid, pid);
    });

    test('POST /process/stop 应在 destructive 模式下成功', () async {
      if (!canRun) return;
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.process', '跳过测试: $skipReason');
        return;
      }
      final wsClient = ProcessWsClient();
      await wsClient.connect();
      final future =
          wsClient.messages.first.timeout(const Duration(seconds: 10));
      await wsClient.send(const <String, dynamic>{
        'type': 'ssh',
        'loginUser': '',
        'loginIP': '',
      });
      final rows = await future;
      await wsClient.close();

      final items = rows is List
          ? rows.whereType<Map<String, dynamic>>().toList()
          : const <Map<String, dynamic>>[];
      if (items.isEmpty) {
        appLogger.wWithPackage(
          'test.api_client.process',
          '跳过 destructive stop：当前测试环境没有可安全断开的 SSH session PID',
        );
        return;
      }

      final pid = items.first['PID'] as int?;
      if (pid == null) {
        appLogger.wWithPackage(
          'test.api_client.process',
          '跳过 destructive stop：SSH session 数据缺少 PID',
        );
        return;
      }

      const path = '/process/stop';
      _logSection(
        '✅ Parsed /process/stop target',
        request: {'PID': pid},
      );
      final raw = await _rawPost(client, path, data: {'PID': pid});
      _logSection(
        '✅ Raw /process/stop',
        method: 'POST',
        path: path,
        request: {'PID': pid},
        response: raw.data,
      );
      await api.stopProcess(ProcessStopRequest(pid: pid));
    });
  });
}
