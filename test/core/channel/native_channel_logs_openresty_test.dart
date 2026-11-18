import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 日志/OpenResty 页依赖的通道契约（B16）。
/// 读 handler 失败语义：返回空列表/空对象/空串（不抛出），与 getDatabases 同型。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('logs read handlers (native channel)', () {
    test('dispatch 路由 getOperationLogs（无服务器时返回空列表）', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'getOperationLogs',
        {'page': 1, 'pageSize': 20},
      );

      expect(result, isA<List>());
    });

    test('dispatch 路由 getLoginLogs（无服务器时返回空列表）', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'getLoginLogs',
        {'page': 1, 'pageSize': 20},
      );

      expect(result, isA<List>());
    });

    test('getSystemLogContent 缺 fileName 返回空串', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'getSystemLogContent',
        {},
      );

      expect(result, '');
    });
  });

  group('openresty handlers (native channel)', () {
    test('dispatch 路由 getOpenrestySnapshot（无服务器时返回空对象）', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'getOpenrestySnapshot',
        null,
      );

      expect(result, isA<Map>());
    });

    test('updateOpenrestyConfig 空 content 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateOpenrestyConfig(
        {'content': ''},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 updateOpenrestyConfig 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'updateOpenrestyConfig',
        {'content': ''},
      );

      expect(result['success'], isFalse);
    });
  });
}
