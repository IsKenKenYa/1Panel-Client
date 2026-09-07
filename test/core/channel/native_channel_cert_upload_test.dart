import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 网关证书上传通道契约（B21）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('uploadCertificate (native channel write handler)', () {
    test('缺 certificate 返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.uploadCertificate(
        {'privateKey': 'key'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('缺 privateKey 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.uploadCertificate(
        {'certificate': 'cert'},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 uploadCertificate 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'uploadCertificate',
        {'certificate': 'cert'},
      );

      expect(result['success'], isFalse);
    });
  });
}
