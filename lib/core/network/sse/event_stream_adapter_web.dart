import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

void configureEventStreamAdapter(Dio dio) {
  dio.httpClientAdapter = _EventStreamAdapter(dio.httpClientAdapter);
}

class _EventStreamAdapter implements HttpClientAdapter {
  _EventStreamAdapter(this._defaultAdapter);

  final HttpClientAdapter _defaultAdapter;
  final _client = BrowserClient();
  final _active = <Completer<void>>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method != 'GET' ||
        options.responseType != ResponseType.stream ||
        options.headers['Accept'] != 'text/event-stream') {
      return _defaultAdapter.fetch(options, requestStream, cancelFuture);
    }
    // Fetch 可以在连接保持打开时逐块读取日志。
    final abort = Completer<void>();
    _active.add(abort);
    void cancel() {
      _active.remove(abort);
      if (!abort.isCompleted) abort.complete();
    }

    cancelFuture?.then((_) => cancel());
    final request =
        http.AbortableRequest('GET', options.uri, abortTrigger: abort.future)
          ..followRedirects = options.followRedirects;
    for (final entry in options.headers.entries) {
      if (entry.value != null) {
        request.headers[entry.key] = entry.value.toString();
      }
    }
    try {
      final response = await _client.send(request);
      Stream<Uint8List> body() async* {
        try {
          await for (final bytes in response.stream.cast<Uint8List>()) {
            yield bytes;
          }
        } on http.ClientException {
          if (!abort.isCompleted) {
            throw DioException.connectionError(
              requestOptions: options,
              reason: '浏览器与面板的日志连接已中断',
            );
          }
        } finally {
          cancel();
        }
      }

      return ResponseBody(
        body(),
        response.statusCode,
        statusMessage: response.reasonPhrase,
        onClose: cancel,
        headers: response.headers.map((key, value) => MapEntry(key, [value])),
      );
    } on http.RequestAbortedException {
      cancel();
      throw options.cancelToken?.cancelError ??
          DioException.requestCancelled(requestOptions: options, reason: null);
    } on http.ClientException {
      cancel();
      throw DioException.connectionError(
          requestOptions: options, reason: '浏览器未能连接面板');
    }
  }

  @override
  void close({bool force = false}) {
    if (force) {
      for (final abort in _active) {
        if (!abort.isCompleted) abort.complete();
      }
      _active.clear();
    }
    _client.close();
    _defaultAdapter.close(force: force);
  }
}
