import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/container_log_stream_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

void main() {
  group('ContainerLogStreamV2Api', () {
    late HttpServer server;
    late DioClient client;
    late String requestPath;
    late Map<String, String> queryParameters;
    late String? acceptHeader;
    late String sseBody;

    setUp(() async {
      requestPath = '';
      queryParameters = <String, String>{};
      acceptHeader = null;
      sseBody = '';

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestPath = request.uri.path;
        queryParameters = request.uri.queryParameters;
        acceptHeader = request.headers.value('accept');

        request.response.statusCode = 200;
        request.response.headers.contentType =
            ContentType('text', 'event-stream');
        request.response.write(sseBody);
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

    String sseFrame(String text) =>
        'data:${base64Encode(utf8.encode(text))}\n\n';

    test('decodes base64 SSE frames into log chunks', () async {
      sseBody = '${sseFrame('first log line\n')}'
          '${sseFrame('second log line\n')}';

      final api = ContainerLogStreamV2Api(client);
      final chunks =
          await api.streamContainerLogs(container: 'web-1').toList();

      expect(requestPath, '/api/v2/containers/search/log');
      expect(chunks, <String>['first log line\n', 'second log line\n']);
    });

    test('sends follow/tail/timestamp query and SSE accept header',
        () async {
      sseBody = sseFrame('tail line\n');

      final api = ContainerLogStreamV2Api(client);
      await api
          .streamContainerLogs(
            container: 'web-1',
            since: '10m',
            tail: '200',
            follow: true,
            timestamps: true,
          )
          .toList();

      expect(queryParameters['container'], 'web-1');
      expect(queryParameters['since'], '10m');
      expect(queryParameters['tail'], '200');
      expect(queryParameters['follow'], 'true');
      expect(queryParameters['timestamp'], 'true');
      expect(acceptHeader, contains('text/event-stream'));
    });

    test('ignores null and malformed frames', () async {
      sseBody = 'data:null\n\n'
          'data:!!!not-base64!!!\n\n'
          '${sseFrame('valid chunk\n')}';

      final api = ContainerLogStreamV2Api(client);
      final chunks =
          await api.streamContainerLogs(container: 'web-1').toList();

      expect(chunks, <String>['valid chunk\n']);
    });
  });
}
