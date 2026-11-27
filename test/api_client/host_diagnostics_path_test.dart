import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/host_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

void main() {
  group('运行时诊断端点路径', () {
    late HttpServer server;
    late DioClient client;
    late List<String> requestPaths;
    late List<String> requestMethods;
    late int Function(HttpRequest request) statusCodeResolver;
    late Map<String, dynamic> Function(HttpRequest request) responseBuilder;

    setUp(() async {
      requestPaths = <String>[];
      requestMethods = <String>[];
      statusCodeResolver = (_) => 200;
      responseBuilder = (_) => <String, dynamic>{
            'code': 200,
            'message': 'success',
            'data': <String, dynamic>{},
          };

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestPaths.add(request.uri.path);
        requestMethods.add(request.method);
        await utf8.decoder.bind(request).join();
        final statusCode = statusCodeResolver(request);
        request.response.statusCode = statusCode;
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

    test('摘要走 /core/hosts/diagnostics/summary 主路径', () async {
      final api = HostV2Api(client);
      await api.getDiagnosticsSummary();

      expect(requestPaths, <String>['/api/v2/core/hosts/diagnostics/summary']);
      expect(requestMethods, <String>['GET']);
    });

    test('摘要主路径 404 时回退到 /hosts/diagnostics/summary', () async {
      statusCodeResolver = (HttpRequest request) =>
          request.uri.path == '/api/v2/core/hosts/diagnostics/summary' ? 404 : 200;
      responseBuilder = (HttpRequest request) => request.uri.path ==
              '/api/v2/core/hosts/diagnostics/summary'
          ? <String, dynamic>{'code': 404, 'message': 'not found', 'data': null}
          : <String, dynamic>{
              'code': 200,
              'message': 'success',
              'data': <String, dynamic>{'goroutines': 12},
            };

      final api = HostV2Api(client);
      final response = await api.getDiagnosticsSummary();

      expect(requestPaths, <String>[
        '/api/v2/core/hosts/diagnostics/summary',
        '/api/v2/hosts/diagnostics/summary',
      ]);
      expect(response.data?['goroutines'], 12);
    });

    test('goroutine 转储走 /core/hosts/diagnostics/goroutines', () async {
      responseBuilder = (_) => <String, dynamic>{
            'code': 200,
            'message': 'success',
            'data': 'goroutine dump',
          };

      final api = HostV2Api(client);
      final response = await api.getDiagnosticsGoroutines();

      expect(
        requestPaths,
        <String>['/api/v2/core/hosts/diagnostics/goroutines'],
      );
      expect(response.data, 'goroutine dump');
    });

    test('剖析捕获走 /core/hosts/diagnostics/profiles 并回退', () async {
      statusCodeResolver = (HttpRequest request) =>
          request.uri.path == '/api/v2/core/hosts/diagnostics/profiles' ? 404 : 200;
      responseBuilder = (HttpRequest request) => request.uri.path ==
              '/api/v2/core/hosts/diagnostics/profiles'
          ? <String, dynamic>{'code': 404, 'message': 'not found', 'data': null}
          : <String, dynamic>{'code': 200, 'message': 'success', 'data': null};

      final api = HostV2Api(client);
      await api.createRuntimeProfile(type: 'heap');

      expect(requestPaths, <String>[
        '/api/v2/core/hosts/diagnostics/profiles',
        '/api/v2/hosts/diagnostics/profiles',
      ]);
      expect(requestMethods, <String>['POST', 'POST']);
    });
  });
}
