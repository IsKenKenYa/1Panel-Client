import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/script_library_v2.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/network/script_run_ws_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/script_library_models.dart';
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
  appLogger.dWithPackage('test.api_client.script_library',
      '========================================');
  appLogger.dWithPackage('test.api_client.script_library', title);
  if (method != null && path != null) {
    appLogger.dWithPackage(
        'test.api_client.script_library', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(
      'test.api_client.script_library',
      'RequestBody: ${_prettyJson(request)}',
    );
  }
  if (response != null) {
    appLogger.dWithPackage(
      'test.api_client.script_library',
      'Response: ${_prettyJson(response)}',
    );
  }
  appLogger.dWithPackage('test.api_client.script_library',
      '========================================');
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
  late ScriptLibraryV2Api api;
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
      api = ScriptLibraryV2Api(client);
      await _prepareWsConfig();
    }
  });

  group('Script Library API客户端测试', () {
    test('POST /core/script/search 应该成功', () async {
      if (!canRun) return;
      final request = const ScriptLibraryQuery(page: 1, pageSize: 10).toJson();
      final raw = await _rawPost(client, '/core/script/search', data: request);
      _logSection(
        '✅ Raw /core/script/search',
        method: 'POST',
        path: '/core/script/search',
        request: request,
        response: raw.data,
      );
      final parsed = await api.searchScripts(
        const ScriptLibraryQuery(page: 1, pageSize: 10),
      );
      _logSection(
        '✅ Parsed /core/script/search',
        response: {
          'total': parsed.data?.total,
          'items': parsed.data?.items
              .map((item) => {'id': item.id, 'name': item.name})
              .toList(),
        },
      );
      expect(parsed.data, isNotNull);
    });

    test('POST /core/script/sync 应该成功', () async {
      if (!canRun) return;
      final taskId = 'script-sync-${DateTime.now().millisecondsSinceEpoch}';
      final raw = await _rawPost(
        client,
        '/core/script/sync',
        data: <String, dynamic>{'taskID': taskId},
      );
      _logSection(
        '✅ Raw /core/script/sync',
        method: 'POST',
        path: '/core/script/sync',
        request: <String, dynamic>{'taskID': taskId},
        response: raw.data,
      );
      await api.syncScripts(taskId);
    });

    test('GET /core/script/run 仅在 destructive 模式下做 websocket 烟测', () async {
      if (!canRun) return;
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.script_library', '跳过测试: $skipReason');
        return;
      }
      final search = await api.searchScripts(
        const ScriptLibraryQuery(page: 1, pageSize: 20),
      );
      final candidate = search.data?.items.firstWhere(
        (item) => !item.isInteractive,
        orElse: () => const ScriptLibraryInfo(
          id: 0,
          name: '',
          isInteractive: false,
          label: '',
          script: '',
          groupList: <int>[],
          groupBelong: <String>[],
          isSystem: false,
          description: '',
          createdAt: null,
        ),
      );
      if (candidate == null || candidate.id == 0) {
        appLogger.wWithPackage(
          'test.api_client.script_library',
          '跳过 destructive run：当前环境没有非交互脚本',
        );
        return;
      }

      final wsClient = ScriptRunWsClient();
      await wsClient.connect(scriptId: candidate.id);
      final output =
          await wsClient.output.first.timeout(const Duration(seconds: 10));
      _logSection(
        '✅ Parsed /core/script/run',
        response: {'scriptId': candidate.id, 'output': output},
      );
      expect(output, isNotEmpty);
      await wsClient.close();
    });
  });
}
