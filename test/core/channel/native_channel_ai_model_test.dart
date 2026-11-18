import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 AI 页模型生命周期扩展通道契约（B14）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('createAIModel (native channel write handler)', () {
    test('缺 name 返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.createAIModel(
        {'name': ''},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('dispatch 路由 createAIModel 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'createAIModel',
        {'name': ''},
      );

      expect(result['success'], isFalse);
    });
  });

  group('recreateAIModel (native channel write handler)', () {
    test('缺 name 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.recreateAIModel(
        {'name': ''},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 recreateAIModel 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'recreateAIModel',
        {'name': ''},
      );

      expect(result['success'], isFalse);
    });
  });
}
