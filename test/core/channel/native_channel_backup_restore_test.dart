import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 备份页依赖的恢复通道契约（B13）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('restoreBackup (native channel write handler)', () {
    test('缺 fileName 返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.restoreBackup(
        {'id': 1, 'name': 'db', 'type': 'database'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('缺 type 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.restoreBackup(
        {'id': 1, 'name': 'db', 'fileName': 'db.tar.gz'},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 restoreBackup 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'restoreBackup',
        {'id': 1, 'name': 'db', 'fileName': 'db.tar.gz'},
      );

      // 无有效服务器时底层失败，handler 必须返回失败结构而非抛出。
      expect(result.containsKey('success'), isTrue);
    });
  });
}
