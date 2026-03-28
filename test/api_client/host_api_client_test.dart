import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/api/v2/host_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/host_asset_models.dart';
import 'package:onepanel_client/data/models/host_models.dart';

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
      'test.api_client.host', '========================================');
  appLogger.dWithPackage('test.api_client.host', title);
  if (method != null && path != null) {
    appLogger.dWithPackage('test.api_client.host', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(
      'test.api_client.host',
      'RequestBody: ${_prettyJson(request)}',
    );
  }
  if (response != null) {
    appLogger.dWithPackage(
      'test.api_client.host',
      'Response: ${_prettyJson(response)}',
    );
  }
  appLogger.dWithPackage(
      'test.api_client.host', '========================================');
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

String _encode(String input) => base64.encode(utf8.encode(input));

void main() {
  late DioClient client;
  late HostV2Api api;
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
      api = HostV2Api(client);
    }
  });

  group('Host API客户端测试', () {
    test('POST /core/hosts/search 应该成功', () async {
      if (!canRun) return;
      final request = const HostSearchRequest(page: 1, pageSize: 10).toJson();
      final raw = await _rawPost(client, '/core/hosts/search', data: request);
      _logSection(
        '✅ Raw /core/hosts/search',
        method: 'POST',
        path: '/core/hosts/search',
        request: request,
        response: raw.data,
      );
      final parsed = await api.searchHostAssets(
        const HostSearchRequest(page: 1, pageSize: 10),
      );
      _logSection(
        '✅ Parsed /core/hosts/search',
        response: {
          'total': parsed.data?.total,
          'items': parsed.data?.items.map((item) => item.toJson()).toList(),
        },
      );
      expect(parsed.data, isNotNull);
    });

    test('POST /core/hosts/info 应该成功', () async {
      if (!canRun) return;
      final hosts = await api.searchHostAssets(
        const HostSearchRequest(page: 1, pageSize: 10),
      );
      if (hosts.data == null || hosts.data!.items.isEmpty) {
        return;
      }
      final hostId = hosts.data!.items.first.id;
      final raw = await _rawPost(
        client,
        '/core/hosts/info',
        data: <String, dynamic>{'id': hostId},
      );
      _logSection(
        '✅ Raw /core/hosts/info',
        method: 'POST',
        path: '/core/hosts/info',
        request: <String, dynamic>{'id': hostId},
        response: raw.data,
      );
      final parsed = await api.getHostById(hostId);
      _logSection(
        '✅ Parsed /core/hosts/info',
        response: parsed.data?.toJson(),
      );
      expect(parsed.data, isNotNull);
    });

    test('POST /core/hosts/tree 应该成功', () async {
      if (!canRun) return;
      final raw = await _rawPost(
        client,
        '/core/hosts/tree',
        data: const <String, dynamic>{'info': ''},
      );
      _logSection(
        '✅ Raw /core/hosts/tree',
        method: 'POST',
        path: '/core/hosts/tree',
        request: const <String, dynamic>{'info': ''},
        response: raw.data,
      );
      final parsed = await api.getHostAssetTree();
      _logSection(
        '✅ Parsed /core/hosts/tree',
        response: parsed.data
            ?.map((item) => {'id': item.id, 'label': item.label})
            .toList(),
      );
      expect(parsed.statusCode, 200);
    });

    test('POST /core/hosts/test/byid/:id 应该成功', () async {
      if (!canRun) return;
      final hosts = await api.searchHostAssets(
        const HostSearchRequest(page: 1, pageSize: 10),
      );
      if (hosts.data == null || hosts.data!.items.isEmpty) {
        return;
      }
      final hostId = hosts.data!.items.first.id;
      final raw = await _rawPost(client, '/core/hosts/test/byid/$hostId');
      _logSection(
        '✅ Raw /core/hosts/test/byid/:id',
        method: 'POST',
        path: '/core/hosts/test/byid/$hostId',
        response: raw.data,
      );
      final parsed = await api.testHostById(hostId);
      _logSection(
        '✅ Parsed /core/hosts/test/byid/:id',
        response: parsed.data,
      );
      expect(parsed.data, isA<bool>());
    });

    test('POST /core/hosts/test/byinfo 应该成功', () async {
      if (!canRun) return;
      final hosts = await api.searchHostAssets(
        const HostSearchRequest(page: 1, pageSize: 10),
      );
      if (hosts.data == null || hosts.data!.items.isEmpty) {
        return;
      }
      final detail = await api.getHostById(hosts.data!.items.first.id);
      final host = detail.data;
      if (host == null) {
        return;
      }
      final request = HostConnTest(
        addr: host.addr ?? '',
        port: host.port ?? 22,
        user: host.user ?? '',
        authMode: host.authMode ?? 'password',
        password:
            host.password?.isNotEmpty == true ? _encode(host.password!) : null,
        privateKey: host.privateKey?.isNotEmpty == true
            ? _encode(host.privateKey!)
            : null,
        passPhrase: host.passPhrase,
      );
      final raw = await _rawPost(
        client,
        '/core/hosts/test/byinfo',
        data: request.toJson(),
      );
      _logSection(
        '✅ Raw /core/hosts/test/byinfo',
        method: 'POST',
        path: '/core/hosts/test/byinfo',
        request: request.toJson(),
        response: raw.data,
      );
      final parsed = await api.testHostAssetByInfo(request);
      _logSection(
        '✅ Parsed /core/hosts/test/byinfo',
        response: parsed.data,
      );
      expect(parsed.data, isA<bool>());
    });

    test('create/update/delete 应在 destructive 模式下成功', () async {
      if (!canRun) return;
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.host', '跳过测试: $skipReason');
        return;
      }
      final hosts = await api.searchHostAssets(
        const HostSearchRequest(page: 1, pageSize: 10),
      );
      if (hosts.data == null || hosts.data!.items.isEmpty) {
        return;
      }
      final detail = await api.getHostById(hosts.data!.items.first.id);
      final base = detail.data;
      if (base == null) return;

      final uniqueName = 'codex-${DateTime.now().millisecondsSinceEpoch}';
      final create = HostOperate(
        name: uniqueName,
        groupID: base.groupID ?? 1,
        addr: base.addr ?? '',
        port: base.port ?? 22,
        user: base.user ?? '',
        authMode: base.authMode ?? 'password',
        password:
            base.password?.isNotEmpty == true ? _encode(base.password!) : null,
        privateKey: base.privateKey?.isNotEmpty == true
            ? _encode(base.privateKey!)
            : null,
        passPhrase: base.passPhrase,
        rememberPassword: base.rememberPassword ?? false,
        description: 'codex-temp',
      );

      await api.createHostAsset(create);
      final createdSearch = await api.searchHostAssets(
        HostSearchRequest(page: 1, pageSize: 20, info: uniqueName),
      );
      final created = createdSearch.data?.items
              .where((item) => item.name == uniqueName)
              .toList() ??
          const <HostInfo>[];
      expect(created, isNotEmpty);
      final createdId = created.first.id;

      await api.updateHostAsset(
        HostOperate(
          id: createdId,
          name: '$uniqueName-updated',
          groupID: create.groupID,
          addr: create.addr,
          port: create.port,
          user: create.user,
          authMode: create.authMode,
          password: create.password,
          privateKey: create.privateKey,
          passPhrase: create.passPhrase,
          rememberPassword: create.rememberPassword,
          description: create.description,
        ),
      );

      await api.deleteHost(OperateByIDs(ids: <int>[createdId]));
    });
  });
}
