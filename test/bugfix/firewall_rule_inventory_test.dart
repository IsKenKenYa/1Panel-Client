import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';
import 'package:onepanel_client/data/models/firewall_v2_models.dart';
import 'package:onepanel_client/features/firewall/firewall_service.dart';

void main() {
  test('iptables inventory requests both families and the managed chains', () {
    final request = FirewallRuleInventoryRequest.forSearch(
      const FirewallRuleSearch(
        page: 2,
        pageSize: 5,
        type: 'port',
        info: '8080',
        strategy: 'drop',
      ),
      provider: 'iptables',
    ).toJson();

    expect(request['all'], isTrue);
    expect(request['info'], '8080');
    expect(request['actions'], ['deny']);
    final scopes = request['scopes'] as List<Map<String, dynamic>>;
    expect(scopes, hasLength(6));
    expect(scopes.map((scope) => scope['family']).toSet(), {'ipv4', 'ipv6'});
    expect(scopes.map((scope) => scope['chain']).toSet(), {
      '1PANEL_BASIC_BEFORE',
      '1PANEL_BASIC',
      '1PANEL_BASIC_AFTER',
    });
    expect(scopes.map((scope) => scope['table']).toSet(), {'filter'});
    expect(scopes.map((scope) => scope['direction']).toSet(), {'input'});
  });

  test('firewalld and UFW use their combined input scopes', () {
    const search = FirewallRuleSearch(page: 2, pageSize: 10);
    final firewalld = FirewallRuleInventoryRequest.forSearch(
      search,
      provider: 'firewalld',
    ).toJson();
    expect(firewalld['all'], isNull);
    expect(firewalld['page'], 2);
    expect(firewalld['pageSize'], 10);
    expect(firewalld['scopes'], [
      {
        'provider': 'firewalld',
        'family': 'inet',
        'zone': 'public',
        'direction': 'input',
      }
    ]);

    final ufw = FirewallRuleInventoryRequest.forSearch(
      search,
      provider: 'ufw',
    ).toJson();
    expect(ufw['scopes'], [
      {
        'provider': 'ufw',
        'family': 'inet',
        'chain': 'incoming',
        'direction': 'input',
      }
    ]);
  });

  test('port and address pages are filtered before taking a page', () {
    final inventory = FirewallRuleInventoryResponse.fromJson({
      'total': 3,
      'items': [
        {
          'rule': {
            'destinationPort': '80',
            'protocol': 'tcp',
            'action': 'accept',
          },
          'observed': {'instanceKey': 'port-80'},
        },
        {
          'rule': {
            'scope': {'family': 'ipv6', 'chain': '1PANEL_BASIC'},
            'sourceAddress': '2001:db8::/32',
            'protocol': 'all',
            'action': 'drop',
            'description': 'Blocked subnet',
          },
          'observed': {'instanceKey': 'blocked-ipv6'},
        },
        {
          'rule': {
            'uuid': 'managed-rule',
            'destinationPort': '443',
            'protocol': 'tcp',
            'action': 'accept',
          },
        },
      ],
    });

    final ports = inventory.pageFor(
      const FirewallRuleSearch(type: 'port', page: 2, pageSize: 1),
    );
    expect(ports.total, 2);
    expect(ports.totalPages, 2);
    expect(ports.items.single.port, '443');
    expect(ports.items.single.inventoryId, 'managed-rule');
    expect(ports.items.single.supportsLegacyChanges, isFalse);
    expect(ports.items.single.id, isNull);

    final ips = inventory.pageFor(const FirewallRuleSearch(type: 'address'));
    expect(ips.total, 1);
    final ip = ips.items.single;
    expect(ip.address, '2001:db8::/32');
    expect(ip.strategy, 'drop');
    expect(ip.family, 'ipv6');
    expect(ip.inventoryId, 'blocked-ipv6');
    expect(ip.description, 'Blocked subnet');

    final empty = inventory.pageFor(
      const FirewallRuleSearch(type: 'address', page: 2, pageSize: 1),
    );
    expect(empty.items, isEmpty);
    expect(empty.total, 1);
  });

  test('legacy rule JSON keeps its numeric ID and action support', () {
    final rule = FirewallRule.fromJson({'id': 42, 'port': '443'});
    expect(rule.id, 42);
    expect(rule.inventoryId, isNull);
    expect(rule.supportsLegacyChanges, isTrue);
  });

  test('current inventory deletion retains the original observed rule', () {
    final scope = {
      'provider': 'iptables',
      'family': 'ipv6',
      'table': 'filter',
      'chain': '1PANEL_BASIC',
      'direction': 'input',
    };
    final observedRule = {
      'scope': scope,
      'sourceAddress': '2001:db8::/32',
      'destinationPort': '443',
      'protocol': 'tcp',
      'action': 'accept',
    };
    final observed = {
      'rule': observedRule,
      'instanceKey': 'ipv6-443',
      'protected': false,
      'parseStatus': 'supported',
      'locator': {'provider': 'iptables', 'position': 2},
    };
    final inventory = FirewallRuleInventoryResponse.fromJson({
      'total': 3,
      'items': [
        for (final (whitelist, protected) in [
          (false, false),
          (true, false),
          (false, true),
        ])
          {
            'rule': {...observedRule, 'description': 'Current description'},
            'observed': {...observed, 'protected': protected},
            'isWhitelist': whitelist,
            'descriptionID': '',
          },
      ],
    }, serverId: 'panel-a');
    final rule = inventory.items.first;
    expect(rule.serverId, 'panel-a');
    expect(rule.inventoryId, 'ipv6-443');
    expect(rule.canDelete, isTrue);
    expect(inventory.items.skip(1).map((item) => item.canDelete),
        everyElement(isFalse));
    final request = FirewallRuleDeleteRequest(
      targets: [rule.modernTarget!.toJson()],
    );
    expect(request.toJson(), {
      'targets': [
        {'scope': scope, 'instanceKey': 'ipv6-443', 'observed': observed},
      ],
    });
  });

  test('2.3 inventory deletes an exact managed match by desired UUID', () {
    final inventory = FirewallRuleInventoryResponse.fromJson({
      'total': 4,
      'items': [
        for (final (state, match, expanded) in [
          ('adopted', 'exact', false),
          ('managed', 'changed', false),
          ('managed', 'exact', true),
          ('external', 'exact', false),
        ])
          {
            'rule': {'destinationPort': '443'},
            'observed': {'instanceKey': 'observed-443', 'protected': false},
            'state': state,
            'match': match,
            'desired': {'uuid': 'managed-443', 'expanded': expanded},
          },
      ],
    }, serverId: 'panel-a');
    final rule = inventory.items.first;
    expect(rule.inventoryId, 'observed-443');
    expect(rule.canDelete, isTrue);
    final request =
        FirewallRuleDeleteRequest.managed([rule.modernTarget!.uuid!]);
    expect(request.toJson(), {
      'uuids': ['managed-443']
    });
    expect(inventory.items.skip(1).map((item) => item.canDelete),
        everyElement(isFalse));
  });

  test('firewall deletion rejects duplicate or mixed-server selections',
      () async {
    const target = FirewallInventoryDeletionTarget.managed('managed');
    const first = FirewallRule(
      inventoryId: 'observed',
      serverId: 'panel-a',
      supportsLegacyChanges: false,
      modernTarget: target,
    );
    const second = FirewallRule(
      inventoryId: 'observed',
      serverId: 'panel-b',
      supportsLegacyChanges: false,
      modernTarget: target,
    );
    final service = FirewallService();
    await expectLater(
        service.deleteInventoryRules([first, first]), throwsArgumentError);
    await expectLater(
        service.deleteInventoryRules([first, second]), throwsStateError);
  });

  test('native firewall deletion requires an inventory and a server ID',
      () async {
    final channel = NativeChannelManager.instance;
    for (final arguments in [
      {'inventoryId': 'rule-1'},
      {'inventoryId': '', 'serverId': 'panel-a'},
      {'inventoryId': null, 'serverId': 'panel-a', 'port': '443'},
    ]) {
      final result = await channel.handleMethodCall(
        'deleteFirewallRule',
        arguments,
      );
      expect(result, containsPair('success', false));
      expect(result,
          containsPair('error', contains('Invalid firewall inventory')));
    }
  });

  test('an empty modern inventory still identifies the newer API', () {
    final inventory = FirewallRuleInventoryResponse.fromJson({
      'total': 0,
      'items': <Object>[],
    });
    final PageResult<FirewallRule> page =
        inventory.pageFor(const FirewallRuleSearch());
    expect(page, isA<FirewallInventoryPageResult>());
    expect(page.items, isEmpty);
  });

  test('UFW all-protocol port inventory uses the TCP and UDP label', () {
    final inventory = FirewallRuleInventoryResponse.fromJson({
      'total': 1,
      'items': [
        {
          'rule': {
            'scope': {'provider': 'ufw'},
            'destinationPort': '443',
            'protocol': 'all',
            'action': 'accept',
          },
        },
      ],
    });
    final page = inventory.pageFor(const FirewallRuleSearch(type: 'port'));
    expect(page.items.single.protocol, 'tcp/udp');
  });
}
