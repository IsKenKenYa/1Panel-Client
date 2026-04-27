import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/ssh_v2.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/network/process_ws_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/ssh_cert_models.dart';
import 'package:onepanel_client/data/models/ssh_log_models.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
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
      'test.api_client.ssh', '========================================');
  appLogger.dWithPackage('test.api_client.ssh', title);
  if (method != null && path != null) {
    appLogger.dWithPackage('test.api_client.ssh', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(
        'test.api_client.ssh', 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage(
        'test.api_client.ssh', 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage(
      'test.api_client.ssh', '========================================');
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
  late SshV2Api api;
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
      api = SshV2Api(client);
      await _prepareWsConfig();
    }
  });

  group('SSH API客户端测试', () {
    test('POST /hosts/ssh/search 应该成功', () async {
      if (!canRun) return;
      final raw = await _rawPost(client, '/hosts/ssh/search');
      _logSection(
        '✅ Raw /hosts/ssh/search',
        method: 'POST',
        path: '/hosts/ssh/search',
        response: raw.data,
      );
      final parsed = await api.getSshInfo();
      _logSection('✅ Parsed /hosts/ssh/search', response: parsed.data);
      expect(parsed.data, isNotNull);
    });

    test('POST /hosts/ssh/update 应支持安全更新', () async {
      if (!canRun) return;
      final info = (await api.getSshInfo()).data!;
      final request = {
        'key': 'UseDNS',
        'oldValue': info.useDNS,
        'newValue': info.useDNS,
      };
      final raw = await _rawPost(client, '/hosts/ssh/update', data: request);
      _logSection(
        '✅ Raw /hosts/ssh/update',
        method: 'POST',
        path: '/hosts/ssh/update',
        request: request,
        response: raw.data,
      );
      await api.updateSsh(
        SshUpdateRequest(
          key: 'UseDNS',
          oldValue: info.useDNS,
          newValue: info.useDNS,
        ),
      );
    });

    test('POST /hosts/ssh/operate 应在 destructive 模式下验证启停操作', () async {
      if (!canRun) return;
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.ssh', '跳过测试: $skipReason');
        return;
      }
      final raw = await _rawPost(
        client,
        '/hosts/ssh/operate',
        data: const <String, dynamic>{'operation': 'restart'},
      );
      _logSection(
        '✅ Raw /hosts/ssh/operate',
        method: 'POST',
        path: '/hosts/ssh/operate',
        request: const <String, dynamic>{'operation': 'restart'},
        response: raw.data,
      );
      await api.operateSsh(const SshOperateRequest(operation: 'restart'));
    });

    test('POST /hosts/ssh/file 与 /file/update 应成功', () async {
      if (!canRun) return;
      const request = {'name': 'sshdConf'};
      final raw = await _rawPost(client, '/hosts/ssh/file', data: request);
      _logSection(
        '✅ Raw /hosts/ssh/file',
        method: 'POST',
        path: '/hosts/ssh/file',
        request: request,
        response: raw.data,
      );
      final file = await api.loadSshFile(const SshFileLoadRequest());
      _logSection('✅ Parsed /hosts/ssh/file', response: file.data);
      expect(file.data, isNotEmpty);

      final updateRequest = {
        'key': 'sshdConf',
        'value': file.data,
      };
      final updateRaw =
          await _rawPost(client, '/hosts/ssh/file/update', data: updateRequest);
      _logSection(
        '✅ Raw /hosts/ssh/file/update',
        method: 'POST',
        path: '/hosts/ssh/file/update',
        request: updateRequest,
        response: updateRaw.data,
      );
      await api.updateSshFile(SshFileUpdateRequest(value: file.data ?? ''));
    });

    test('SSH cert search 与 sync 应成功', () async {
      if (!canRun) return;
      final rawSearch = await _rawPost(
        client,
        '/hosts/ssh/cert/search',
        data: const {'page': 1, 'pageSize': 20},
      );
      _logSection(
        '✅ Raw /hosts/ssh/cert/search',
        method: 'POST',
        path: '/hosts/ssh/cert/search',
        response: rawSearch.data,
      );
      final result = await api.searchSshCerts(const SshCertSearchRequest());
      _logSection(
        '✅ Parsed /hosts/ssh/cert/search',
        response: result.data?.items.map((item) => item.name).toList(),
      );

      final rawSync = await _rawPost(client, '/hosts/ssh/cert/sync');
      _logSection(
        '✅ Raw /hosts/ssh/cert/sync',
        method: 'POST',
        path: '/hosts/ssh/cert/sync',
        response: rawSync.data,
      );
      await api.syncSshCerts();
    });

    test('SSH logs load 与 export 应成功', () async {
      if (!canRun) return;
      final request = const SshLogSearchRequest().toJson();
      final raw = await _rawPost(client, '/hosts/ssh/log', data: request);
      _logSection(
        '✅ Raw /hosts/ssh/log',
        method: 'POST',
        path: '/hosts/ssh/log',
        request: request,
        response: raw.data,
      );
      final result = await api.searchSshLogs(const SshLogSearchRequest());
      _logSection(
        '✅ Parsed /hosts/ssh/log',
        response: result.data?.items.map((item) => item.address).toList(),
      );

      final exportRaw =
          await _rawPost(client, '/hosts/ssh/log/export', data: request);
      _logSection(
        '✅ Raw /hosts/ssh/log/export',
        method: 'POST',
        path: '/hosts/ssh/log/export',
        request: request,
        response: exportRaw.data,
      );
      final exportResult = await api.exportSshLogs(const SshLogSearchRequest());
      _logSection('✅ Parsed /hosts/ssh/log/export',
          response: exportResult.data);
    });

    test('GET /settings/ssh/conn 应返回本地 SSH 连接摘要', () async {
      if (!canRun) return;
      final response = await api.getSshConn();
      _logSection(
        '✅ Parsed /settings/ssh/conn',
        response: response.data?.toJson(),
      );
      expect(response.statusCode, 200);
      expect(response.data, isNotNull);
    });

    test('POST /settings/ssh/check/info 应支持当前本地连接校验', () async {
      if (!canRun) return;
      final connection = (await api.getSshConn()).data;
      if (connection == null || !connection.isConfigured) {
        return;
      }
      final raw = await _rawPost(
        client,
        '/settings/ssh/check/info',
        data: connection.toJson(),
      );
      _logSection(
        '✅ Raw /settings/ssh/check/info',
        method: 'POST',
        path: '/settings/ssh/check/info',
        request: connection.toJson(),
        response: raw.data,
      );
      final parsed = await api.checkSshInfo(request: connection);
      _logSection(
        '✅ Parsed /settings/ssh/check/info',
        response: parsed.data,
      );
      expect(parsed.statusCode, 200);
      expect(parsed.data, equals(raw.data?['data']));
    });

    test('POST /settings/ssh/conn/default 应在 destructive 模式下做同值回放',
        () async {
      if (!canRun) return;
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.ssh', '跳过测试: $skipReason');
        return;
      }
      final connection = (await api.getSshConn()).data;
      final currentValue =
          connection?.localSSHConnShow.isNotEmpty == true
              ? connection!.localSSHConnShow
              : 'Disable';
      final request = SshDefaultConnectionVisibilityUpdate(
        withReset: false,
        defaultConn: currentValue,
      );
      final raw = await _rawPost(
        client,
        '/settings/ssh/conn/default',
        data: request.toJson(),
      );
      _logSection(
        '✅ Raw /settings/ssh/conn/default',
        method: 'POST',
        path: '/settings/ssh/conn/default',
        request: request.toJson(),
        response: raw.data,
      );
      await api.setDefaultSshConn(request);
    });

    test('GET /process/ws 应支持 SSH session websocket 查询', () async {
      if (!canRun) return;
      final wsClient = ProcessWsClient();
      await wsClient.connect();
      final future =
          wsClient.messages.first.timeout(const Duration(seconds: 10));
      await wsClient.send(const SshSessionQuery(loginUser: '').toJson());
      final result = await future;
      _logSection('✅ Parsed /process/ws ssh', response: result);
      expect(result == null || result is List<dynamic>, isTrue);
      await wsClient.close();
    });
  });
}
