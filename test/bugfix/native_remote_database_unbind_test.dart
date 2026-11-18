import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';

void main() {
  test('原生解绑接口拒绝缺少目标面板或无效数据库标识的请求', () async {
    final channel = NativeChannelManager.instance;
    final requests = <Map<String, Object>>[
      {'id': 12},
      {'id': 12, 'serverId': ''},
      {'id': 0, 'serverId': 'panel-a'},
      {'id': '12', 'serverId': 'panel-a'},
    ];

    for (final method in ['checkRemoteDatabaseUnbind', 'unbindRemoteDatabase']) {
      for (final request in requests) {
        final reply = await channel.handleMethodCall(method, request);
        expect(reply, containsPair('success', false));
        expect(reply, containsPair('error', contains('Invalid remote database')));
      }
    }
  });
}
