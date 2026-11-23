import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/container_log_stream_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/network/sse/sse_frame_decoder.dart';

void main() {
  group('ContainerLogStreamV2Api', () {
    late HttpServer server;
    late DioClient client;
    late String requestPath;
    late Map<String, String> queryParameters;
    late String? acceptHeader;
    late String sseBody;
    late ContentType contentType;
    late bool holdResponse;
    Completer<void>? releaseResponse;
    Completer<void>? responseClosed;
    Completer<void>? requestReceived;

    setUp(() async {
      requestPath = '';
      queryParameters = <String, String>{};
      acceptHeader = null;
      sseBody = '';
      contentType = ContentType('text', 'event-stream');
      holdResponse = false;
      releaseResponse = null;
      responseClosed = null;
      requestReceived = null;

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestPath = request.uri.path;
        queryParameters = request.uri.queryParameters;
        acceptHeader = request.headers.value('accept');
        if (requestReceived != null) {
          requestReceived!.complete();
          return;
        }

        request.response.statusCode = 200;
        request.response.headers.contentType = contentType;
        request.response.bufferOutput = false;
        request.response.write(sseBody);
        if (holdResponse) {
          await request.response.flush();
          final release = releaseResponse;
          if (release != null) await release.future;
        }
        try {
          await request.response.close();
        } catch (_) {
          // 客户端取消时连接已关闭。
        }
        final closed = responseClosed;
        if (closed != null && !closed.isCompleted) closed.complete();
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

    String sseError(String message) => 'event: error\ndata: $message\n\n';

    Future<void> waitFor(bool Function() condition) async {
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      while (!condition()) {
        if (DateTime.now().isAfter(deadline)) {
          fail('condition not met within 3 seconds');
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    test('decodes base64 SSE frames into log chunks', () async {
      sseBody = '${sseFrame('first log line\n')}'
          '${sseFrame('second log line\n')}';

      final api = ContainerLogStreamV2Api(client);
      final chunks = await api.streamContainerLogs(container: 'web-1').toList();

      expect(requestPath, '/api/v2/containers/search/log');
      expect(chunks, <String>['first log line\n', 'second log line\n']);
    });

    test('sends follow/tail/timestamp query and SSE accept header', () async {
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
      final chunks = await api.streamContainerLogs(container: 'web-1').toList();

      expect(chunks, <String>['valid chunk\n']);
    });

    test('cancels a subscription before the server sends headers', () async {
      requestReceived = Completer<void>();
      final events = ContainerLogStreamV2Api(client)
          .streamContainerLogs(container: 'web-1', follow: true);
      final subscription = events.listen((_) => fail('unexpected log'));
      await requestReceived!.future.timeout(const Duration(seconds: 3));
      await subscription.cancel().timeout(const Duration(seconds: 2));
    });

    test('rejects an HTML response to a log request', () async {
      contentType = ContentType.html;
      sseBody = '<html>login</html>';
      final events = ContainerLogStreamV2Api(client)
          .streamContainerLogs(container: 'web-1');
      await expectLater(events, emitsError(isA<FormatException>()));
    });

    test('turns a server error event into a stream error after earlier logs',
        () async {
      sseBody = '${sseFrame('before error\n')}'
          '${sseError('docker logs: no such container')}';

      final chunks = <String>[];
      final errors = <Object>[];
      final finished = Completer<void>();
      ContainerLogStreamV2Api(client)
          .streamContainerLogs(container: 'web-1', follow: true)
          .listen(chunks.add, onError: errors.add, onDone: finished.complete);

      await finished.future.timeout(const Duration(seconds: 3));
      expect(chunks, <String>['before error\n']);
      expect(errors, hasLength(1));
      expect(errors.single, isA<SseServerError>());
      expect('${errors.single}', 'docker logs: no such container');
    });

    test('cancels a live stream without reporting an error', () async {
      holdResponse = true;
      releaseResponse = Completer<void>();
      responseClosed = Completer<void>();
      sseBody = sseFrame('line one\n');

      final chunks = <String>[];
      final errors = <Object>[];
      final subscription = ContainerLogStreamV2Api(client)
          .streamContainerLogs(container: 'web-1', follow: true)
          .listen(chunks.add, onError: errors.add);

      await waitFor(() => requestPath.isNotEmpty);
      expect(requestPath, '/api/v2/containers/search/log');
      await waitFor(() => chunks.isNotEmpty);
      expect(chunks, <String>['line one\n']);

      await subscription.cancel().timeout(const Duration(seconds: 2));
      releaseResponse!.complete();
      await responseClosed!.future.timeout(const Duration(seconds: 2));
      expect(errors, isEmpty);
    });

    test('keeps the next subscription clean after cancelling the previous one',
        () async {
      holdResponse = true;
      releaseResponse = Completer<void>();
      responseClosed = Completer<void>();
      sseBody = sseFrame('first stream line\n');

      final firstChunks = <String>[];
      final firstErrors = <Object>[];
      final first = ContainerLogStreamV2Api(client)
          .streamContainerLogs(container: 'web-1', follow: true)
          .listen(firstChunks.add, onError: firstErrors.add);

      await waitFor(() => firstChunks.isNotEmpty);
      await first.cancel().timeout(const Duration(seconds: 2));
      releaseResponse!.complete();
      await responseClosed!.future.timeout(const Duration(seconds: 2));

      holdResponse = false;
      sseBody = '${sseFrame('second stream line\n')}'
          '${sseError('container stopped')}';
      final secondChunks = <String>[];
      final secondErrors = <Object>[];
      final finished = Completer<void>();
      ContainerLogStreamV2Api(client)
          .streamContainerLogs(container: 'web-1', follow: true)
          .listen(secondChunks.add,
                  onError: secondErrors.add, onDone: finished.complete);

      await finished.future.timeout(const Duration(seconds: 3));
      expect(firstChunks, <String>['first stream line\n']);
      expect(firstErrors, isEmpty);
      expect(secondChunks, <String>['second stream line\n']);
      expect(secondErrors.single, isA<SseServerError>());
      expect('${secondErrors.single}', 'container stopped');
    });
  });
}
