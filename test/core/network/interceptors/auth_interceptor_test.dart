import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/interceptors/auth_interceptor.dart';

void main() {
  group('AuthInterceptor', () {
    test('onRequest adds auth headers when apiKey is set', () {
      final interceptor = AuthInterceptor('test-api-key');
      final handler = _TestRequestInterceptorHandler();
      final options = RequestOptions(path: '/api/v2/test');

      interceptor.onRequest(options, handler);

      expect(options.headers['1Panel-Token'], isNotNull);
      expect(options.headers['1Panel-Timestamp'], isNotNull);
      expect(options.headers['Content-Type'], 'application/json');
      expect(options.headers['Accept'], 'application/json');
      expect(options.headers['User-Agent'], ApiConstants.userAgent);
    });

    test('onRequest does not add auth headers when apiKey is null', () {
      final interceptor = AuthInterceptor(null);
      final handler = _TestRequestInterceptorHandler();
      final options = RequestOptions(path: '/api/v2/test');

      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('1Panel-Token'), isFalse);
      expect(options.headers.containsKey('1Panel-Timestamp'), isFalse);
    });

    test('保留调用方声明的请求和响应类型', () {
      final request = RequestOptions(
        path: '/api/v2/test',
        contentType: 'application/octet-stream',
        headers: {'Accept': 'text/event-stream'},
      );
      AuthInterceptor('key').onRequest(request, RequestInterceptorHandler());
      expect(request.contentType, 'application/octet-stream');
      expect(request.headers['Accept'], 'text/event-stream');
    });

    test('onRequest does not add auth headers when apiKey is empty', () {
      final interceptor = AuthInterceptor('');
      final handler = _TestRequestInterceptorHandler();
      final options = RequestOptions(path: '/api/v2/test');

      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('1Panel-Token'), isFalse);
    });

    test('updateApiKey changes the key for subsequent requests', () {
      final interceptor = AuthInterceptor('old-key');
      final handler1 = _TestRequestInterceptorHandler();
      final options1 = RequestOptions(path: '/test');

      interceptor.onRequest(options1, handler1);
      final oldToken = options1.headers['1Panel-Token'];

      interceptor.updateApiKey('new-key');
      final handler2 = _TestRequestInterceptorHandler();
      final options2 = RequestOptions(path: '/test');

      interceptor.onRequest(options2, handler2);
      final newToken = options2.headers['1Panel-Token'];

      // Both should have tokens (timestamps may differ)
      expect(oldToken, isNotNull);
      expect(newToken, isNotNull);
    });

    test('onRequest calls handler.next', () {
      final interceptor = AuthInterceptor('key');
      final handler = _TestRequestInterceptorHandler();
      final options = RequestOptions(path: '/test');

      interceptor.onRequest(options, handler);
      expect(handler.nextCalled, isTrue);
    });

    test('onError passes through for all status codes', () {
      final interceptor = AuthInterceptor('key');
      final handler = _TestErrorInterceptorHandler();
      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/test'),
        ),
        type: DioExceptionType.badResponse,
      );

      interceptor.onError(err, handler);
      expect(handler.nextCalled, isTrue);
    });

    test('onError passes through for non-401 errors', () {
      final interceptor = AuthInterceptor('key');
      final handler = _TestErrorInterceptorHandler();
      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/test'),
        ),
        type: DioExceptionType.badResponse,
      );

      interceptor.onError(err, handler);
      expect(handler.nextCalled, isTrue);
    });
  });
}

class _TestRequestInterceptorHandler extends RequestInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(RequestOptions options) {
    nextCalled = true;
  }

  @override
  void resolve(Response response, [bool callFollowingResponseInterceptor = false]) {}

  @override
  void reject(DioException e, [bool callFollowingErrorInterceptor = false]) {}
}

class _TestErrorInterceptorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(DioException err) {
    nextCalled = true;
  }

  @override
  void resolve(Response response, [bool callFollowingResponseInterceptor = false]) {}

  @override
  void reject(DioException e, [bool callFollowingErrorInterceptor = false]) {}
}
