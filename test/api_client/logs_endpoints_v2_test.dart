import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/logs_v2.dart';
import 'package:onepanel_client/api/v2/task_log_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/system_log_models.dart';
import 'package:onepanel_client/data/models/task_log_models.dart';

void main() {
  group('SystemLogSearch 序列化', () {
    test('空筛选只提交分页大小，不发送空字符串字段', () {
      const request = SystemLogSearch(pageSize: 50);
      expect(request.toJson(), <String, dynamic>{'pageSize': 50});
    });

    test('完整筛选按上游字段名提交', () {
      const request = SystemLogSearch(
        pageSize: 100,
        cursor: 'c1',
        startTime: '2026-11-01 00:00:00',
        endTime: '2026-11-02 00:00:00',
        keyword: 'panel',
        priority: 'err',
        service: '1panel-core',
      );
      expect(request.toJson(), <String, dynamic>{
        'pageSize': 100,
        'cursor': 'c1',
        'startTime': '2026-11-01 00:00:00',
        'endTime': '2026-11-02 00:00:00',
        'keyword': 'panel',
        'priority': 'err',
        'service': '1panel-core',
      });
    });
  });

  group('SystemLogStatus 能力判定', () {
    test('journalctl 来源支持关键字筛选', () {
      final status = SystemLogStatus.fromJson(<String, dynamic>{
        'source': 'journalctl',
        'version': '252',
      });
      expect(status.source, SystemLogSourceKind.journalctl);
      expect(status.canFilterByKeyword, isTrue);
    });

    test('file 来源不支持关键字筛选，并保留服务端说明', () {
      final status = SystemLogStatus.fromJson(<String, dynamic>{
        'source': 'file',
        'message': 'file source does not support keyword filter',
      });
      expect(status.source, SystemLogSourceKind.file);
      expect(status.canFilterByKeyword, isFalse);
      expect(status.message, 'file source does not support keyword filter');
    });
  });

  group('TaskLogReadRequest 序列化', () {
    test('页码与大小必填，其余可选字段为空时省略', () {
      const request = TaskLogReadRequest(page: 1, pageSize: 100);
      expect(request.toJson(), <String, dynamic>{
        'page': 1,
        'pageSize': 100,
        'latest': false,
      });
    });

    test('带任务标识时按上游字段名提交', () {
      const request = TaskLogReadRequest(
        page: 2,
        pageSize: 50,
        latest: true,
        taskId: 'task-1',
        taskType: 'backup',
        taskOperate: 'backup',
        resourceId: 12,
      );
      expect(request.toJson(), <String, dynamic>{
        'page': 2,
        'pageSize': 50,
        'latest': true,
        'taskID': 'task-1',
        'taskType': 'backup',
        'taskOperate': 'backup',
        'resourceID': 12,
      });
    });
  });

  group('日志端点对齐', () {
    late HttpServer server;
    late DioClient client;
    late List<String> requestPaths;
    late List<String> requestMethods;
    late List<Map<String, dynamic>?> requestBodies;
    late Map<String, dynamic> Function(HttpRequest request) responseBuilder;

    setUp(() async {
      requestPaths = <String>[];
      requestMethods = <String>[];
      requestBodies = <Map<String, dynamic>?>[];
      responseBuilder = (_) => <String, dynamic>{
            'code': 200,
            'message': 'success',
            'data': null,
          };

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestPaths.add(request.uri.path);
        requestMethods.add(request.method);
        final payload = await utf8.decoder.bind(request).join();
        requestBodies.add(
          payload.isEmpty
              ? null
              : jsonDecode(payload) as Map<String, dynamic>,
        );
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBuilder(request)));
        await request.response.close();
      });

      client = DioClient(
        baseUrl: 'http://${server.address.host}:${server.port}',
        apiKey: 'test-key',
      );
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('GET /logs/system/status 解析来源与能力', () async {
      responseBuilder = (_) => <String, dynamic>{
            'code': 200,
            'message': 'success',
            'data': <String, dynamic>{
              'source': 'journalctl',
              'version': '255',
              'keywordFilterSupported': true,
            },
          };

      final api = LogsV2Api(client);
      final response = await api.getSystemLogStatus();

      expect(requestPaths, <String>['/api/v2/logs/system/status']);
      expect(requestMethods, <String>['GET']);
      expect(response.data?.source, SystemLogSourceKind.journalctl);
      expect(response.data?.version, '255');
    });

    test('GET /logs/system/services 解析服务名数组', () async {
      responseBuilder = (_) => <String, dynamic>{
            'code': 200,
            'message': 'success',
            'data': <String>['1panel-core', 'docker'],
          };

      final api = LogsV2Api(client);
      final response = await api.getRunningServices();

      expect(requestPaths, <String>['/api/v2/logs/system/services']);
      expect(response.data, <String>['1panel-core', 'docker']);
    });

    test('POST /logs/system/read 提交游标并解析条目与下一页游标', () async {
      responseBuilder = (_) => <String, dynamic>{
            'code': 200,
            'message': 'success',
            'data': <String, dynamic>{
              'source': 'journalctl',
              'hasMore': true,
              'nextCursor': 'c2',
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'time': '2026-11-26 10:00:00',
                  'priority': 'err',
                  'service': '1panel-core',
                  'message': 'failed to open port',
                  'raw': 'raw line',
                },
              ],
            },
          };

      final api = LogsV2Api(client);
      final response = await api.readSystemLogs(
        const SystemLogSearch(pageSize: 50, cursor: 'c1', priority: 'err'),
      );

      expect(requestPaths, <String>['/api/v2/logs/system/read']);
      expect(requestMethods, <String>['POST']);
      expect(requestBodies.single, <String, dynamic>{
        'pageSize': 50,
        'cursor': 'c1',
        'priority': 'err',
      });
      expect(response.data?.hasMore, isTrue);
      expect(response.data?.nextCursor, 'c2');
      expect(response.data?.items.single.message, 'failed to open port');
    });

    test('POST /logs/tasks/read 走任务日志端点并解析行内容', () async {
      responseBuilder = (_) => <String, dynamic>{
            'code': 200,
            'message': 'success',
            'data': <String, dynamic>{
              'lines': <String>['line one', 'line two'],
              'path': '/var/log/tasks/task-1.log',
              'totalLines': 2,
              'taskStatus': 'Success',
            },
          };

      final api = TaskLogV2Api(client);
      final response = await api.readTaskLog(
        const TaskLogReadRequest(page: 1, pageSize: 100, taskId: 'task-1'),
      );

      expect(requestPaths, <String>['/api/v2/logs/tasks/read']);
      expect(requestBodies.single?['taskID'], 'task-1');
      expect(response.data?.lines, <String>['line one', 'line two']);
      expect(response.data?.path, '/var/log/tasks/task-1.log');
      expect(response.data?.taskStatus, 'Success');
    });
  });
}
