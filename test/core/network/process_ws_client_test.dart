import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/process_ws_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
      'ProcessWsClient connects to /process/ws with operateNode and auth headers',
      () async {
    late String requestPath;
    late String operateNode;
    late HttpHeaders headers;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      requestPath = request.uri.path;
      operateNode = request.uri.queryParameters['operateNode'] ?? '';
      headers = request.headers;
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((_) {
        socket.add('[{"PID":1,"name":"sshd"}]');
      });
    });

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final config = ApiConfig(
      id: 'test-server',
      name: 'Test',
      url: 'http://${server.address.host}:${server.port}',
      apiKey: 'test-key',
      isDefault: true,
    );
    await ApiConfigManager.saveConfig(config);
    await ApiConfigManager.setCurrentConfig(config.id);

    final client = ProcessWsClient();
    await client.connect();
    final future = client.messages.first.timeout(const Duration(seconds: 5));
    await client.send(const <String, dynamic>{
      'type': 'ps',
      'pid': null,
      'name': '',
      'username': '',
    });
    final result = await future;

    expect(requestPath, '/api/v2/process/ws');
    expect(operateNode, 'local');
    expect(headers.value('1Panel-Token'), isNotEmpty);
    expect(headers.value('1Panel-Timestamp'), isNotEmpty);
    expect(result, isA<List<dynamic>>());

    await client.close();
    await server.close(force: true);
  });
}
