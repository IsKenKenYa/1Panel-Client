import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/backup_account_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/backup_request_models.dart';

import '../core/test_config_manager.dart';

String _prettyJson(Object? data) {
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data?.toString() ?? '';
  }
}

void _log(String title, {Object? request, Object? response}) {
  const pkg = 'test.api_client.database_backup';
  appLogger.dWithPackage(pkg, '========================================');
  appLogger.dWithPackage(pkg, title);
  if (request != null) {
    appLogger.dWithPackage(pkg, 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage(pkg, 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage(pkg, '========================================');
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
    canRun = TestEnvironment.canRunIntegrationTests;

    if (canRun) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = BackupAccountV2Api(client);
    }
  });

  group('Database backup API客户端测试', () {
    test('POST /backups/record/search accepts database record search',
        () async {
      final skipReason = TestEnvironment.skipIntegration();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.database_backup', '跳过测试: $skipReason');
        return;
      }

      const request = BackupRecordQuery(
        type: 'mysql',
        name: 'mysql',
        detailName: 'app_db',
        page: 1,
        pageSize: 10,
      );
      final raw = await _rawPost(
        client,
        '/backups/record/search',
        data: request.toJson(),
      );
      _log('raw record search', request: request.toJson(), response: raw.data);

      final response = await api.searchBackupRecords(request);
      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
    });

    test('database backup write flow is gated behind destructive mode',
        () async {
      final skipIntegrationReason = TestEnvironment.skipIntegration();
      if (skipIntegrationReason != null) {
        appLogger.wWithPackage(
            'test.api_client.database_backup', '跳过测试: $skipIntegrationReason');
        return;
      }
      final skipDestructiveReason = TestEnvironment.skipDestructive();
      if (skipDestructiveReason != null) {
        appLogger.wWithPackage(
            'test.api_client.database_backup', '跳过测试: $skipDestructiveReason');
        return;
      }

      final response = await api.backupSystemData(
        const BackupRunRequest(
          type: 'mysql',
          name: 'mysql',
          detailName: 'app_db',
          taskID: 'test-task',
        ),
      );
      expect(response.statusCode, isNotNull);
    });
  });
}
