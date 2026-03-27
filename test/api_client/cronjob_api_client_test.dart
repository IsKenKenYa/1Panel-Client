import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/cronjob_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/cronjob_list_models.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';

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
      'test.api_client.cronjob', '========================================');
  appLogger.dWithPackage('test.api_client.cronjob', title);
  if (method != null && path != null) {
    appLogger.dWithPackage('test.api_client.cronjob', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(
      'test.api_client.cronjob',
      'RequestBody: ${_prettyJson(request)}',
    );
  }
  if (response != null) {
    appLogger.dWithPackage(
      'test.api_client.cronjob',
      'Response: ${_prettyJson(response)}',
    );
  }
  appLogger.dWithPackage(
      'test.api_client.cronjob', '========================================');
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

void main() {
  late DioClient client;
  late CronjobV2Api api;
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
      api = CronjobV2Api(client);
    }
  });

  group('Cronjob API客户端测试', () {
    test('POST /cronjobs/search 应该成功', () async {
      if (!canRun) return;
      final request = const CronjobListQuery(page: 1, pageSize: 10).toJson();
      final raw = await _rawPost(client, '/cronjobs/search', data: request);
      _logSection(
        '✅ Raw /cronjobs/search',
        method: 'POST',
        path: '/cronjobs/search',
        request: request,
        response: raw.data,
      );
      final parsed = await api.searchCronjobs(
        const CronjobListQuery(page: 1, pageSize: 10),
      );
      _logSection(
        '✅ Parsed /cronjobs/search',
        response: {
          'total': parsed.data?.total,
          'items': parsed.data?.items
              .map((item) =>
                  {'id': item.id, 'name': item.name, 'status': item.status})
              .toList(),
        },
      );
      expect(parsed.data, isNotNull);
    });

    test('POST /cronjobs/load/info 与 /status 应该成功', () async {
      if (!canRun) return;
      final search = await api.searchCronjobs(
        const CronjobListQuery(page: 1, pageSize: 10),
      );
      if (search.data == null || search.data!.items.isEmpty) {
        return;
      }
      final item = search.data!.items.first;

      final infoRaw = await _rawPost(
        client,
        '/cronjobs/load/info',
        data: <String, dynamic>{'id': item.id},
      );
      _logSection(
        '✅ Raw /cronjobs/load/info',
        method: 'POST',
        path: '/cronjobs/load/info',
        request: <String, dynamic>{'id': item.id},
        response: infoRaw.data,
      );
      final info = await api.loadCronjobInfo(item.id);
      _logSection('✅ Parsed /cronjobs/load/info', response: info.data);

      final statusRequest = <String, dynamic>{
        'id': item.id,
        'status': item.status
      };
      final statusRaw =
          await _rawPost(client, '/cronjobs/status', data: statusRequest);
      _logSection(
        '✅ Raw /cronjobs/status',
        method: 'POST',
        path: '/cronjobs/status',
        request: statusRequest,
        response: statusRaw.data,
      );
      await api.updateCronjobStatus(
        CronjobStatusUpdate(id: item.id, status: item.status),
      );
    });

    test('POST /cronjobs/search/records 和 /records/log 应该成功', () async {
      if (!canRun) return;
      final jobs = await api.searchCronjobs(
        const CronjobListQuery(page: 1, pageSize: 10),
      );
      if (jobs.data == null || jobs.data!.items.isEmpty) {
        return;
      }
      final cronjobId = jobs.data!.items.first.id;
      final request = CronjobRecordQuery(cronjobId: cronjobId);

      final raw = await _rawPost(
        client,
        '/cronjobs/search/records',
        data: request.toJson(),
      );
      _logSection(
        '✅ Raw /cronjobs/search/records',
        method: 'POST',
        path: '/cronjobs/search/records',
        request: request.toJson(),
        response: raw.data,
      );
      final records = await api.searchCronjobRecords(request);
      _logSection(
        '✅ Parsed /cronjobs/search/records',
        response: {
          'total': records.data?.total,
          'items': records.data?.items
              .map((item) => {'id': item.id, 'status': item.status})
              .toList(),
        },
      );

      if (records.data == null || records.data!.items.isEmpty) {
        return;
      }
      final recordId = records.data!.items.first.id;
      final logRaw = await _rawPost(
        client,
        '/cronjobs/records/log',
        data: <String, dynamic>{'id': recordId},
      );
      _logSection(
        '✅ Raw /cronjobs/records/log',
        method: 'POST',
        path: '/cronjobs/records/log',
        request: <String, dynamic>{'id': recordId},
        response: logRaw.data,
      );
      final log = await api.getRecordLog(recordId);
      _logSection('✅ Parsed /cronjobs/records/log', response: log.data);
      expect(log.data, isNotNull);
    });

    test('GET /cronjobs/script/options 应该成功', () async {
      if (!canRun) return;
      final raw = await _rawGet(client, '/cronjobs/script/options');
      _logSection(
        '✅ Raw /cronjobs/script/options',
        method: 'GET',
        path: '/cronjobs/script/options',
        response: raw.data,
      );
      final parsed = await api.getScriptOptions();
      _logSection(
        '✅ Parsed /cronjobs/script/options',
        response: parsed.data
            ?.map((item) => {'id': item.id, 'name': item.name})
            .toList(),
      );
      expect(parsed.data, isNotNull);
    });

    test('POST /cronjobs/handle 仅在 destructive 模式下验证', () async {
      if (!canRun) return;
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.cronjob', '跳过测试: $skipReason');
        return;
      }
      final jobs = await api.searchCronjobs(
        const CronjobListQuery(page: 1, pageSize: 10),
      );
      if (jobs.data == null || jobs.data!.items.isEmpty) {
        appLogger.wWithPackage('test.api_client.cronjob',
            '跳过 destructive handle：当前环境没有可用 cronjob');
        return;
      }
      final cronjobId = jobs.data!.items.first.id;
      final raw = await _rawPost(
        client,
        '/cronjobs/handle',
        data: <String, dynamic>{'id': cronjobId},
      );
      _logSection(
        '✅ Raw /cronjobs/handle',
        method: 'POST',
        path: '/cronjobs/handle',
        request: <String, dynamic>{'id': cronjobId},
        response: raw.data,
      );
      await api.handleCronjobOnce(CronjobHandleRequest(id: cronjobId));
    });
  });
}
