import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:onepanel_client/core/channel/native_firewall_payloads.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';

void main() {
  group('firewallBasePayload', () {
    test('基础状态字段透传', () {
      final payload = firewallBasePayload(const FirewallBaseInfo(
        name: 'firewalld',
        isExist: true,
        isActive: true,
        isInit: true,
        isBind: false,
        version: '1.2.3',
        pingStatus: 'ok',
      ));

      expect(payload['name'], 'firewalld');
      expect(payload['isActive'], isTrue);
      expect(payload['version'], '1.2.3');
    });
  });

  group('firewallRulePayloads', () {
    test('重复 inventoryId 生成稳定行标识并计算可删除状态', () {
      final rules = <FirewallRule>[
        const FirewallRule(
          inventoryId: 'inv-1',
          supportsLegacyChanges: false,
          modernTarget: FirewallInventoryDeletionTarget.managed('uuid-1'),
          port: '80',
        ),
        const FirewallRule(
          inventoryId: 'inv-1',
          supportsLegacyChanges: false,
          modernTarget: FirewallInventoryDeletionTarget.managed('uuid-1'),
          port: '443',
        ),
      ];

      final payloads = firewallRulePayloads(rules, serverId: 'server-1');

      expect(payloads, hasLength(2));
      expect(payloads.first['id'], 'inv-1');
      expect(payloads.last['id'], 'row-1');
      expect(payloads.first['serverId'], 'server-1');
      expect(payloads.first['canDelete'], isFalse);
    });

    test('传统规则在可删除时输出字段', () {
      final payloads = firewallRulePayloads(<FirewallRule>[
        const FirewallRule(
          id: 7,
          supportsLegacyChanges: true,
          protocol: 'tcp',
          port: '22',
          address: '0.0.0.0',
          strategy: 'accept',
          description: 'ssh',
        ),
      ]);

      expect(payloads.first['protocol'], 'tcp');
      expect(payloads.first['port'], '22');
      expect(payloads.first['canDelete'], isTrue);
      expect(payloads.first['description'], 'ssh');
    });
  });

  group('firewallFlatPayload', () {
    test('嵌套结构转成 JSON 文本', () {
      final payload = firewallFlatPayload(<String, dynamic>{
        'system': <String, dynamic>{'selected': 'firewalld'},
        'count': 3,
        'enabled': true,
      });

      expect(payload['count'], '3');
      expect(payload['enabled'], 'true');
      expect(jsonDecode(payload['system']!), <String, dynamic>{'selected': 'firewalld'});
    });
  });

  group('规则更新请求', () {
    test('端口更新保留旧值与新值', () {
      final request = firewallPortUpdateRequest(<String, dynamic>{
        'oldRule': <String, dynamic>{
          'address': '0.0.0.0',
          'port': '80',
          'protocol': 'tcp',
          'strategy': 'accept',
        },
        'newRule': <String, dynamic>{
          'address': '0.0.0.0',
          'port': '8080',
          'protocol': 'tcp',
          'strategy': 'drop',
          'description': 'web',
        },
      });

      expect(request.oldRule.port, '80');
      expect(request.newRule.port, '8080');
      expect(request.newRule.strategy, 'drop');
      expect(request.newRule.description, 'web');
    });

    test('IP 更新保留策略与描述', () {
      final request = firewallIpUpdateRequest(<String, dynamic>{
        'oldRule': <String, dynamic>{'address': '10.0.0.1', 'strategy': 'accept'},
        'newRule': <String, dynamic>{
          'address': '10.0.0.2',
          'strategy': 'drop',
          'description': 'block',
        },
      });

      expect(request.oldRule.address, '10.0.0.1');
      expect(request.newRule.address, '10.0.0.2');
      expect(request.newRule.strategy, 'drop');
    });
  });

  group('防火墙深度入口', () {
    test('未知启停操作返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.operateFirewall(
        <String, dynamic>{'operation': 'reload'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('operation'));
    });

    test('防火墙操作 dispatch 路由到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'operateFirewall',
        <String, dynamic>{'operation': 'reload'},
      );

      expect(result['success'], isFalse);
    });
  });
}