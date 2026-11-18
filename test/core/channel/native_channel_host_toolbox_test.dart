import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 主机/工具箱页依赖的读写通道契约（B15）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('operateSsh (native channel write handler)', () {
    test('operation 非白名单返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.operateSsh(
        {'operation': 'nuke'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('dispatch 路由 operateSsh 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'operateSsh',
        {'operation': 'nuke'},
      );

      expect(result['success'], isFalse);
    });
  });

  group('saveSshConfig (native channel write handler)', () {
    test('空 config 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.saveSshConfig(
        {'value': ''},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 saveSshConfig 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'saveSshConfig',
        {'value': ''},
      );

      expect(result['success'], isFalse);
    });
  });

  group('verifyToolboxDns (native channel write handler)', () {
    test('空 dns 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.verifyToolboxDns(
        {'dns': ''},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 verifyToolboxDns 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'verifyToolboxDns',
        {'dns': '8.8.8.8'},
      );

      // 无有效服务器时底层失败，handler 必须返回失败结构而非抛出。
      expect(result.containsKey('success'), isTrue);
    });
  });
}
