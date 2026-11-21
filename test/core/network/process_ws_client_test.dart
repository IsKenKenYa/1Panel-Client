import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/process_ws_client.dart';

void main() {
  test(
      'ProcessWsClient connects to /process/ws with operateNode and auth headers',
      () async {
    late String requestPath;
    late String operateNode;
    late HttpHeaders headers;
    var connections = 0;
    var queries = 0;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      connections++;
      requestPath = request.uri.path;
      operateNode = request.uri.queryParameters['operateNode'] ?? '';
      headers = request.headers;
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((_) {
        queries++;
        socket.add('[{"PID":1,"name":"sshd"}]');
      });
    });

    final config = ApiConfig(
      id: 'test-server',
      name: 'Test',
      url: 'http://${server.address.host}:${server.port}',
      apiKey: 'test-key',
      isDefault: true,
    );
    final client = ProcessWsClient(config: config);
    await Future.wait([client.connect(), client.connect()]);
    final future = client.messages.first.timeout(const Duration(seconds: 5));
    const query = <String, dynamic>{
      'type': 'ps',
      'pid': null,
      'name': '',
      'username': '',
    };
    await Future.wait([client.send(query), client.send(query)]);
    final result = await future;

    expect(requestPath, '/api/v2/process/ws');
    expect(connections, 1);
    expect(queries, 1);
    expect(operateNode, 'local');
    expect(headers.value('1Panel-Token'), isNotEmpty);
    expect(headers.value('1Panel-Timestamp'), isNotEmpty);
    expect(result, isA<List<dynamic>>());

    await client.close();
    await server.close(force: true);
  });

  test('closing a pending handshake leaves the client disconnected', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final received = Completer<void>();
    server.listen((_) => received.complete());
    final client = ProcessWsClient(
        config: ApiConfig(
      id: 'loopback',
      name: 'Loopback',
      apiKey: 'test',
      url: 'http://${server.address.host}:${server.port}',
    ));
    final opening = client.connect();
    await received.future.timeout(const Duration(seconds: 5));
    await client.close();
    await opening.timeout(const Duration(seconds: 5));
    expect(client.isConnected, isFalse);
  });
}
