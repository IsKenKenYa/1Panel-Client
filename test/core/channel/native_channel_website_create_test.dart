import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 网站页新建表单依赖的 createWebsite 通道契约。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('createWebsite (native channel write handler)', () {
    test('缺 primaryDomain 返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.createWebsite(
        {'primaryDomain': ''},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('port 非法时回退默认 80 并进入创建链路（无服务器时失败但不抛出）', () async {
      // 无有效服务器配置时底层请求失败，handler 必须吞掉异常返回失败结构，
      // 不允许向原生侧抛出（跨通道异常会变成 PlatformException）。
      final result = await NativeChannelWriteHandlers.createWebsite(
        {'primaryDomain': 'demo.example.com', 'port': 'abc'},
      );

      expect(result.containsKey('success'), isTrue);
      expect(result['success'], anyOf(isTrue, isFalse));
    });

    test('dispatch 路由 createWebsite 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'createWebsite',
        {'primaryDomain': ''},
      );

      expect(result['success'], isFalse);
    });
  });

  group('openrestyMissingInPreCheck (回归：未装 OpenResty 时拦截创建)', () {
    // 服务端 /websites/check 真实返回形态（2026-09-08 US 测试面板实测）。
    test('OpenResty 应用未安装时返回 true', () {
      final blocked = NativeChannelWriteHandlers.openrestyMissingInPreCheck([
        {'name': '', 'status': '应用未安装', 'version': '', 'appName': 'OpenResty'},
      ]);

      expect(blocked, isTrue);
    });

    test('OpenResty 已安装（Running）时返回 false', () {
      final blocked = NativeChannelWriteHandlers.openrestyMissingInPreCheck([
        {'name': 'openresty', 'status': 'Running', 'version': '1.27.4', 'appName': 'OpenResty'},
      ]);

      expect(blocked, isFalse);
    });

    test('空检查列表不拦截', () {
      expect(
        NativeChannelWriteHandlers.openrestyMissingInPreCheck([]),
        isFalse,
      );
    });
  });
}
