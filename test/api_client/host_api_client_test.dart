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

void _expectSuccessEnvelope(Response<Map<String, dynamic>> response) {
  expect(response.statusCode, equals(200));
  expect(response.data, isNotNull);
  expect(response.data, containsPair('code', 200));
  expect(response.data, contains('data'));
}

Future<HostInfo?> _firstHost(HostV2Api api) async {
  final hosts = await api.searchHostAssets(
    const HostSearchRequest(page: 1, pageSize: 10),
  );
  final items = hosts.data?.items ?? const <HostInfo>[];
  if (items.isEmpty) {
    return null;
  }
  return items.first;
}

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
      const hostSearch = HostSearchRequest(page: 1, pageSize: 10);
      final request = hostSearch.toJson();
      final raw = await _rawPost(client, '/core/hosts/search', data: request);
      _logSection(
        '✅ Raw /core/hosts/search',
        method: 'POST',
        path: '/core/hosts/search',
        request: request,
        response: raw.data,
      );
      _expectSuccessEnvelope(raw);
      final rawData = Map<String, dynamic>.from(raw.data!['data'] as Map);
      final rawItems = (rawData['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);

      final parsed = await api.searchHostAssets(hostSearch);
      _logSection(
        '✅ Parsed /core/hosts/search',
        response: {
          'total': parsed.data?.total,
          'items': parsed.data?.items.map((item) => item.toJson()).toList(),
        },
      );
      expect(parsed.data, isNotNull);
      expect(parsed.data!.total, equals(rawData['total']));
      expect(parsed.data!.items, hasLength(rawItems.length));
      for (var i = 0; i < rawItems.length; i++) {
        final rawItem = rawItems[i];
        final item = parsed.data!.items[i];
        expect(item.id, equals(rawItem['id']));
        expect(item.name, equals(rawItem['name']));
        expect(item.addr, equals(rawItem['addr'] ?? rawItem['address']));
        expect(item.port, equals(rawItem['port']));
        expect(item.user, equals(rawItem['user'] ?? rawItem['username']));
        expect(item.groupID, equals(rawItem['groupID']));
        expect(item.status, equals(rawItem['status'] ?? 'unknown'));
      }
    });

    test('POST /core/hosts/search 应兼容 HostSearch parser 分支', () async {
      if (!canRun) return;
      const request = HostSearch(page: 1, pageSize: 10);
      final raw = await _rawPost(
        client,
        '/core/hosts/search',
        data: request.toJson(),
      );
      _logSection(
        '✅ Raw /core/hosts/search (HostSearch)',
        method: 'POST',
        path: '/core/hosts/search',
        request: request.toJson(),
        response: raw.data,
      );
      _expectSuccessEnvelope(raw);
      final rawData = Map<String, dynamic>.from(raw.data!['data'] as Map);
      final rawItems = (rawData['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);

      final parsed = await api.searchHosts(request);
      _logSection(
        '✅ Parsed /core/hosts/search (HostSearch)',
        response: {
          'total': parsed.data?.total,
          'items': parsed.data?.items.map((item) => item.toJson()).toList(),
        },
      );
      expect(parsed.data, isNotNull);
      expect(parsed.data!.total, equals(rawData['total']));
      expect(parsed.data!.items, hasLength(rawItems.length));
      for (var i = 0; i < rawItems.length; i++) {
        final rawItem = rawItems[i];
        final item = parsed.data!.items[i];
        expect(item.id, equals(rawItem['id']));
        expect(item.name, equals(rawItem['name']));
        expect(item.addr, equals(rawItem['addr'] ?? rawItem['address']));
        expect(item.user, equals(rawItem['user'] ?? rawItem['username']));
      }
    });

    test('POST /core/hosts/info 应该成功', () async {
      if (!canRun) return;
      final host = await _firstHost(api);
      if (host == null) {
        return;
      }
      final hostId = host.id;
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
      _expectSuccessEnvelope(raw);
      final rawItem = Map<String, dynamic>.from(raw.data!['data'] as Map);
      final parsed = await api.getHostById(hostId);
      _logSection(
        '✅ Parsed /core/hosts/info',
        response: parsed.data?.toJson(),
      );
      expect(parsed.data, isNotNull);
      expect(parsed.data!.id, equals(rawItem['id']));
      expect(parsed.data!.name, equals(rawItem['name']));
      expect(parsed.data!.addr, equals(rawItem['addr'] ?? rawItem['address']));
      expect(parsed.data!.port, equals(rawItem['port']));
      expect(parsed.data!.user, equals(rawItem['user'] ?? rawItem['username']));
      expect(parsed.data!.groupID, equals(rawItem['groupID']));
      expect(parsed.data!.groupBelong, equals(rawItem['groupBelong']));
      expect(parsed.data!.status, equals(rawItem['status'] ?? 'unknown'));
      expect(parsed.data!.authMode, equals(rawItem['authMode']));
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
      _expectSuccessEnvelope(raw);
      final rawItems = (raw.data!['data'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      final parsed = await api.getHostAssetTree();
      _logSection(
        '✅ Parsed /core/hosts/tree',
        response: parsed.data
            ?.map((item) => {'id': item.id, 'label': item.label})
            .toList(),
      );
      expect(parsed.statusCode, 200);
      expect(parsed.data, hasLength(rawItems.length));
      for (var i = 0; i < rawItems.length; i++) {
        final rawItem = rawItems[i];
        final item = parsed.data![i];
        expect(item.id, equals(rawItem['id']));
        expect(item.label, equals(rawItem['label']));
      }
    });

    test('POST /core/hosts/tree 应兼容原始 Map tree 分支', () async {
      if (!canRun) return;
      const request = SearchWithPage(info: '', page: 1, pageSize: 10);
      final raw = await _rawPost(
        client,
        '/core/hosts/tree',
        data: request.toJson(),
      );
      _logSection(
        '✅ Raw /core/hosts/tree (SearchWithPage)',
        method: 'POST',
        path: '/core/hosts/tree',
        request: request.toJson(),
        response: raw.data,
      );
      _expectSuccessEnvelope(raw);
      final rawItems = (raw.data!['data'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);

      final parsed = await api.getHostTree(request);
      _logSection(
        '✅ Parsed /core/hosts/tree (SearchWithPage)',
        response: parsed.data,
      );
      expect(parsed.statusCode, equals(200));
      expect(parsed.data, hasLength(rawItems.length));
      for (var i = 0; i < rawItems.length; i++) {
        final rawItem = rawItems[i];
        final item = parsed.data![i];
        expect(item['id'], equals(rawItem['id']));
        expect(item['label'], equals(rawItem['label']));
      }
    });

    test('POST /core/hosts/test/byid/:id 应该成功', () async {
      if (!canRun) return;
      final host = await _firstHost(api);
      if (host == null) {
        return;
      }
      final hostId = host.id;
      final raw = await _rawPost(client, '/core/hosts/test/byid/$hostId');
      _logSection(
        '✅ Raw /core/hosts/test/byid/:id',
        method: 'POST',
        path: '/core/hosts/test/byid/$hostId',
        response: raw.data,
      );
      _expectSuccessEnvelope(raw);
      final parsed = await api.testHostById(hostId);
      _logSection(
        '✅ Parsed /core/hosts/test/byid/:id',
        response: parsed.data,
      );
      expect(parsed.data, isA<bool>());
      expect(parsed.data, equals(raw.data!['data']));
    });

    test('POST /core/hosts/test/byinfo 应该成功', () async {
      if (!canRun) return;
      final firstHost = await _firstHost(api);
      if (firstHost == null) return;
      final detail = await api.getHostById(firstHost.id);
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
      _expectSuccessEnvelope(raw);
      final parsed = await api.testHostAssetByInfo(request);
      _logSection(
        '✅ Parsed /core/hosts/test/byinfo',
        response: parsed.data,
      );
      expect(parsed.data, isA<bool>());
      expect(parsed.data, equals(raw.data!['data']));
    });

    test('updateHostGroup 应在 destructive 模式下做同值回放', () async {
      if (!canRun) return;
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.host', '跳过测试: $skipReason');
        return;
      }
      final host = await _firstHost(api);
      final groupId = host?.groupID;
      if (host == null || groupId == null) {
        return;
      }

      final response = await api.updateHostGroup(id: host.id, groupId: groupId);
      _logSection(
        '✅ Parsed /core/hosts/update/group (same-value replay)',
        request: <String, dynamic>{'id': host.id, 'groupID': groupId},
        response: <String, dynamic>{
          'statusCode': response.statusCode,
          'statusMessage': response.statusMessage,
        },
      );
      expect(response.statusCode, equals(200));
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
