import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/alert_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/alert_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';

void main() {
  group('AlertV2Api alignment', () {
    late HttpServer server;
    late DioClient client;
    late Map<String, dynamic>? requestBody;
    late String requestMethod;
    late String requestPath;
    late Map<String, dynamic> Function() responseBuilder;

    setUp(() async {
      requestBody = null;
      requestMethod = '';
      requestPath = '';
      responseBuilder = () => <String, dynamic>{'code': 200, 'data': null};

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestMethod = request.method;
        requestPath = request.uri.path;

        final payload = await utf8.decoder.bind(request).join();
        requestBody = payload.isEmpty
            ? null
            : jsonDecode(payload) as Map<String, dynamic>;

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBuilder()));
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

    test('aligns /alert/search route and page parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 1,
                  'type': 'disk',
                  'method': 'email',
                  'title': '磁盘告警',
                  'status': 'Enable',
                  'sendMethod': <String>['email'],
                },
              ],
              'total': 1,
            },
          };

      final api = AlertV2Api(client);
      final response = await api.searchAlerts(
        const AlertSearch(page: 1, pageSize: 20, orderBy: 'created_at'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/alert/search');
      expect(requestBody?['orderBy'], 'created_at');
      expect(response.data?.items.single.type, 'disk');
      expect(response.data?.total, 1);
    });

    test('aligns POST /alert route and payload', () async {
      final api = AlertV2Api(client);
      await api.createAlert(
        const AlertCreate(type: 'disk', method: 'email', title: '磁盘告警'),
      );

      expect(requestPath, '/api/v2/alert');
      expect(requestBody?['type'], 'disk');
      expect(requestBody?['method'], 'email');
    });

    test('aligns /alert/status route and payload', () async {
      final api = AlertV2Api(client);
      await api.updateAlertStatus(
        const AlertUpdateStatus(id: 5, status: 'Disable'),
      );

      expect(requestPath, '/api/v2/alert/status');
      expect(requestBody?['id'], 5);
      expect(requestBody?['status'], 'Disable');
    });

    test('aligns /alert/del route and payload', () async {
      final api = AlertV2Api(client);
      await api.deleteAlert(const OperateByID(id: 3));

      expect(requestPath, '/api/v2/alert/del');
      expect(requestBody?['id'], 3);
    });

    test('aligns /alert/disks/list route and parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'path': '/',
                'device': 'vda1',
                'usedPercent': 82.5,
              },
            ],
          };

      final api = AlertV2Api(client);
      final response = await api.listAlertDisks();

      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/alert/disks/list');
      expect(response.data?.single.usedPercent, 82.5);
    });

    test('aligns /alert/logs/search route and nested parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 9,
                  'alertId': 1,
                  'message': 'disk usage high',
                  'alertDetail': <String, dynamic>{
                    'type': 'disk',
                    'title': '磁盘告警',
                  },
                  'alertRule': <String, dynamic>{
                    'id': 1,
                    'type': 'disk',
                  },
                },
              ],
              'total': 1,
            },
          };

      final api = AlertV2Api(client);
      final response = await api.searchAlertLogs(
        const AlertLogSearch(page: 1, pageSize: 20),
      );

      expect(requestPath, '/api/v2/alert/logs/search');
      expect(response.data?.items.single.message, 'disk usage high');
      expect(response.data?.items.single.alertDetail.type, 'disk');
      expect(response.data?.items.single.alertRule.type, 'disk');
    });

    test('aligns /alert/config/info route and parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 2,
                'type': 'email',
                'title': '邮件通知',
                'config': '{"host":"smtp.example.com"}',
                'status': 'Enable',
              },
            ],
          };

      final api = AlertV2Api(client);
      final response = await api.listAlertConfigs(
        const AlertConfigFilterReq(excludeTypes: <String>['sms']),
      );

      expect(requestPath, '/api/v2/alert/config/info');
      expect(requestBody?['excludeTypes'], <String>['sms']);
      expect(response.data?.single.config, '{"host":"smtp.example.com"}');
    });

    test('aligns /alert/config/test route and parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'success': true,
              'statusCode': 200,
              'duration': 320,
            },
          };

      final api = AlertV2Api(client);
      final response = await api.testAlertConfig(
        const AlertConfigTest(
          type: 'email',
          host: 'smtp.example.com',
          port: 465,
          encryption: 'ssl',
          sender: 'from@example.com',
          recipient: 'to@example.com',
        ),
      );

      expect(requestPath, '/api/v2/alert/config/test');
      expect(requestBody?['encryption'], 'ssl');
      expect(response.data?.success, isTrue);
      expect(response.data?.duration, 320);
    });
  });
}
