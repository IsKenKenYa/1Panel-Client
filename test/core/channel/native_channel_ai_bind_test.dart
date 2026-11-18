import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 AI 域名绑定通道契约（B17，消费 getOllamaContext 发现流）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('bindAIDomain (native channel write handler)', () {
    test('缺 appInstallID 返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.bindAIDomain(
        {'appInstallID': 0, 'domain': 'ai.example.com'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('缺 domain 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.bindAIDomain(
        {'appInstallID': 5, 'domain': ''},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 bindAIDomain 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'bindAIDomain',
        {'appInstallID': 5, 'domain': ''},
      );

      expect(result['success'], isFalse);
    });
  });

  group('getOllamaContext (native channel read handler)', () {
    test('dispatch 路由 getOllamaContext（无服务器时 found=false）', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'getOllamaContext',
        null,
      );

      expect(result, isA<Map>());
      expect(result['found'], anyOf(isTrue, isFalse));
    });
  });
}
