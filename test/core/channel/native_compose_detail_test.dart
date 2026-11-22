import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_read_handlers.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';

void main() {
  group('Compose 详情通道', () {
    test('内容路径为空时直接返回空文本', () async {
      final result = await NativeChannelReadHandlers.getComposeContent(
        <String, dynamic>{'path': '  '},
      );

      expect(result, '');
    });

    test('校验缺少名称时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.testCompose(
        <String, dynamic>{'content': 'services: {}'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('name'));
    });

    test('校验缺少内容时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.testCompose(
        <String, dynamic>{'name': 'web'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('content'));
    });

    test('保存缺少内容时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateCompose(
        <String, dynamic>{
          'name': 'web',
          'path': '/opt/1panel/docker/compose/web/docker-compose.yml',
          'detailPath':
              '/opt/1panel/docker/compose/web/docker-compose.yml',
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('content'));
    });

    test('清理日志缺少路径时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.cleanComposeLog(
        <String, dynamic>{'name': 'web'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('path'));
    });

    test('dispatch 路由 Compose 校验', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'testCompose',
        <String, dynamic>{},
      );

      expect(result['success'], isFalse);
    });
  });
}