import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/system_group_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';

import '../core/test_config_manager.dart';

const String _pkg = 'test.api_client.group';

String _prettyJson(Object? data) {
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data?.toString() ?? '';
  }
}

void _logSection(String title,
    {String? method, String? path, Object? request, Object? response}) {
  appLogger.dWithPackage(_pkg, '========================================');
  appLogger.dWithPackage(_pkg, title);
  if (method != null && path != null) {
    appLogger.dWithPackage(_pkg, 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(_pkg, 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage(_pkg, 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage(_pkg, '========================================');
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
  late SystemGroupV2Api api;
  bool canRun = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    canRun = TestEnvironment.canRunIntegrationTests;
    if (canRun) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = SystemGroupV2Api(client);
    }
  });

  test('POST /core/groups/search 返回真实 host 分组结构', () async {
    final skipReason =
        TestEnvironment.skipIntegration() ?? TestEnvironment.skipNoApiKey();
    if (skipReason != null) {
      appLogger.wWithPackage(_pkg, '跳过测试: $skipReason');
      return;
    }

    const request = GroupSearch(type: 'host');
    final raw = await _rawPost(
      client,
      '/core/groups/search',
      data: request.toJson(),
    );
    _logSection(
      '✅ Raw /core/groups/search',
      method: 'POST',
      path: '/core/groups/search',
      request: request.toJson(),
      response: raw.data,
    );

    expect(raw.statusCode, equals(200));
    expect(raw.data, isNotNull);
    expect(raw.data, containsPair('code', 200));
    expect(raw.data, contains('data'));
    final rawItems = raw.data!['data'];
    expect(rawItems, isA<List<dynamic>>());

    final parsed = await api.searchCoreGroups(request);
    _logSection(
      '✅ Parsed /core/groups/search',
      response: parsed.data?.map((group) => group.toJson()).toList(),
    );

    expect(parsed.statusCode, equals(200));
    expect(parsed.data, hasLength((rawItems as List<dynamic>).length));
    for (var i = 0; i < rawItems.length; i++) {
      final rawItem = Map<String, dynamic>.from(rawItems[i] as Map);
      final group = parsed.data![i];
      expect(group.id, equals(rawItem['id']));
      expect(group.name, equals(rawItem['name']));
      expect(group.type, equals(rawItem['type']));
      expect(group.isDefault, equals(rawItem['isDefault']));
    }
  });
}
