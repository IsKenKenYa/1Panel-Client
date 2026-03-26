import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/api/v2/backup_account_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
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
  appLogger.dWithPackage(
    'test.api_client.backup_account',
    '========================================',
  );
  appLogger.dWithPackage('test.api_client.backup_account', title);
  if (method != null && path != null) {
    appLogger.dWithPackage(
      'test.api_client.backup_account',
      'Request: $method $path',
    );
  }
  if (request != null) {
    appLogger.dWithPackage(
      'test.api_client.backup_account',
      'RequestBody: ${_prettyJson(request)}',
    );
  }
  if (response != null) {
    appLogger.dWithPackage(
      'test.api_client.backup_account',
      'Response: ${_prettyJson(response)}',
    );
  }
  appLogger.dWithPackage(
    'test.api_client.backup_account',
    '========================================',
  );
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

  group('Backup Account API客户端测试', () {
    test('POST /backups/search 应该成功', () async {
      if (!canRun) {
        appLogger.wWithPackage(
          'test.api_client.backup_account',
          '跳过测试: 未检测到可用 API Key',
        );
        return;
      }

      final request = const BackupAccountSearch(
        page: 1,
        pageSize: 10,
      ).toJson();
      final raw = await _rawPost(client, '/backups/search', data: request);
      _logSection(
        '✅ Raw /backups/search',
        method: 'POST',
        path: '/backups/search',
        request: request,
        response: raw.data,
      );

      final result = await api.searchBackupAccounts(
        const BackupAccountSearch(page: 1, pageSize: 10),
      );
      _logSection(
        '✅ Parsed /backups/search',
        response: {
          'total': result.data?.total,
          'items': result.data?.items.map((item) => item.toJson()).toList(),
        },
      );

      expect(result.data, isNotNull);
    });

    test('GET /backups/options 应该成功', () async {
      if (!canRun) {
        appLogger.wWithPackage(
          'test.api_client.backup_account',
          '跳过测试: 未检测到可用 API Key',
        );
        return;
      }

      final raw = await _rawGet(client, '/backups/options');
      _logSection(
        '✅ Raw /backups/options',
        method: 'GET',
        path: '/backups/options',
        response: raw.data,
      );

      final result = await api.getBackupAccountOptions();
      _logSection(
        '✅ Parsed /backups/options',
        response: result.data?.map((item) => item.toJson()).toList(),
      );

      expect(result.statusCode, 200);
    });

    test('POST /backups/search/files 应该与修正后的接口一致', () async {
      if (!canRun) {
        appLogger.wWithPackage(
          'test.api_client.backup_account',
          '跳过测试: 未检测到可用 API Key',
        );
        return;
      }

      final accounts = await api.searchBackupAccounts(
        const BackupAccountSearch(page: 1, pageSize: 10),
      );
      if (accounts.data == null || accounts.data!.items.isEmpty) {
        appLogger.wWithPackage(
          'test.api_client.backup_account',
          '测试环境暂无备份账户，跳过 /backups/search/files',
        );
        return;
      }

      final accountId = accounts.data!.items.first.id;
      expect(accountId, isNotNull);
      final request = <String, dynamic>{'id': accountId};

      final raw = await _rawPost(client, '/backups/search/files', data: request);
      _logSection(
        '✅ Raw /backups/search/files',
        method: 'POST',
        path: '/backups/search/files',
        request: request,
        response: raw.data,
      );

      final result = await api.listBackupFiles(OperateByID(id: accountId!));
      _logSection(
        '✅ Parsed /backups/search/files',
        response: result.data,
      );

      expect(result.data, isA<List<String>>());
    });
  });
}
