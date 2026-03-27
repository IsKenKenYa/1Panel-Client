import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/backup_account_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/backup_request_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';

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
  appLogger.dWithPackage('test.api_client.backup', '========================================');
  appLogger.dWithPackage('test.api_client.backup', title);
  if (method != null && path != null) {
    appLogger.dWithPackage('test.api_client.backup', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage('test.api_client.backup', 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage('test.api_client.backup', 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage('test.api_client.backup', '========================================');
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
  late BackupAccountV2Api api;
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
      api = BackupAccountV2Api(client);
    }
  });

  group('Backup API客户端测试', () {
    test('search/options/record search/size/search files should succeed', () async {
      if (!canRun) return;
      final accounts = await api.searchBackupAccounts(
        const BackupAccountSearchRequest(page: 1, pageSize: 20),
      );
      _logSection('✅ Parsed /backups/search', response: {'total': accounts.data?.total});
      final options = await api.getBackupAccountOptions();
      _logSection('✅ Parsed /backups/options', response: options.data?.map((item) => item.name).toList());
      expect(options.data, isNotNull);

      final recordsRaw = await _rawPost(
        client,
        '/backups/record/search',
        data: const BackupRecordQuery(type: 'app').toJson(),
      );
      _logSection('✅ Raw /backups/record/search', method: 'POST', path: '/backups/record/search', request: const BackupRecordQuery(type: 'app').toJson(), response: recordsRaw.data);
      final records = await api.searchBackupRecords(const BackupRecordQuery(type: 'app'));
      _logSection('✅ Parsed /backups/record/search', response: {'total': records.data?.total});

      final sizes = await api.loadBackupRecordSizes(
        const BackupRecordSizeQuery(type: 'app'),
      );
      _logSection('✅ Parsed /backups/record/size', response: sizes.data?.length);

      final firstAccountId = accounts.data == null || accounts.data!.items.isEmpty
          ? null
          : accounts.data!.items.first.id;
      if (firstAccountId != null) {
        final files = await api.listBackupFiles(OperateByID(id: firstAccountId));
        _logSection('✅ Parsed /backups/search/files', response: files.data);
      }
    });

    test('check/client info/refresh token/backup/recover stay behind destructive gate', () async {
      if (!canRun) return;
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.backup', '跳过测试: $skipReason');
        return;
      }

      final checkRequest = const BackupOperate(
        name: 'codex-check',
        type: 'SFTP',
        accessKey: 'root',
        credential: 'password',
        backupPath: '/tmp',
        vars: '{"address":"127.0.0.1","port":22,"authMode":"password"}',
      );
      final checkRaw = await _rawPost(client, '/backups/conn/check', data: checkRequest.toJson());
      _logSection('✅ Raw /backups/conn/check', method: 'POST', path: '/backups/conn/check', request: checkRequest.toJson(), response: checkRaw.data);
      await api.checkBackupConnection(checkRequest);

      final clientInfo = await api.getBackupClientInfo('Onedrive');
      _logSection('✅ Parsed /core/backups/client/Onedrive', response: clientInfo.data?.toJson());

      final accounts = await api.searchBackupAccounts(
        const BackupAccountSearchRequest(page: 1, pageSize: 20),
      );
      final account = accounts.data == null
          ? null
          : accounts.data!.items.where((item) => item.id != null).isEmpty
              ? null
              : accounts.data!.items.where((item) => item.id != null).first;
      if (account != null) {
        await api.refreshBackupToken(OperateByID(id: account.id!));
      }

      final backup = const BackupRunRequest(
        type: 'app',
        name: 'wordpress',
        detailName: 'wordpress',
        taskID: 'task-codex',
      );
      await api.backupSystemData(backup);
    });
  });
}
