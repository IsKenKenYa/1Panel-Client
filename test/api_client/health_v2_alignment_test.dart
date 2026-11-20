import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/health_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

void main() {
  group('HealthV2Api alignment', () {
    late HttpServer server;
    late DioClient client;
    late String requestMethod;
    late String requestPath;

    setUp(() async {
      requestMethod = '';
      requestPath = '';

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestMethod = request.method;
        requestPath = request.uri.path;

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': 'healthy',
        }));
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

    test('aligns GET /health/check route and unwraps envelope', () async {
      final api = HealthV2Api(client);
      final response = await api.checkHealth();

      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/health/check');
      expect(response.data, 'healthy');
    });
  });
}
