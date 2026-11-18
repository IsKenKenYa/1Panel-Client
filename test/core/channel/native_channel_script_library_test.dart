import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 脚本库页通道契约（B20）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('deleteScripts (native channel write handler)', () {
    test('缺 ids 返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.deleteScripts(
        {'ids': null},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('空 ids 数组返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.deleteScripts(
        {'ids': <dynamic>[]},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 deleteScripts 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'deleteScripts',
        {'ids': 'x'},
      );

      // 无有效服务器时底层失败，handler 必须返回失败结构而非抛出。
      expect(result.containsKey('success'), isTrue);
    });
  });
}
