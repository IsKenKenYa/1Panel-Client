import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_read_handlers.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Windows 原生轨道经 NativeChannel 调用的设置读写契约。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('updateSetting (native channel write handler)', () {
    test('renderMode 写入后 getUIRenderMode 返回 md3', () async {
      final result = await NativeChannelWriteHandlers.updateSetting(
        {'key': 'renderMode', 'value': 'md3'},
      );

      expect(result['success'], isTrue);
      expect(await NativeChannelReadHandlers.getUIRenderMode(), 'md3');
    });

    test('renderMode 写入 native 返回平台支持的模式', () async {
      await NativeChannelWriteHandlers.updateSetting(
        {'key': 'renderMode', 'value': 'native'},
      );

      expect(
        await NativeChannelReadHandlers.getUIRenderMode(),
        UIRenderPolicy.resolveSupportedMode(UIRenderMode.native).name,
      );
    });

    test('language 写入后 getSettings 返回对应语言', () async {
      final result = await NativeChannelWriteHandlers.updateSetting(
        {'key': 'language', 'value': 'zh'},
      );

      expect(result['success'], isTrue);
      final settings = await NativeChannelReadHandlers.getSettings(null);
      expect(settings['language'], 'zh');
    });

    test('未知 key 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateSetting(
        {'key': 'unknown_key', 'value': 'x'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });
  });

  group('native channel dispatch (WinUI3 依赖的方法集)', () {
    test('dispatch 路由 updateSetting 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'updateSetting',
        {'key': 'renderMode', 'value': 'md3'},
      );

      expect(result['success'], isTrue);
    });

    test('未配置服务器时 getCurrentServer 返回空值', () async {
      expect(
        await NativeChannelManager.instance.handleMethodCall(
          'getCurrentServer',
          null,
        ),
        isNull,
      );
    });
  });
}
