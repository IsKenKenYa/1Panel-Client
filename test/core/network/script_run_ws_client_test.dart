import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/script_run_ws_client.dart';

void main() {
  test(
      'ScriptRunWsClient connects to /core/script/run and decodes base64 output',
      () async {
    late String requestPath;
    late Map<String, String> queryParameters;
    late HttpHeaders headers;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      requestPath = request.uri.path;
      queryParameters = request.uri.queryParameters;
      headers = request.headers;
      final socket = await WebSocketTransformer.upgrade(request);
      socket.add(
        jsonEncode(<String, dynamic>{
          'type': 'cmd',
          'data': base64.encode(utf8.encode('hello script\n')),
        }),
      );
    });

    final config = ApiConfig(
      id: 'test-server',
      name: 'Test',
      url: 'http://${server.address.host}:${server.port}',
      apiKey: 'test-key',
      isDefault: true,
    );
    final client = ScriptRunWsClient(config: config);
    final firstOutput = client.output.first;
    await client.connect(scriptId: 9, cols: 100, rows: 30);
    final output = await firstOutput.timeout(const Duration(seconds: 5));

    expect(requestPath, '/api/v2/core/script/run');
    expect(queryParameters['script_id'], '9');
    expect(queryParameters['cols'], '100');
    expect(queryParameters['rows'], '30');
    expect(queryParameters['operateNode'], 'local');
    expect(headers.value('1Panel-Token'), isNotEmpty);
    expect(headers.value('1Panel-Timestamp'), isNotEmpty);
    expect(output, 'hello script\n');

    await client.close();
    await server.close(force: true);
  });

  test('script WebSocket requires a 1Panel configuration', () async {
    final client = ScriptRunWsClient(
      config: ApiConfig(
        id: 'other',
        name: 'Other',
        url: 'https://panel.invalid',
        panelType: 'other',
        apiKey: '',
      ),
    );
    await expectLater(client.connect(scriptId: 1), throwsUnsupportedError);
  });
}
