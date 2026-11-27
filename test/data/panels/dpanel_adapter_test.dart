import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/panels/dpanel_adapter.dart';
import 'package:onepanel_client/data/panels/panel_adapter.dart';
import 'package:onepanel_client/data/panels/panel_registry.dart';

void main() {
  late HttpServer server;
  var loginCount = 0;
  var failNextAuthOnce = false;
  String? lastOperatePayload;
  String? lastLoginCookie;
  String? lastAuthHeader;
  var currentToken = 'token-v1';

  setUp(() async {
    loginCount = 0;
    failNextAuthOnce = false;
    lastOperatePayload = null;
    lastLoginCookie = null;
    lastAuthHeader = null;
    currentToken = 'token-v1';

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      final path = request.uri.path;
      final bodyText = await utf8.decoder.bind(request).join();
      final body = bodyText.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(bodyText) as Map<String, dynamic>;

      if (request.method == 'GET' && path == '/secret-gate') {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.add('set-cookie', 'DPanelEntrance=signed-cookie-value; Path=/')
          ..headers.add('location', '/');
        await request.response.close();
        return;
      }

      if (path == '/dpanel/api/common/user/login') {
        loginCount++;
        lastLoginCookie = request.headers.value('cookie');
        if (body['username'] != 'admin' || body['password'] != 'secret') {
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'code': 500, 'error': 'Invalid credentials'}));
          await request.response.close();
          return;
        }
        currentToken = 'token-v$loginCount';
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'code': 200,
              'data': {'accessToken': currentToken, 'redirect': '/home/overview'},
            }),
          );
        await request.response.close();
        return;
      }

      lastAuthHeader = request.headers.value('x-dpanel-authorization');
      if (failNextAuthOnce || lastAuthHeader != 'Bearer $currentToken') {
        failNextAuthOnce = false;
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'code': 401, 'error': 'Login required'}));
        await request.response.close();
        return;
      }

      if (path == '/dpanel/api/common/home/info') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'code': 200,
              'data': {
                'info': {
                  'OperatingSystem': 'Ubuntu 24.04 LTS',
                  'ServerVersion': '27.3.1',
                  'Containers': 5,
                  'ContainersRunning': 3,
                },
                'dpanel': {'version': '1.6.2'},
                'dockerEnv': {'name': 'local', 'title': 'Local Docker'},
              },
            }),
          );
        await request.response.close();
        return;
      }

      if (path == '/dpanel/api/common/user/get-user-info') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'code': 200,
              'data': {
                'feature': ['version-env-standard', 'swarm-manage'],
              },
            }),
          );
        await request.response.close();
        return;
      }

      if (path == '/dpanel/api/common/home/get-stat-list') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'code': 200,
              'data': {
                'dockerEnvName': 'local',
                'docker': [],
                'system': {
                  'cpu': {'cores': 4, 'usagePercent': 24.5, 'load1': 0.72},
                  'memory': {'total': 1000, 'available': 250},
                },
              },
            }),
          );
        await request.response.close();
        return;
      }

      if (path == '/dpanel/api/app/container/get-list') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'code': 200,
              'data': {
                'list': [
                  {
                    'Id': 'abc123def456',
                    'Names': ['/nginx-proxy'],
                    'Image': 'nginx:alpine',
                    'State': 'running',
                    'Status': 'Up 2 hours',
                  },
                ],
              },
            }),
          );
        await request.response.close();
        return;
      }

      if (path == '/dpanel/api/app/container/status') {
        lastOperatePayload = bodyText;
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'code': 200, 'data': {}}));
        await request.response.close();
        return;
      }

      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
  });

  ApiConfig dpanelConfig({
    String password = 'secret',
    String entrance = '',
    String suffix = '',
  }) {
    return ApiConfig(
      id: 'dp-1',
      name: 'DPanel Test',
      url: 'http://${server.address.address}:${server.port}$suffix',
      apiKey: '',
      panelType: DPanelAdapter.panelTypeId,
      additionalCredentials: {
        DPanelAdapter.fieldUsername: 'admin',
        DPanelAdapter.fieldPassword: password,
        if (entrance.isNotEmpty) DPanelAdapter.fieldEntrance: entrance,
      },
    );
  }

  test('支持安全入口 Cookie 登录、连接探测、能力与指标采集', () async {
    final session = const DPanelAdapter().open(
      dpanelConfig(entrance: 'secret-gate', suffix: '/dpanel/api/'),
    );
    addTearDown(session.close);

    final conn = await session.testConnection();
    expect(conn.success, isTrue);
    expect(conn.operatingSystem, 'Ubuntu 24.04 LTS · DPanel 1.6.2');
    expect(lastLoginCookie, 'DPanelEntrance=signed-cookie-value');
    expect(loginCount, 1);

    final caps = await session.loadCapabilities();
    expect(caps['containers'], PanelAccess.write);
    expect(caps['sites'], PanelAccess.read);
    expect(caps['swarm'], PanelAccess.read);

    final metrics = await session.loadMetrics();
    expect(metrics.isReachable, isTrue);
    expect(metrics.cpuPercent, 24.5);
    expect(metrics.memoryPercent, 75.0);
    expect(metrics.load, 0.72);
    expect(loginCount, 1);
  });

  test('令牌失效收到 401 时自动重新登录并重试请求', () async {
    final session = const DPanelAdapter().open(dpanelConfig());
    addTearDown(session.close);

    final initial = await session.listContainers();
    expect(initial, hasLength(1));
    expect(initial.single.name, 'nginx-proxy');
    expect(initial.single.isRunning, isTrue);
    expect(loginCount, 1);

    failNextAuthOnce = true;
    await session.operateContainer('abc123def456', 'restart');
    expect(loginCount, 2);
    expect(lastAuthHeader, 'Bearer token-v2');
    expect(jsonDecode(lastOperatePayload!), {
      'md5': 'abc123def456',
      'operate': 'restart',
    });
  });

  test('默认 PanelRegistry 已注册 DPanel 适配器且错误凭据返回失败', () async {
    expect(PanelRegistry.instance.supports(DPanelAdapter.panelTypeId), isTrue);
    final session = const DPanelAdapter().open(dpanelConfig(password: 'wrong'));
    addTearDown(session.close);

    final result = await session.testConnection();
    expect(result.success, isFalse);
    expect(result.errorMessage, 'Invalid credentials');
  });
}
