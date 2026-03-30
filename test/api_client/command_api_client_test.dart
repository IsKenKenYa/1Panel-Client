import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/api/v2/command_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/command_models.dart';
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
      'test.api_client.command', '========================================');
  appLogger.dWithPackage('test.api_client.command', title);
  if (method != null && path != null) {
    appLogger.dWithPackage('test.api_client.command', 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(
      'test.api_client.command',
      'RequestBody: ${_prettyJson(request)}',
    );
  }
  if (response != null) {
    appLogger.dWithPackage(
      'test.api_client.command',
      'Response: ${_prettyJson(response)}',
    );
  }
  appLogger.dWithPackage(
      'test.api_client.command', '========================================');
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
  late CommandV2Api api;
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
      api = CommandV2Api(client);
    }
  });

  group('Command API客户端测试', () {
    test('POST /core/commands/search 应该成功', () async {
      if (!canRun) return;
      final request =
          const CommandSearchRequest(page: 1, pageSize: 10).toJson();
      final raw =
          await _rawPost(client, '/core/commands/search', data: request);
      _logSection(
        '✅ Raw /core/commands/search',
        method: 'POST',
        path: '/core/commands/search',
        request: request,
        response: raw.data,
      );
      final parsed = await api.searchCommands(
        const CommandSearchRequest(page: 1, pageSize: 10),
      );
      _logSection(
        '✅ Parsed /core/commands/search',
        response: {
          'total': parsed.data?.total,
          'items': parsed.data?.items.map((item) => item.toJson()).toList(),
        },
      );
      expect(parsed.data, isNotNull);
    });

    test('POST /core/commands/tree 应该成功', () async {
      if (!canRun) return;
      final raw = await _rawPost(
        client,
        '/core/commands/tree',
        data: <String, dynamic>{'type': 'command'},
      );
      _logSection(
        '✅ Raw /core/commands/tree',
        method: 'POST',
        path: '/core/commands/tree',
        request: const <String, dynamic>{'type': 'command'},
        response: raw.data,
      );
      final parsed = await api.getCommandTree();
      _logSection(
        '✅ Parsed /core/commands/tree',
        response: parsed.data?.map((item) => item.toJson()).toList(),
      );
      expect(parsed.statusCode, 200);
    });

    test('POST /core/commands/list 应该返回命令列表', () async {
      if (!canRun) return;
      final request = <String, dynamic>{'type': 'command'};
      final raw = await _rawPost(client, '/core/commands/list', data: request);
      _logSection(
        '✅ Raw /core/commands/list',
        method: 'POST',
        path: '/core/commands/list',
        request: request,
        response: raw.data,
      );

      final parsed = await api.listCommands();
      _logSection(
        '✅ Parsed /core/commands/list',
        response: parsed.data?.map((item) => item.toJson()).toList(),
      );

      expect(parsed.statusCode, 200);
      expect(parsed.data, isNotNull);
    });

    test('POST /core/commands create/update/del 主链路应可回归', () async {
      if (!canRun) return;
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.command', '跳过测试: $skipReason');
        return;
      }

      final uniqueName =
          'codex-create-${DateTime.now().millisecondsSinceEpoch}';
      final created = CommandOperate(
        name: uniqueName,
        command: 'echo created',
        type: 'command',
        groupID: 0,
      );

      await api.createCommand(created);
      _logSection(
        '✅ Parsed /core/commands create',
        method: 'POST',
        path: '/core/commands',
        request: created.toJson(),
      );

      final createdSearch = await api.searchCommands(
        CommandSearchRequest(page: 1, pageSize: 20, info: uniqueName),
      );
      final createdItems = createdSearch.data?.items
              .where((item) => item.name == uniqueName)
              .toList() ??
          const <CommandInfo>[];
      expect(createdItems, isNotEmpty);

      final target = createdItems.first;
      final updatedName = '$uniqueName-updated';
      final updated = CommandOperate(
        id: target.id,
        name: updatedName,
        command: 'echo updated',
        type: 'command',
        groupID: target.groupID ?? 0,
      );

      await api.updateCommand(updated);
      _logSection(
        '✅ Parsed /core/commands/update',
        method: 'POST',
        path: '/core/commands/update',
        request: updated.toJson(),
      );

      final updatedSearch = await api.searchCommands(
        CommandSearchRequest(page: 1, pageSize: 20, info: updatedName),
      );
      final updatedItems = updatedSearch.data?.items
              .where((item) => item.name == updatedName)
              .toList() ??
          const <CommandInfo>[];
      _logSection(
        '✅ Parsed create/update verify',
        response: updatedItems.map((item) => item.toJson()).toList(),
      );
      expect(updatedItems, isNotEmpty);

      final ids = updatedItems
          .map((item) => item.id)
          .whereType<int>()
          .toList(growable: false);
      if (ids.isNotEmpty) {
        await api.deleteCommand(OperateByIDs(ids: ids));
        _logSection(
          '✅ Parsed /core/commands/del',
          method: 'POST',
          path: '/core/commands/del',
          request: <String, dynamic>{'ids': ids},
        );
      }
    });

    test('POST /core/commands/export 应该返回导出路径', () async {
      if (!canRun) return;
      final raw = await _rawPost(client, '/core/commands/export');
      _logSection(
        '✅ Raw /core/commands/export',
        method: 'POST',
        path: '/core/commands/export',
        response: raw.data,
      );
      final parsed = await api.exportCommand();
      _logSection(
        '✅ Parsed /core/commands/export',
        response: parsed.data,
      );
      expect(parsed.data, isNotNull);
    });

    test('POST /core/commands/import 应该支持真实环境导入', () async {
      if (!canRun) return;
      final skipReason = TestEnvironment.skipDestructive();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.command', '跳过测试: $skipReason');
        return;
      }
      final uniqueName = 'codex-${DateTime.now().millisecondsSinceEpoch}';
      final items = <CommandOperate>[
        CommandOperate(
          name: uniqueName,
          command: 'echo codex',
          type: 'command',
          groupID: 0,
        ),
      ];

      await api.importCommand(items);
      final search = await api.searchCommands(
        CommandSearchRequest(page: 1, pageSize: 20, info: uniqueName),
      );
      final created = search.data?.items
              .where((item) => item.name == uniqueName)
              .toList() ??
          const <CommandInfo>[];
      _logSection(
        '✅ Parsed /core/commands/import search verify',
        response: created.map((item) => item.toJson()).toList(),
      );
      expect(created, isNotEmpty);
      final ids = created
          .map((item) => item.id)
          .whereType<int>()
          .toList(growable: false);
      if (ids.isNotEmpty) {
        await api.deleteCommand(OperateByIDs(ids: ids));
      }
    });
  });
}
