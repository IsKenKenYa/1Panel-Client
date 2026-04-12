import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/logs_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/container_models.dart';

void main() {
  group('LogsV2Api alignment', () {
    late HttpServer server;
    late DioClient client;
    late Map<String, dynamic>? requestBody;
    late String requestMethod;
    late String requestPath;
    late Map<String, String> requestQuery;
    late Map<String, dynamic> Function() responseBuilder;
    String? rawResponseBody;

    setUp(() async {
      requestBody = null;
      requestMethod = '';
      requestPath = '';
      requestQuery = <String, String>{};
      responseBuilder = () => <String, dynamic>{'code': 200, 'data': null};
      rawResponseBody = null;

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestMethod = request.method;
        requestPath = request.uri.path;
        requestQuery = request.uri.queryParameters;

        final payload = await utf8.decoder.bind(request).join();
        requestBody = payload.isEmpty
            ? null
            : jsonDecode(payload) as Map<String, dynamic>;

        request.response.statusCode = 200;
        if (rawResponseBody != null) {
          request.response.headers.contentType = ContentType.text;
          request.response.write(rawResponseBody);
        } else {
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode(responseBuilder()));
        }
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

    test('aligns /containers/search/log route and query', () async {
      rawResponseBody = 'line-1\nline-2';
      final api = LogsV2Api(client);

      final response = await api.searchContainerLogs(
        container: 'container-1',
        since: '1h',
        follow: true,
        tail: '200',
      );

      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/containers/search/log');
      expect(requestQuery, <String, String>{
        'container': 'container-1',
        'since': '1h',
        'follow': 'true',
        'tail': '200',
      });
      expect(response.data.toString(), contains('line-1'));
    });

    test('aligns /containers/clean/log route and payload', () async {
      final api = LogsV2Api(client);

      await api.cleanContainerLogs(
        const OperationWithName(name: 'container-1'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/containers/clean/log');
      expect(requestBody, <String, dynamic>{'name': 'container-1'});
    });

    test('aligns /containers/compose/clean/log route and payload', () async {
      final api = LogsV2Api(client);

      await api.cleanComposeLogs(
        const ContainerComposeLogCleanRequest(
          name: 'demo',
          path: '/opt/compose/demo',
        ),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/containers/compose/clean/log');
      expect(requestBody, <String, dynamic>{
        'name': 'demo',
        'path': '/opt/compose/demo',
      });
    });

    test('aligns /containers/logoption/update route and payload', () async {
      final api = LogsV2Api(client);

      await api.updateContainerLogOptions(
        const LogOption(logMaxFile: '3', logMaxSize: '10m'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/containers/logoption/update');
      expect(requestBody, <String, dynamic>{
        'logMaxFile': '3',
        'logMaxSize': '10m',
      });
    });

    test('aligns /cronjobs/records/log route and parses payload', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': 'record-log-line',
          };
      final api = LogsV2Api(client);

      final response = await api.getCronjobRecordLog(const OperateByID(id: 9));

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/cronjobs/records/log');
      expect(requestBody, <String, dynamic>{'id': 9});
      expect(response.data, contains('record-log-line'));
    });
  });
}
