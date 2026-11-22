import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';

void main() {
  group('运行环境入口', () {
    test('缺少 id 时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.operateRuntime(
        <String, dynamic>{'id': '', 'operation': 'start'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('id'));
    });

    test('未知操作返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.operateRuntime(
        <String, dynamic>{'id': 1, 'operation': 'reload'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('operation'));
    });

    test('dispatch 路由 operateRuntime 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'operateRuntime',
        <String, dynamic>{'id': 0, 'operation': 'start'},
      );

      expect(result['success'], isFalse);
    });
  });
}