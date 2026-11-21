import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/auth_v2.dart';
import 'package:onepanel_client/api/v2/host_v2.dart';
import 'package:onepanel_client/api/v2/toolbox_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:onepanel_client/data/models/host_models.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';

/// 回归测试：SPA 回退页识别 + legacy 端点回退 + Toolbox 信封解包修复
///
/// 问题描述（真机走查确认）：
/// 1Panel 服务端对不存在的路由返回 HTTP 200 + index.html（SPA fallback，
/// content-type text/html）。客户端此前两类缺陷：
///
/// 1. HostV2Api._postWithLegacyFallback 只捕获 DioException 且仅识别
///    404/405。而 DioClient 已把 DioException 统一转换为 NetworkException
///    子类抛出（404 → HttpException），导致 catch 永不匹配；同时 200+HTML
///    回退页被当作成功响应，Map 泛型强转抛 TypeError，主机资产整页加载失败。
/// 3. ToolboxV2Api 多个方法把 {code,message,data} 信封直接喂给
///    fromJson/PageResult.fromJson，信封字段被当业务字段解析。
///
/// 修复方式：
/// 1. DioClient._executeRequest 统一识别 /api/ 前缀请求的 200+HTML 回退页，
///    抛出 EndpointNotFoundException（「当前面板版本不支持该功能」）。
/// 2. HostV2Api 回退条件改为同时识别 EndpointNotFoundException 与
///    NetworkException.statusCode 404/405。
/// 4. ToolboxV2Api 全部改用 ApiResponseParser（asMap/asList）解包信封。
void main() {
  const htmlFallbackPage =
      '<!DOCTYPE html><html><head><title>1Panel</title></head><body></body></html>';

  late HttpServer server;
  late String baseUrl;
  late DioClient client;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://127.0.0.1:${server.port}';
    client = DioClient(baseUrl: baseUrl);
    server.listen((request) async {
      final path = request.uri.path;
      final response = request.response;
      response.statusCode = 200;
      if (path == '/api/v2/core/hosts/search') {
        // 模拟旧版服务器：新端点不存在 → SPA 回退页
        response.headers.contentType = ContentType.html;
        response.write(htmlFallbackPage);
      } else if (path == '/api/v2/hosts/search') {
        // legacy 端点返回正常信封
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'id': 1, 'name': 'local', 'addr': '127.0.0.1'},
            ],
            'total': 1,
          },
        }));
      } else if (path == '/api/v2/core/auth/passkey/list' ||
          path == '/api/v2/core/auth/mfa') {
        response.headers.contentType = ContentType.html;
        response.write(htmlFallbackPage);
      } else if (path == '/api/v2/toolbox/clam/base') {
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <String, dynamic>{
            'id': 1,
            'name': 'clam-daily',
            'status': 'enable',
            'path': '/home',
          },
        }));
      } else if (path == '/api/v2/toolbox/ftp/search') {
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'id': 3, 'user': 'ftp-user'},
            ],
            'total': 1,
          },
        }));
      } else if (path == '/api/v2/toolbox/clean/data') {
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <Map<String, dynamic>>[
            <String, dynamic>{'name': 'systemTemp', 'size': '10MB', 'path': '/tmp'},
          ],
        }));
      } else {
        response.statusCode = 404;
      }
      await response.close();
    });
  });

  tearDown(() async {
    client.dio.close();
    await server.close(force: true);
  });

  group('HostV2Api legacy 回退（200+HTML 回退页触发）', () {
    test('searchHosts 新端点返回 SPA 回退页时自动回退 legacy 端点', () async {
      final api = HostV2Api(client);
      final response = await api.searchHosts(
        const HostSearch(page: 1, pageSize: 10),
      );

      expect(response.data, isNotNull);
      expect(response.data!.total, 1);
      expect(response.data!.items, hasLength(1));
      expect(response.data!.items.first.name, 'local');
    });
  });

  group('AuthV2Api 检查账号接口响应', () {
    test('Passkey 列表返回 HTML 时报告错误', () async {
      await expectLater(
        AuthV2Api(client).listPasskeysAuth(),
        throwsA(isA<EndpointNotFoundException>()),
      );
    });

    test('loadMfaInfo 拒绝 HTML 响应', () async {
      final api = AuthV2Api(client);
      await expectLater(
        api.loadMfaInfo({'title': 'KenPanel', 'interval': 30}),
        throwsA(isA<EndpointNotFoundException>()),
      );
    });
  });

  group('ToolboxV2Api 信封解包', () {
    test('getClamBaseInfo 解包 {code,message,data} 信封', () async {
      final api = ToolboxV2Api(client);
      final response = await api.getClamBaseInfo();

      expect(response.data, isNotNull);
      expect(response.data!.id, 1);
      expect(response.data!.name, 'clam-daily');
      expect(response.data!.status, 'enable');
    });

    test('searchFtp 解包信封后按 PageResult 解析', () async {
      final api = ToolboxV2Api(client);
      final response = await api.searchFtp(
        const FtpSearch(info: '', page: 1, pageSize: 20),
      );

      expect(response.data!.total, 1);
      expect(response.data!.items, hasLength(1));
      expect(response.data!.items.first.user, 'ftp-user');
    });

    test('getCleanData 解包信封后按列表解析', () async {
      final api = ToolboxV2Api(client);
      final response = await api.getCleanData();

      expect(response.data, hasLength(1));
      expect(response.data!.first.name, 'systemTemp');
      expect(response.data!.first.size, '10MB');
    });
  });
}
