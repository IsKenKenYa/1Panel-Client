import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';

void main() {
  group('防火墙 V2 写入入口', () {
    test('Docker 操作名不在允许集合时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.operateFirewallDockerGuard(
        <String, dynamic>{'operation': 'restart'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('operation'));
    });

    test('转发规则为空时返回失败结构', () async {
      final result =
          await NativeChannelWriteHandlers.operateFirewallForwardRules(
        <String, dynamic>{'rules': <Object>[]},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('rules'));
    });

    test('Docker 策略为空时返回失败结构', () async {
      final result =
          await NativeChannelWriteHandlers.upsertFirewallDockerPolicies(
        <String, dynamic>{'policies': <Object>[]},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('policies'));
    });

    test('Docker 策略删除缺少标识时返回失败结构', () async {
      final result =
          await NativeChannelWriteHandlers.deleteFirewallDockerPolicies(
        <String, dynamic>{'uuids': <String>[]},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('uuids'));
    });

    test('后端操作缺少字段时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.operateFirewallBackend(
        <String, dynamic>{'backend': 'nftables'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('backend'));
    });

    test('dispatch 路由 Docker 守卫操作', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'operateFirewallDockerGuard',
        <String, dynamic>{'operation': 'invalid'},
      );

      expect(result['success'], isFalse);
    });
  });
}