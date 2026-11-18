import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 编排/安全网关页通道契约（B18，只读最小集 + 编排操作）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('composeOperate (native channel write handler)', () {
    test('action 非白名单返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.composeOperate(
        {'id': 'c-1', 'name': 'web', 'action': 'format-disk'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('缺 name 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.composeOperate(
        {'id': 'c-1', 'action': 'start'},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 composeOperate 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'composeOperate',
        {'id': 'c-1', 'name': 'web', 'action': 'format-disk'},
      );

      expect(result['success'], isFalse);
    });
  });
}
