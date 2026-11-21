import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/interceptors/retry_interceptor.dart';

void main() {
  late HttpServer server;
  late Dio dio;
  late int requests;
  late Completer<void> firstResponse;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}'));
    dio.interceptors.add(RetryInterceptor(dio, delay: Duration.zero));
    requests = 0;
    firstResponse = Completer<void>();
    server.listen((request) async {
      requests++;
      await request.drain<void>();
      final response = request.response;
      if (request.uri.path == '/retry-after') {
        response.headers.set('Retry-After', '60');
      }
      response.statusCode = request.uri.path == '/recover' && requests == 2
          ? HttpStatus.ok
          : HttpStatus.serviceUnavailable;
      await response.close();
      if (!firstResponse.isCompleted) firstResponse.complete();
    });
  });

  tearDown(() async {
    dio.close(force: true);
    await server.close(force: true);
  });

  test('同一客户端重新处理 GET 请求的拦截器与响应', () async {
    var intercepted = 0;
    var completed = 0;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (request, handler) {
        intercepted++;
        handler.next(request);
      },
      onResponse: (response, handler) {
        completed++;
        handler.next(response);
      },
    ));
    final response = await dio.get<dynamic>('/recover');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.requestOptions.extra[RetryInterceptor.retriedKey], true);
    expect(requests, 2);
    expect(intercepted, 2);
    expect(completed, 1);
  });

  test('连续失败的读取最多重试一次', () async {
    var failures = 0;
    dio.interceptors.add(InterceptorsWrapper(onError: (error, handler) {
      failures++;
      handler.next(error);
    }));
    await expectLater(
        dio.get<dynamic>('/unavailable'), throwsA(isA<DioException>()));
    expect(requests, 2);
    expect(failures, 1);
  });

  test('写入、带请求体的读取、流响应和服务端指定等待时间的读取只发送一次', () async {
    final calls = <Future<dynamic> Function()>[
      () => dio.post<dynamic>('/action', data: {'value': 1}),
      () => dio.put<dynamic>('/action'),
      () => dio.patch<dynamic>('/action'),
      () => dio.delete<dynamic>('/action'),
      () => dio.get<dynamic>('/read', data: 'body'),
      () => dio.get<ResponseBody>('/events',
          options: Options(responseType: ResponseType.stream)),
      () => dio.get<dynamic>('/retry-after'),
      () => dio.get<dynamic>('/private',
          options: Options(extra: {RetryInterceptor.disableRetryKey: true})),
    ];
    for (final call in calls) {
      final before = requests;
      await expectLater(call(), throwsA(isA<DioException>()));
      expect(requests, before + 1);
    }
  });

  test('等待重试时取消请求会释放等待者并阻止下一次请求', () async {
    dio.interceptors.clear();
    const delay = Duration(milliseconds: 100);
    dio.interceptors.add(RetryInterceptor(dio, delay: delay));
    final token = CancelToken();
    final result = expectLater(
      dio.get<dynamic>('/cancel', cancelToken: token),
      throwsA(isA<DioException>()
          .having((error) => error.type, 'type', DioExceptionType.cancel)),
    );
    await firstResponse.future;
    token.cancel();
    await result;
    await Future<void>.delayed(delay * 2);
    expect(requests, 1);
  });
}
