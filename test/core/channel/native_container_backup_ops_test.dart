import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';

/// 容器 kill/pause、容器文件写操作与备份账户通道的参数校验契约。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('容器 kill 与暂停', () {
    test('缺 id 时返回失败结构', () async {
      for (final call in [
        NativeChannelWriteHandlers.killContainer(<String, dynamic>{}),
        NativeChannelWriteHandlers.pauseContainer(<String, dynamic>{}),
        NativeChannelWriteHandlers.unpauseContainer(<String, dynamic>{}),
      ]) {
        final result = await call;
        expect(result['success'], isFalse);
        expect(result['error'], contains('id'));
      }
    });

    test('dispatch 路由三个操作', () async {
      for (final method in [
        'killContainer',
        'pauseContainer',
        'unpauseContainer',
      ]) {
        final result = await NativeChannelManager.instance.handleMethodCall(
          method,
          <String, dynamic>{},
        );
        expect(result['success'], isFalse);
      }
    });
  });

  group('容器文件写操作', () {
    test('上传缺少容器或目录时返回失败结构', () async {
      final result =
          await NativeChannelWriteHandlers.uploadFilesToContainer(
        <String, dynamic>{'path': '/root'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('containerId'));
    });

    test('删除缺少路径时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.deleteContainerFiles(
        <String, dynamic>{'containerId': 'abc'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('paths'));
    });
  });

  group('备份账户', () {
    test('新建缺少名称或类型时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.createBackupAccount(
        <String, dynamic>{'name': 'account'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('type'));
    });

    test('修改缺少 id 时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateBackupAccount(
        <String, dynamic>{'name': 'account', 'type': 'sftp'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('id'));
    });

    test('删除缺少 id 时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.deleteBackupAccount(
        <String, dynamic>{},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('id'));
    });

    test('dispatch 路由备份账户读取与新建', () async {
      final accounts = await NativeChannelManager.instance.handleMethodCall(
        'getBackupAccounts',
        <String, dynamic>{},
      );
      expect(accounts, isA<Map<dynamic, dynamic>>());

      final created = await NativeChannelManager.instance.handleMethodCall(
        'createBackupAccount',
        <String, dynamic>{'name': 'a'},
      );
      expect(created['success'], isFalse);
    });
  });
}