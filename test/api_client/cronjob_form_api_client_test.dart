import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/cronjob_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/cronjob_form_request_models.dart';
import 'package:onepanel_client/data/models/cronjob_form_response_models.dart';

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
  appLogger.dWithPackage('test.api_client.cronjob_form',
      '========================================');
  appLogger.dWithPackage('test.api_client.cronjob_form', title);
  if (method != null && path != null) {
    appLogger.dWithPackage(
        'test.api_client.cronjob_form', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(
        'test.api_client.cronjob_form', 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage(
        'test.api_client.cronjob_form', 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage('test.api_client.cronjob_form',
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

  group('Cronjob Form API客户端测试', () {
    test('POST /cronjobs/load/info and /cronjobs/next should succeed',
        () async {
      if (!canRun) return;
      final searchRaw = await _rawPost(
        client,
        '/cronjobs/search',
        data: const <String, dynamic>{
          'page': 1,
          'pageSize': 20,
          'info': '',
          'groupIDs': <int>[],
          'orderBy': 'createdAt',
          'order': 'null',
        },
      );
      final items = (searchRaw.data?['data']?['items'] as List<dynamic>? ??
              const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      if (items.isEmpty) {
        appLogger.wWithPackage(
            'test.api_client.cronjob_form', '跳过 load/info：当前环境没有 cronjob');
        return;
      }
      final id = items.first['id'] as int;
      final infoRaw = await _rawPost(client, '/cronjobs/load/info',
          data: <String, dynamic>{'id': id});
      _logSection('✅ Raw /cronjobs/load/info',
          method: 'POST',
          path: '/cronjobs/load/info',
          request: <String, dynamic>{'id': id},
          response: infoRaw.data);
      final info = await api.loadCronjobInfo(id);
      _logSection('✅ Parsed /cronjobs/load/info', response: {
        'id': info.data?.id,
        'type': info.data?.type,
        'name': info.data?.name
      });

      final nextRaw = await _rawPost(
        client,
        '/cronjobs/next',
        data: const <String, dynamic>{'spec': '0 0 * * *'},
      );
      _logSection('✅ Raw /cronjobs/next',
          method: 'POST',
          path: '/cronjobs/next',
          request: const <String, dynamic>{'spec': '0 0 * * *'},
          response: nextRaw.data);
      final next = await api
          .loadNextHandle(const CronjobNextPreviewRequest(spec: '0 0 * * *'));
      _logSection('✅ Parsed /cronjobs/next', response: next.data);
      expect(next.data, isNotEmpty);
    });

    test('GET /cronjobs/script/options should succeed', () async {
      if (!canRun) return;
      final raw = await client.get<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/cronjobs/script/options'),
      );
      _logSection('✅ Raw /cronjobs/script/options',
          method: 'GET', path: '/cronjobs/script/options', response: raw.data);
      final parsed = await api.getScriptOptions();
      _logSection('✅ Parsed /cronjobs/script/options',
          response: parsed.data?.map((item) => item.name).toList());
      expect(parsed.data, isNotNull);
    });

    test('create/update/delete/import/export stay behind destructive gate',
        () async {
      if (!canRun) return;
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage(
            'test.api_client.cronjob_form', '跳过测试: $skipReason');
        return;
      }

      final create = CronjobOperateRequest(
        name: 'codex-cronjob-${DateTime.now().millisecondsSinceEpoch}',
        groupID: 1,
        type: 'shell',
        specCustom: true,
        spec: '0 0 * * *',
        executor: 'bash',
        scriptMode: 'input',
        script: 'echo codex',
        user: 'root',
      );
      final createRaw =
          await _rawPost(client, '/cronjobs', data: create.toJson());
      _logSection('✅ Raw /cronjobs',
          method: 'POST',
          path: '/cronjobs',
          request: create.toJson(),
          response: createRaw.data);
      await api.createCronjob(create);

      final importRequest = CronjobImportRequest(
        cronjobs: const <CronjobTransItem>[
          CronjobTransItem(
            name: 'imported-codex',
            type: 'shell',
            groupID: 1,
            specCustom: true,
            spec: '0 1 * * *',
            executor: 'bash',
            scriptMode: 'input',
            script: 'echo imported',
          ),
        ],
      );
      final importRaw = await _rawPost(client, '/cronjobs/import',
          data: importRequest.toJson());
      _logSection('✅ Raw /cronjobs/import',
          method: 'POST',
          path: '/cronjobs/import',
          request: importRequest.toJson(),
          response: importRaw.data);
      await api.importCronjobs(importRequest);

      final export =
          await api.exportCronjobs(const CronjobExportRequest(ids: <int>[]));
      _logSection('✅ Parsed /cronjobs/export',
          response: Uint8List.fromList(export.data ?? const <int>[]).length);
      expect(export.data, isNotNull);
    });
  });
}
