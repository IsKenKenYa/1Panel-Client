import 'dart:convert';
import 'dart:io' hide HttpException;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';

void main() {
  group('DioClient', () {
    group('constructor', () {
      test('creates with default baseUrl', () {
        final client = DioClient();
        expect(client.dio.options.baseUrl, ApiConstants.defaultBaseUrl);
      });

      test('creates with custom baseUrl', () {
        final client = DioClient(baseUrl: 'https://custom.host:8080');
        expect(client.dio.options.baseUrl, 'https://custom.host:8080');
      });

      test('sets connect timeout', () {
        final client = DioClient();
        expect(client.dio.options.connectTimeout,
            Duration(seconds: ApiConstants.connectTimeout));
      });

      test('sets receive timeout', () {
        final client = DioClient();
        expect(client.dio.options.receiveTimeout,
            Duration(seconds: ApiConstants.receiveTimeout));
      });

      test('sets send timeout', () {
        final client = DioClient();
        expect(client.dio.options.sendTimeout,
            Duration(seconds: ApiConstants.sendTimeout));
      });

      test('sets response type to json', () {
        final client = DioClient();
        expect(client.dio.options.responseType, ResponseType.json);
      });

      test('sets default headers', () {
        final client = DioClient();
        expect(client.dio.options.headers['Content-Type'], 'application/json');
        expect(client.dio.options.headers['Accept'], 'application/json');
        expect(client.dio.options.headers['User-Agent'], ApiConstants.userAgent);
      });

      test('adds 4 business interceptors plus dio built-in (total 5)', () {
        final client = DioClient();
        // dio >= 5.9 内置 ImplyContentTypeInterceptor，
        // 加上 DioClient 显式添加的 Auth/BusinessResponse/Logging/Retry 共 5 个。
        expect(client.dio.interceptors.length, 5);
        expect(
          client.dio.interceptors.any((i) => i.runtimeType.toString() == 'AuthInterceptor'),
          isTrue,
        );
        expect(
          client.dio.interceptors.any((i) => i.runtimeType.toString() == 'BusinessResponseInterceptor'),
          isTrue,
        );
        expect(
          client.dio.interceptors.any((i) => i.runtimeType.toString() == 'LoggingInterceptor'),
          isTrue,
        );
        expect(
          client.dio.interceptors.any((i) => i.runtimeType.toString() == 'RetryInterceptor'),
          isTrue,
        );
      });

      test('exposes dio instance', () {
        final client = DioClient();
        expect(client.dio, isA<Dio>());
      });
    });

    group('updateAuth', () {
      test('does not throw', () {
        final client = DioClient();
        expect(() => client.updateAuth('new-key'), returnsNormally);
      });

      test('can be called with null', () {
        final client = DioClient();
        expect(() => client.updateAuth(null), returnsNormally);
      });

      test('can be called with empty string', () {
        final client = DioClient();
        expect(() => client.updateAuth(''), returnsNormally);
      });
    });

    group('validateStatus', () {
      test('accepts 200', () {
        final client = DioClient();
        expect(client.dio.options.validateStatus!(200), isTrue);
      });

      test('accepts 201', () {
        final client = DioClient();
        expect(client.dio.options.validateStatus!(201), isTrue);
      });

      test('accepts 299', () {
        final client = DioClient();
        expect(client.dio.options.validateStatus!(299), isTrue);
      });

      test('rejects 300', () {
        final client = DioClient();
        expect(client.dio.options.validateStatus!(300), isFalse);
      });

      test('rejects 400', () {
        final client = DioClient();
        expect(client.dio.options.validateStatus!(400), isFalse);
      });

      test('rejects 500', () {
        final client = DioClient();
        expect(client.dio.options.validateStatus!(500), isFalse);
      });

      test('rejects null', () {
        final client = DioClient();
        expect(client.dio.options.validateStatus!(null), isFalse);
      });
    });

    group('HTTP methods exist', () {
      test('get method is callable', () {
        final client = DioClient();
        expect(client.get, isA<Function>());
      });

      test('post method is callable', () {
        final client = DioClient();
        expect(client.post, isA<Function>());
      });

      test('put method is callable', () {
        final client = DioClient();
        expect(client.put, isA<Function>());
      });

      test('delete method is callable', () {
        final client = DioClient();
        expect(client.delete, isA<Function>());
      });

      test('patch method is callable', () {
        final client = DioClient();
        expect(client.patch, isA<Function>());
      });

      test('upload method is callable', () {
        final client = DioClient();
        expect(client.upload, isA<Function>());
      });

      test('download method is callable', () {
        final client = DioClient();
        expect(client.download, isA<Function>());
      });
    });

    group('exception conversion', () {
      test('主动取消保持 Dio 取消类型', () async {
        final client = DioClient(baseUrl: 'http://localhost:1');
        addTearDown(() => client.dio.close(force: true));
        final cancel = CancelToken()..cancel();
        await expectLater(
          client.get<dynamic>('/unused', cancelToken: cancel),
          throwsA(isA<DioException>().having(
            (error) => CancelToken.isCancel(error),
            'cancelled',
            isTrue,
          )),
        );
      });
      test('get throws NetworkConnectionException on connection error', () async {
        final client = DioClient(baseUrl: 'http://localhost:1');
        expect(
          () => client.get('/test'),
          throwsA(isA<NetworkConnectionException>()),
        );
      }, timeout: Timeout(Duration(seconds: 10)));

      test('post throws NetworkConnectionException on connection error', () async {
        final client = DioClient(baseUrl: 'http://localhost:1');
        expect(
          () => client.post('/test'),
          throwsA(isA<NetworkConnectionException>()),
        );
      }, timeout: Timeout(Duration(seconds: 10)));

      test('业务失败保留 HTTP 状态，敏感请求仅显示业务码', () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        final client = DioClient(baseUrl: 'http://127.0.0.1:${server.port}');
        addTearDown(() => client.dio.close(force: true));
        server.listen((request) async {
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({
            'code': 401,
            'message': 'session required',
            'data': {'detail': 'private detail'},
          }));
          await request.response.close();
        });
        final failure =
            isA<HttpException>().having((e) => e.statusCode, 'status', 200);
        await expectLater(
          client.get<dynamic>('/api/v2/panel'),
          throwsA(failure.having((e) => e.message, 'message', 'session required')),
        );
        await expectLater(
          client.get<dynamic>('/api/v2/panel', options: DioClient.sensitiveOptions),
          throwsA(failure.having((e) => e.message, 'message', '面板拒绝请求 (401)')),
        );
      });
    });

    group('SPA fallback page detection (EndpointNotFoundException)', () {
      const htmlPage = '<!DOCTYPE html><html><head></head><body>index</body></html>';
      HttpServer? server;
      String? baseUrl;

      setUp(() async {
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        baseUrl = 'http://127.0.0.1:${server!.port}';
        server!.listen((request) async {
          final path = request.uri.path;
          if (path == '/api/v2/core/missing') {
            // 1Panel SPA fallback: 200 + HTML page
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.html;
            request.response.write(htmlPage);
          } else if (path == '/api/v2/core/textonly') {
            // 200 + text/html 但 body 非 HTML（content-type 识别路径）
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.html;
            request.response.write('fallback');
          } else if (path == '/api/v2/core/ok') {
            // 正常 JSON 信封响应，不应被误伤
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode(<String, dynamic>{'code': 200, 'message': 'ok', 'data': 1}),
            );
          } else if (path == '/downloads/file') {
            // 非 /api/ 前缀的 HTML 下载/预览，不应抛端点不存在
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.html;
            request.response.write(htmlPage);
          } else {
            request.response.statusCode = 404;
          }
          await request.response.close();
        });
      });

      tearDown(() async {
        await server?.close(force: true);
        server = null;
      });

      test('get throws EndpointNotFoundException on 200 + HTML for /api/ path',
          () async {
        final client = DioClient(baseUrl: baseUrl);
        await expectLater(
          client.get<dynamic>('/api/v2/core/missing'),
          throwsA(
            isA<EndpointNotFoundException>().having(
              (e) => e.message,
              'message',
              '当前面板版本不支持该功能',
            ),
          ),
        );
      });

      test('post throws EndpointNotFoundException on 200 + HTML for /api/ path',
          () async {
        final client = DioClient(baseUrl: baseUrl);
        await expectLater(
          client.post<dynamic>('/api/v2/core/missing'),
          throwsA(isA<EndpointNotFoundException>()),
        );
      });

      test(
          'typed Map<String, dynamic> request converts Dio TypeError to '
          'EndpointNotFoundException', () async {
        final client = DioClient(baseUrl: baseUrl);
        await expectLater(
          client.get<Map<String, dynamic>>('/api/v2/core/missing'),
          throwsA(isA<EndpointNotFoundException>()),
        );
      });

      test('text/html content-type alone triggers detection for /api/ path',
          () async {
        final client = DioClient(baseUrl: baseUrl);
        await expectLater(
          client.get<dynamic>('/api/v2/core/textonly'),
          throwsA(isA<EndpointNotFoundException>()),
        );
      });

      test('normal JSON envelope response is not affected', () async {
        final client = DioClient(baseUrl: baseUrl);
        final response = await client.get<Map<String, dynamic>>(
          '/api/v2/core/ok',
        );
        expect(response.data, containsPair('code', 200));
      });

      test('non /api/ path HTML response is not affected', () async {
        final client = DioClient(baseUrl: baseUrl);
        final response = await client.get<String>('/downloads/file');
        expect(response.data, contains('<!DOCTYPE html>'));
      });
    });
  });
}
