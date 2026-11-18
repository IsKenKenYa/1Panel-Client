import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 命令库页与 AI 域名绑定发现流通道契约（B17）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('createCommand (native channel write handler)', () {
    test('缺 name 或 command 返回失败结构（不发网络请求）', () async {
      final r1 = await NativeChannelWriteHandlers.createCommand(
        {'name': '', 'command': 'ls'},
      );
      final r2 = await NativeChannelWriteHandlers.createCommand(
        {'name': 't', 'command': ''},
      );

      expect(r1['success'], isFalse);
      expect(r2['success'], isFalse);
    });

    test('dispatch 路由 createCommand 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'createCommand',
        {'name': ''},
      );

      expect(result['success'], isFalse);
    });
  });

  group('deleteCommand (native channel write handler)', () {
    test('缺 id 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.deleteCommand(
        {'id': null},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 deleteCommand 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'deleteCommand',
        {'id': 'x'},
      );

      // 无有效服务器时底层失败，handler 必须返回失败结构而非抛出。
      expect(result.containsKey('success'), isTrue);
    });
  });
}
