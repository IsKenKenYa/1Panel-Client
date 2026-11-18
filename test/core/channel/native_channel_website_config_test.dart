import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_read_handlers.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 网站配置中心通道契约（B1）。
/// 契约单一事实源：docs/development/modules/b1_website_channel_contract.md。
/// 本测试不触网：只覆盖写 handler 必填参数快速失败与 dispatch 路由
/// （无服务器配置时读 handler 走 catch 返回空结构）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('write handlers: 必填参数缺失快速失败（不发网络请求）', () {
    test('updateWebsiteHttpsConfig 缺 websiteId', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteHttpsConfig(
        {'enable': true},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('websiteId is required'));
    });

    test('updateWebsiteProxy 缺 name', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteProxy(
        {
          'operate': 'create',
          'match': '/',
          'proxyProtocol': 'http://',
          'proxyAddress': '127.0.0.1:8080',
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('name'));
    });

    test('updateWebsiteProxy 非法 operate', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteProxy(
        {
          'operate': 'drop',
          'name': 'p1',
          'match': '/',
          'proxyAddress': '127.0.0.1:8080',
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('Unsupported operate'));
    });

    test('deleteWebsiteProxy 缺 id/name', () async {
      final result = await NativeChannelWriteHandlers.deleteWebsiteProxy({});

      expect(result['success'], isFalse);
      expect(result['error'], contains('id and name are required'));
    });

    test('updateWebsiteProxyStatus 缺 id/name', () async {
      final result =
          await NativeChannelWriteHandlers.updateWebsiteProxyStatus({});

      expect(result['success'], isFalse);
      expect(result['error'], contains('id and name are required'));
    });

    test('updateWebsiteProxyStatus 非法 status', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteProxyStatus(
        {'id': 1, 'name': 'p1', 'status': 'restart'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('Unsupported status'));
    });

    test('updateWebsiteRedirect 缺 websiteID', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteRedirect(
        {
          'operate': 'create',
          'name': 'r1',
          'type': 'domain',
          'redirect': '301',
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('websiteID is required'));
    });

    test('updateWebsiteRedirect 非法 operate', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteRedirect(
        {'websiteID': 1, 'operate': 'rollback', 'name': 'r1'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('Unsupported operate'));
    });

    test('updateWebsiteRewrite 缺 websiteID', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteRewrite(
        {'name': 'default', 'content': 'server {}'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('websiteID is required'));
    });

    test('updateWebsiteCors 缺 websiteID', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteCors(
        {'cors': true, 'allowOrigins': '*', 'allowMethods': 'GET'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('websiteID is required'));
    });

    test('updateWebsiteLeech 缺 websiteID', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteLeech(
        {
          'enable': true,
          'extends': 'png|jpg',
          'serverNames': ['a.com'],
          'return_': '404',
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('websiteID is required'));
    });

    test('updateWebsiteAuth 缺 websiteID', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteAuth(
        {'operate': 'create', 'scope': 'root', 'username': 'u'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('websiteID is required'));
    });

    test('updateWebsiteAuth 非法 operate', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteAuth(
        {'websiteID': 1, 'operate': 'upsert', 'scope': 'root'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('Unsupported operate'));
    });

    test('updateWebsitePathAuth 缺 websiteID', () async {
      final result = await NativeChannelWriteHandlers.updateWebsitePathAuth(
        {'operate': 'create', 'path': '/admin'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('websiteID is required'));
    });

    test('addWebsiteDomains 缺 websiteID', () async {
      final result = await NativeChannelWriteHandlers.addWebsiteDomains(
        {
          'domains': [
            {'domain': 'a.example.com', 'port': 80, 'ssl': false},
          ],
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('websiteID is required'));
    });

    test('addWebsiteDomains 缺 domains', () async {
      final result = await NativeChannelWriteHandlers.addWebsiteDomains(
        {'websiteID': 1},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('domains is required'));
    });

    test('deleteWebsiteDomain 缺 id', () async {
      final result =
          await NativeChannelWriteHandlers.deleteWebsiteDomain({});

      expect(result['success'], isFalse);
      expect(result['error'], contains('id is required'));
    });
  });

  group('dispatch 路由（写通道）', () {
    test('updateWebsiteHttpsConfig 已接入 dispatch（缺参返回失败结构）', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'updateWebsiteHttpsConfig',
        {'enable': true},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('websiteId is required'));
    });

    test('updateWebsiteProxy 已接入 dispatch（缺参返回失败结构）', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'updateWebsiteProxy',
        {'operate': 'create', 'match': '/'},
      );

      expect(result['success'], isFalse);
    });

    test('deleteWebsiteDomain 已接入 dispatch（缺参返回失败结构）', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'deleteWebsiteDomain',
        {},
      );

      expect(result['success'], isFalse);
    });
  });

  group('read handlers（B1 读语义：失败/缺参返回空结构）', () {
    test('getWebsiteHttpsConfig 缺 id 返回空 Map（不抛出）', () async {
      final result = await NativeChannelReadHandlers.getWebsiteHttpsConfig(
        {},
      );

      expect(result, isA<Map>());
      expect(result, isEmpty);
    });

    test('dispatch 路由 getWebsiteHttpsConfig（无服务器时返回空 Map）', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'getWebsiteHttpsConfig',
        {'id': 1},
      );

      // 无服务器配置 → getCurrentClient 抛出 → handler 捕获返回空 Map。
      expect(result, isA<Map>());
      expect(result, isEmpty);
    });

    test('dispatch 路由 getWebsiteProxies（无服务器时返回空列表）', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'getWebsiteProxies',
        {'id': 1},
      );

      expect(result, isA<List>());
      expect(result, isEmpty);
    });

    test('dispatch 路由 getWebsiteLogs（无服务器时返回空 Map）', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'getWebsiteLogs',
        {'id': 1, 'logType': 'access.log'},
      );

      expect(result, isA<Map>());
      expect(result, isEmpty);
    });
  });
}
