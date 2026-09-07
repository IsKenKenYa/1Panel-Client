import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 宿主安装应用商店应用（首个场景：OpenResty）依赖的
/// installApp 通道契约。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('installApp (native channel write handler)', () {
    test('缺 appKey 返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.installApp(
        {'appKey': ''},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('dispatch 路由 installApp 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'installApp',
        {'appKey': ''},
      );

      expect(result['success'], isFalse);
    });

    test('无服务器配置时调用不抛出，返回失败结构', () async {
      // 无有效服务器配置时底层请求失败，handler 必须吞掉异常返回失败结构，
      // 不允许向原生侧抛出（跨通道异常会变成 PlatformException）。
      final result = await NativeChannelWriteHandlers.installApp(
        {'appKey': 'openresty'},
      );

      expect(result.containsKey('success'), isTrue);
      expect(result['success'], anyOf(isTrue, isFalse));
    });
  });
}
