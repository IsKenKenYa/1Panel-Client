import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/container_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';

void main() {
  group('ContainerV2Api alignment', () {
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

    test('aligns /containers/compose/search route and payload', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{'id': '1', 'name': 'demo-compose'},
              ],
              'total': 1,
            },
          };

      final api = ContainerV2Api(client);
      final response = await api.searchComposeProjects(
        const ContainerComposeSearch(page: 1, pageSize: 20, search: 'demo'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/containers/compose/search');
      expect(requestBody?['page'], 1);
      expect(requestBody?['pageSize'], 20);
      expect(requestBody?['search'], 'demo');
      expect(response.data?.items.single.name, 'demo-compose');
      expect(response.data?.total, 1);
    });

    test('aligns /containers/compose/operate route and payload', () async {
      final api = ContainerV2Api(client);

      await api.operateComposeProject(
        const ContainerComposeOperate(
          name: 'demo-compose',
          operation: 'up',
          path: '/opt/compose/demo',
          force: true,
        ),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/containers/compose/operate');
      expect(requestBody, <String, dynamic>{
        'name': 'demo-compose',
        'operation': 'up',
        'path': '/opt/compose/demo',
        'force': true,
      });
    });

    test('aligns /containers/compose/env route and parses env list', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String>['A=1', 'B=2'],
          };

      final api = ContainerV2Api(client);
      final response =
          await api.loadComposeEnv(const FilePath(path: '/opt/compose/demo/.env'));

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/containers/compose/env');
      expect(requestBody, <String, dynamic>{'path': '/opt/compose/demo/.env'});
      expect(response.data, <String>['A=1', 'B=2']);
    });

    test('aligns /containers/compose/update route and payload', () async {
      final api = ContainerV2Api(client);

      await api.updateComposeProject(
        const ContainerComposeUpdateRequest(
          name: 'demo-compose',
          path: '/opt/compose/demo',
          content: 'services: {}',
          env: 'A=1',
          forcePull: true,
        ),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/containers/compose/update');
      expect(requestBody, <String, dynamic>{
        'name': 'demo-compose',
        'path': '/opt/compose/demo',
        'content': 'services: {}',
        'env': 'A=1',
        'forcePull': true,
      });
    });

    test('aligns /containers/compose/test route and payload', () async {
      final api = ContainerV2Api(client);

      await api.testComposeProject(
        const ContainerComposeCreate(
          from: 'edit',
          name: 'demo-compose',
          file: 'services: {}',
        ),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/containers/compose/test');
      expect(requestBody?['from'], 'edit');
      expect(requestBody?['name'], 'demo-compose');
      expect(requestBody?['file'], 'services: {}');
    });

    test('aligns /containers/compose/clean/log route and payload', () async {
      final api = ContainerV2Api(client);

      await api.cleanComposeProjectLog(
        const ContainerComposeLogCleanRequest(
          name: 'demo-compose',
          path: '/opt/compose/demo',
        ),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/containers/compose/clean/log');
      expect(requestBody, <String, dynamic>{
        'name': 'demo-compose',
        'path': '/opt/compose/demo',
      });
    });

    test('aligns /runtimes/php/container/{id} route and parsing', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'id': 9,
              'containerName': 'php-84',
            },
          };

      final api = ContainerV2Api(client);
      final response = await api.loadPhpContainerConfig(9);

      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/runtimes/php/container/9');
      expect(response.data?.id, 9);
      expect(response.data?.containerName, 'php-84');
    });

    test('aligns /runtimes/php/container/update route and payload', () async {
      final api = ContainerV2Api(client);

      await api.updatePhpContainerConfig(
        const PHPContainerConfig(id: 9, containerName: 'php-84'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/php/container/update');
      expect(requestBody, <String, dynamic>{
        'id': 9,
        'containerName': 'php-84',
      });
    });
  });
}
