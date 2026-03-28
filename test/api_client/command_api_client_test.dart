import 'dart:convert';
import 'dart:typed_data';

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

FormData _buildUploadFormData(Uint8List bytes) {
  return FormData.fromMap(<String, dynamic>{
    'file': MultipartFile.fromBytes(bytes, filename: 'commands.csv'),
  });
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

    test('POST /core/commands/upload 应该返回导入预览', () async {
      if (!canRun) return;
      final csv = Uint8List.fromList(
        utf8.encode('name,command\nCodex Import Preview,echo hello\n'),
      );
      final rawFormData = _buildUploadFormData(csv);
      final raw = await client.upload<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/core/commands/upload'),
        rawFormData,
      );
      _logSection(
        '✅ Raw /core/commands/upload',
        method: 'POST',
        path: '/core/commands/upload',
        response: raw.data,
      );
      final parsed = await api.uploadCommands(_buildUploadFormData(csv));
      _logSection(
        '✅ Parsed /core/commands/upload',
        response: parsed.data?.map((item) => item.toJson()).toList(),
      );
      expect(parsed.data, isA<List<CommandInfo>>());
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
