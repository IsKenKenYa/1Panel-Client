import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 证书应用与 Compose 模板创建通道契约（B22）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('applyCertificate (native channel write handler)', () {
    test('缺 id 返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.applyCertificate(
        {'id': null},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('dispatch 路由 applyCertificate 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'applyCertificate',
        {'id': 'x'},
      );

      // 无有效服务器时底层失败，handler 必须返回失败结构而非抛出。
      expect(result.containsKey('success'), isTrue);
    });
  });

  group('createCompose template (native channel write handler)', () {
    test('from=template 缺 template id 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.createCompose(
        {'name': 'web', 'from': 'template'},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 from=template 创建（缺 name 仍失败）', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'createCompose',
        {'name': '', 'from': 'template'},
      );

      expect(result['success'], isFalse);
    });
  });
}
