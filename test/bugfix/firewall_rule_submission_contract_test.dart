import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/data/models/firewall_v2_models.dart';
import 'package:onepanel_client/data/models/task_log_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('端口规则保留来访地址、目标端口、协议与操作', () {
    final request = FirewallRuleCreateRequest.forInboundRule(
      sourceAddress: '2001:db8::/64',
      destinationPort: '443, 8000-8001',
      protocol: 'tcp/udp',
      action: 'accept',
      description: 'HTTPS',
    );

    expect(request.toJson(), {
      'items': [
        for (final protocol in ['tcp', 'udp'])
          {
            'rule': {
              'sourceAddress': '2001:db8::/64',
              'scope': {'family': 'ipv6'},
              'destinationPort': '443,8000-8001',
              'protocol': protocol,
              'action': 'accept',
              'description': 'HTTPS',
            },
            'sourceKind': 'user',
          },
      ],
    });
  });

  test('地址规则只对所填来源地址匹配所有协议', () {
    final request = FirewallRuleCreateRequest.forInboundRule(
      sourceAddress: '192.0.2.4',
      action: 'drop',
    );

    expect(request.items!.single['rule'], {
      'sourceAddress': '192.0.2.4',
      'scope': {'family': 'ipv4'},
      'protocol': 'all',
      'action': 'drop',
    });
  });

  test('多个来源地址各自携带地址族，保持防火墙后端的匹配范围', () {
    final request = FirewallRuleCreateRequest.forInboundRule(
      sourceAddress: '192.0.2.4, 2001:db8::/64, ::ffff:192.0.2.5',
      destinationPort: '80',
      action: 'drop',
    );

    final scopes = request.items!.map((item) => item['rule']['scope']);
    expect(scopes, [
      {'family': 'ipv4'},
      {'family': 'ipv6'},
      {'family': 'ipv4'}
    ]);
  });

  test('禁止将缺少匹配条件或填写通配端口的规则交给面板', () {
    for (final port in ['', 'any', '*', '0', '65536', '90-80', '80,', '0x50']) {
      expect(
        () => FirewallRuleCreateRequest.forInboundRule(
          destinationPort: port,
          protocol: 'tcp',
          action: 'accept',
        ),
        throwsFormatException,
      );
    }
    for (final address in ['any', 'anywhere (v6)', '192.0.2.4,']) {
      expect(
        () => FirewallRuleCreateRequest.forInboundRule(
          sourceAddress: address,
          action: 'drop',
        ),
        throwsFormatException,
      );
    }
  });

  test('防火墙任务通过完整任务 ID 查询，旧查询保持原格式', () {
    const old = TaskLogSearch();
    const byId = TaskLogSearch(taskId: 'firewall-task-id', pageSize: 1);

    expect(old.toJson(), isNot(contains('taskID')));
    expect(byId.toJson(), containsPair('taskID', 'firewall-task-id'));
    expect(TaskLogSearch.fromJson(byId.toJson()).taskId, byId.taskId);
  });

  test('原生表单的空白规则返回失败', () async {
    final reply = await NativeChannelManager.instance.handleMethodCall(
      'addFirewallRule',
      {'port': ' ', 'address': ' '},
    );

    expect(reply, containsPair('success', false));
    expect(reply, containsPair('error', contains('port or source address')));
  });
}
