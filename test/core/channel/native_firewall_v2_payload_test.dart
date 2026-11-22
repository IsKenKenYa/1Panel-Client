import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_firewall_payloads.dart';

void main() {
  group('防火墙 V2 读载荷', () {
    test('转发分区保留基础信息并附结构化规则', () {
      final payload = firewallForwardPayload(
        <String, dynamic>{'name': 'forward', 'isActive': true},
        <String, dynamic>{
          'items': <dynamic>[
            <String, dynamic>{
              'id': 7,
              'port': '8080',
              'protocol': 'tcp',
              'targetIP': '10.0.0.2',
              'targetPort': '80',
              'strategy': 'accept',
              'isDesired': true,
            },
            <String, dynamic>{
              'port': '9090',
              'protocol': 'udp',
              'targetPort': '90',
            },
          ],
          'total': 2,
        },
      );

      expect(payload['name'], 'forward');
      expect(payload['isActive'], 'true');
      expect(payload['total'], 2);
      final rules = payload['rules'] as List;
      expect(rules, hasLength(2));
      expect((rules.first as Map)['id'], 7);
      expect((rules.first as Map)['targetIP'], '10.0.0.2');
      expect((rules.first as Map)['isDesired'], isTrue);
      expect((rules.last as Map)['id'], 'row-1');
      expect((rules.last as Map)['protocol'], 'udp');
    });

    test('转发分区在缺少总数时使用规则数量', () {
      final payload = firewallForwardPayload(
        <String, dynamic>{},
        <String, dynamic>{
          'items': <dynamic>[
            <String, dynamic>{'id': 1, 'port': '80', 'protocol': 'tcp'},
          ],
        },
      );

      expect(payload['total'], 1);
    });

    test('Docker 分区按策略标识去重并汇总发布端口', () {
      final payload = firewallDockerPayload(
        <String, dynamic>{
          'base': <String, dynamic>{'name': 'docker', 'bound': true},
          'containers': <dynamic>[
            <String, dynamic>{
              'name': 'web',
              'endpoints': <dynamic>[
                <String, dynamic>{
                  'policyUUID': 'policy-a',
                  'hostIP': '0.0.0.0',
                  'hostPort': 8080,
                  'containerPort': 80,
                  'protocol': 'tcp',
                  'family': 'ipv4',
                  'mode': 'deny_sources',
                  'sources': <dynamic>['10.0.0.0/8'],
                  'containerName': 'web',
                  'effective': true,
                },
                <String, dynamic>{
                  'policyUUID': 'policy-a',
                  'hostIP': '0.0.0.0',
                  'hostPort': 8080,
                  'protocol': 'tcp',
                  'family': 'ipv4',
                  'containerName': 'web',
                },
              ],
            },
          ],
          'orphanPolicies': <dynamic>[
            <String, dynamic>{
              'policyUUID': 'policy-b',
              'hostIP': '::',
              'hostPort': 8443,
              'protocol': 'tcp',
              'family': 'ipv6',
              'mode': 'accept_all',
            },
          ],
        },
        const <dynamic>[],
      );

      expect(payload['name'], 'docker');
      expect(payload['bound'], 'true');
      final policies = payload['policies'] as List;
      expect(policies, hasLength(2));
      expect((policies.first as Map)['id'], 'policy-a');
      expect((policies.first as Map)['sources'], <String>['10.0.0.0/8']);
      expect((policies.last as Map)['id'], 'policy-b');
      final published = payload['publishedPorts'] as List;
      expect(published, hasLength(2));
      expect((published.first as Map)['containerName'], 'web');
    });

    test('Docker 分区在无容器载荷时使用发布端口列表', () {
      final payload = firewallDockerPayload(
        <String, dynamic>{'base': <String, dynamic>{}},
        <dynamic>[
          <String, dynamic>{
            'name': 'api',
            'endpoints': <dynamic>[
              <String, dynamic>{
                'policyUUID': 'policy-c',
                'hostIP': '127.0.0.1',
                'hostPort': 3000,
                'protocol': 'tcp',
                'family': 'ipv4',
                'mode': 'allow_sources',
              },
            ],
          },
        ],
      );

      final policies = payload['policies'] as List;
      expect(policies, hasLength(1));
      expect((policies.first as Map)['id'], 'policy-c');
      expect((policies.first as Map)['mode'], 'allow_sources');
    });

    test('设置分区附端口白名单与后端分组', () {
      final payload = firewallSettingsPayload(<String, dynamic>{
        'ipv6Enabled': true,
        'panelPort': '20450',
        'portWhiteList': <dynamic>[
          <String, dynamic>{
            'port': '20450',
            'protocol': 'tcp',
            'sources': <dynamic>['0.0.0.0/0'],
          },
        ],
        'system': <String, dynamic>{
          'selected': 'firewalld',
          'current': 'firewalld',
          'options': <dynamic>[
            <String, dynamic>{
              'name': 'firewalld',
              'installed': true,
              'active': true,
              'supported': true,
            },
          ],
        },
        'forwarding': <String, dynamic>{
          'selected': 'iptables',
          'options': <dynamic>[
            <String, dynamic>{'name': 'iptables', 'installed': true},
          ],
        },
      });

      expect(payload['ipv6Enabled'], 'true');
      final whitelist = payload['whitelist'] as List;
      expect(whitelist, hasLength(1));
      expect((whitelist.first as Map)['id'], 'whitelist-0');
      expect((whitelist.first as Map)['sources'], <String>['0.0.0.0/0']);
      final backends = payload['backends'] as List;
      expect(backends, hasLength(2));
      expect((backends.first as Map)['subsystem'], 'system');
      final options = (backends.first as Map)['options'] as List;
      expect((options.first as Map)['name'], 'firewalld');
      expect((options.first as Map)['active'], isTrue);
      expect((backends.last as Map)['selected'], 'iptables');
    });
  });
}