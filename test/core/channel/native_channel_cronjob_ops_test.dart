import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 定时任务页依赖的建/改/执行一次通道契约（B12）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('createCronJob (native channel write handler)', () {
    test('缺 name 返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.createCronJob(
        {'name': '', 'spec': '* * * * *', 'script': 'echo hi'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('缺 spec 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.createCronJob(
        {'name': 'task', 'script': 'echo hi'},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 createCronJob 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'createCronJob',
        {'name': ''},
      );

      expect(result['success'], isFalse);
    });
  });

  group('updateCronJob (native channel write handler)', () {
    test('缺 id 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateCronJob(
        {'name': 't', 'spec': '* * * * *', 'script': 'x'},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 updateCronJob 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'updateCronJob',
        {'name': 't'},
      );

      expect(result['success'], isFalse);
    });
  });

  group('handleCronJobOnce (native channel write handler)', () {
    test('缺 id 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.handleCronJobOnce(
        {'id': null},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('dispatch 路由 handleCronJobOnce 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'handleCronJobOnce',
        {'id': 'x'},
      );

      // 无有效服务器时底层失败，handler 必须返回失败结构而非抛出。
      expect(result.containsKey('success'), isTrue);
    });
  });
}
