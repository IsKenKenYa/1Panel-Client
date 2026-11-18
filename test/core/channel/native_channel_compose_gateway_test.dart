import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 Compose 建/改与网关 HTTPS 开关通道契约（B19）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('createCompose (native channel write handler)', () {
    test('缺 name 返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.createCompose(
        {'file': 'services: {}'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('from=path 缺 path 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.createCompose(
        {'name': 'web', 'from': 'path'},
      );

      expect(result['success'], isFalse);
    });

    test('回归：from=raw 归一化为服务端合法枚举 edit，不再被 path 校验拦截', () async {
      // 服务端 ComposeCreate.from 枚举为 edit|path|template（2026-09-08
      // 上游 400 oneof 校验实测），from=raw 必须映射为 edit。
      final result = await NativeChannelWriteHandlers.createCompose(
        {'name': 'web', 'from': 'raw', 'file': 'services: {}'},
      );

      // 无服务器配置时网络层失败，但绝不能是 path 必填校验错误。
      expect(result['success'], isFalse);
      expect(result['error'], isNot(contains('path is required')));
    });

    test('dispatch 路由 createCompose 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'createCompose',
        {'name': ''},
      );

      expect(result['success'], isFalse);
    });
  });

  group('updateCompose (native channel write handler)', () {
    test('缺 name/path/content 任一返回失败结构', () async {
      final r1 = await NativeChannelWriteHandlers.updateCompose(
        {'path': '/x', 'content': 'c'},
      );
      final r2 = await NativeChannelWriteHandlers.updateCompose(
        {'name': 'web', 'content': 'c'},
      );
      final r3 = await NativeChannelWriteHandlers.updateCompose(
        {'name': 'web', 'path': '/x'},
      );

      expect(r1['success'], isFalse);
      expect(r2['success'], isFalse);
      expect(r3['success'], isFalse);
    });

    test('dispatch 路由 updateCompose 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'updateCompose',
        {'name': 'web'},
      );

      expect(result['success'], isFalse);
    });
  });

  group('updateOpenrestyHttps (native channel write handler)', () {
    test('operate 非白名单返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateOpenrestyHttps(
        {'operate': 'nuke'},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 updateOpenrestyHttps 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'updateOpenrestyHttps',
        {'operate': 'nuke'},
      );

      expect(result['success'], isFalse);
    });
  });
}
