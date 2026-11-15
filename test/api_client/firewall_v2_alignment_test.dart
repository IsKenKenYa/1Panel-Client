import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/firewall_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/firewall_v2_models.dart';

void main() {
  group('FirewallV2Api v2.5.1 alignment', () {
    late HttpServer server;
    late DioClient client;
    late List<String> requestMethods;
    late List<String> requestPaths;
    late List<Map<String, dynamic>?> requestBodies;
    late Map<String, String> queryParams;
    late Map<String, dynamic> Function(HttpRequest request) responseBuilder;

    setUp(() async {
      requestMethods = <String>[];
      requestPaths = <String>[];
      requestBodies = <Map<String, dynamic>?>[];
      queryParams = <String, String>{};
      responseBuilder =
          (_) => <String, dynamic>{'code': 200, 'data': null};

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestMethods.add(request.method);
        requestPaths.add(request.uri.path);
        queryParams = Map<String, String>.from(request.uri.queryParameters);

        final payload = await utf8.decoder.bind(request).join();
        requestBodies.add(payload.isEmpty
            ? null
            : jsonDecode(payload) as Map<String, dynamic>);

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBuilder(request)));
        await request.response.close();
      });

      client = DioClient(
        baseUrl: 'http://${server.address.host}:${server.port}',
        apiKey: 'test-key',
      );
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('aligns firewall settings and whitelist routes', () async {
      responseBuilder = (HttpRequest request) {
        if (request.uri.path == '/api/v2/hosts/firewall/settings') {
          return <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'ipv6Enabled': true,
              'panelPort': '26314',
              'sshPort': '22',
              'pingStatus': 'ok',
              'portWhiteList': <dynamic>[],
              'system': <String, dynamic>{'backend': 'nftables'},
              'forwarding': <String, dynamic>{'backend': 'iptables'},
              'docker': <String, dynamic>{'backend': 'nftables'},
            },
          };
        }
        return <String, dynamic>{'code': 200, 'data': null};
      };
      final api = FirewallV2Api(client);

      final settings = await api.loadFirewallV2Settings();
      expect(requestMethods.single, 'GET');
      expect(requestPaths.single, '/api/v2/hosts/firewall/settings');
      expect(settings.data?['ipv6Enabled'], isTrue);
      expect(settings.data?['panelPort'], '26314');
      expect(settings.data?['system'], <String, dynamic>{'backend': 'nftables'});

      await api.updateFirewallIPv6(
        const FirewallIPv6Operation(status: 'enable'),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/settings/ipv6');
      expect(requestBodies.last, <String, dynamic>{'status': 'enable'});

      await api.operateFirewallBackend(
        const FirewallBackendOperation(
          backend: 'nftables',
          operation: 'switch',
          subsystem: 'system',
        ),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/settings/operate');
      expect(requestBodies.last, <String, dynamic>{
        'backend': 'nftables',
        'operation': 'switch',
        'subsystem': 'system',
      });

      await api.createFirewallPortWhitelist(
        const FirewallPortWhitelistOperation(
          rule: FirewallPortWhitelistRule(port: '26314', protocol: 'tcp'),
        ),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/settings/whitelist');
      expect(requestBodies.last, <String, dynamic>{
        'rule': <String, dynamic>{'port': '26314', 'protocol': 'tcp'},
      });

      await api.updateFirewallPortWhitelist(
        const FirewallPortWhitelistUpdate(
          oldRule: FirewallPortWhitelistRule(port: '26314', protocol: 'tcp'),
          rule: FirewallPortWhitelistRule(port: '26315', protocol: 'tcp'),
        ),
      );
      expect(requestPaths.last,
          '/api/v2/hosts/firewall/settings/whitelist/update');
      expect(requestBodies.last, <String, dynamic>{
        'oldRule': <String, dynamic>{'port': '26314', 'protocol': 'tcp'},
        'rule': <String, dynamic>{'port': '26315', 'protocol': 'tcp'},
      });

      await api.deleteFirewallPortWhitelist(
        const FirewallPortWhitelistOperation(
          rule: FirewallPortWhitelistRule(port: '26315', protocol: 'tcp'),
        ),
      );
      expect(requestPaths.last,
          '/api/v2/hosts/firewall/settings/whitelist/delete');
      expect(requestBodies.last, <String, dynamic>{
        'rule': <String, dynamic>{'port': '26315', 'protocol': 'tcp'},
      });
    });

    test('aligns unified rule inventory routes', () async {
      responseBuilder = (HttpRequest request) {
        if (request.uri.path == '/api/v2/hosts/firewall/rules/backups') {
          return <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'directory': '/backup/firewall',
              'files': <dynamic>[
                <String, dynamic>{'name': 'rules.json', 'path': '/backup/firewall/rules.json'},
              ],
            },
          };
        }
        if (request.uri.path == '/api/v2/hosts/firewall/rules/search') {
          return <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'total': 1,
              'allTotal': 1,
              'ipv4Range': <String, dynamic>{},
              'ipv6Range': <String, dynamic>{},
              'notices': <dynamic>[],
              'items': <dynamic>[
                <String, dynamic>{'instanceKey': 'rule-1', 'scope': 'system'},
              ],
            },
          };
        }
        if (request.uri.path == '/api/v2/hosts/firewall/rules/native/detail') {
          return <String, dynamic>{'code': 200, 'data': 'chain INPUT ...'};
        }
        return <String, dynamic>{
          'code': 200,
          'data': <String, dynamic>{'queued': true, 'taskID': 'task-1'},
        };
      };
      final api = FirewallV2Api(client);

      final backups = await api.loadFirewallRuleBackups('system');
      expect(requestMethods.last, 'GET');
      expect(requestPaths.last, '/api/v2/hosts/firewall/rules/backups');
      expect(queryParams, <String, String>{'subsystem': 'system'});
      expect(backups.data?['directory'], '/backup/firewall');

      final inventory = await api.searchFirewallRuleInventory(
        const FirewallRuleInventoryRequest(page: 1, pageSize: 10, info: '22'),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/rules/search');
      expect(requestBodies.last, <String, dynamic>{
        'page': 1,
        'pageSize': 10,
        'info': '22',
      });
      expect(inventory.data?['total'], 1);

      await api.createFirewallV2Rules(
        const FirewallRuleCreateRequest(initialize: false),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/rules');
      expect(requestBodies.last, <String, dynamic>{'initialize': false});

      await api.deleteFirewallV2Rules(
        const FirewallRuleDeleteRequest(
          targets: <Map<String, dynamic>>[
            <String, dynamic>{'instanceKey': 'rule-1', 'scope': 'system'},
          ],
        ),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/rules/delete');
      expect(requestBodies.last, <String, dynamic>{
        'targets': <Map<String, dynamic>>[
          <String, dynamic>{'instanceKey': 'rule-1', 'scope': 'system'},
        ],
      });

      await api.updateFirewallV2Rule(
        const FirewallRuleUpdateRequest(
          instanceKey: 'rule-1',
          scope: 'system',
          description: 'new',
        ),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/rules/update');
      expect(requestBodies.last, <String, dynamic>{
        'instanceKey': 'rule-1',
        'scope': 'system',
        'description': 'new',
      });

      await api.reorderFirewallV2Rule(
        const FirewallRuleReorderRequest(
          instanceKey: 'rule-1',
          scope: 'system',
          targetPosition: 2,
        ),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/rules/reorder');
      expect(requestBodies.last, <String, dynamic>{
        'instanceKey': 'rule-1',
        'scope': 'system',
        'targetPosition': 2,
      });

      await api.resetFirewallV2Rules(
        const FirewallRuleResetRequest(subsystem: 'system'),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/rules/reset');
      expect(requestBodies.last, <String, dynamic>{'subsystem': 'system'});

      final native = await api.loadFirewallNativeDetail(
        const FirewallNativeDetailRequest(
          name: 'INPUT',
          nativeKind: 'chain',
          provider: 'nftables',
        ),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/rules/native/detail');
      expect(requestBodies.last, <String, dynamic>{
        'name': 'INPUT',
        'nativeKind': 'chain',
        'provider': 'nftables',
      });
      expect(native.data, 'chain INPUT ...');
    });

    test('aligns forwarding routes', () async {
      final api = FirewallV2Api(client);

      await api.loadFirewallForwardBase();
      expect(requestPaths.last, '/api/v2/hosts/firewall/forward/base');

      await api.enableFirewallForwarding(
        const FirewallForwardEnableRequest(taskID: 'task-forward'),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/forward/enable');
      expect(requestBodies.last, <String, dynamic>{'taskID': 'task-forward'});

      await api.operateFirewallForwardRules(
        const FirewallForwardOperateV2Request(
          rules: <Map<String, dynamic>>[
            <String, dynamic>{'port': '8080', 'targetPort': '80'},
          ],
        ),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/forward/operate');
      expect(requestBodies.last, <String, dynamic>{
        'rules': <Map<String, dynamic>>[
          <String, dynamic>{'port': '8080', 'targetPort': '80'},
        ],
      });

      await api.searchFirewallForwardRules(
        const FirewallForwardSearchRequest(page: 1, pageSize: 10, status: 'all'),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/forward/search');
      expect(requestBodies.last, <String, dynamic>{
        'page': 1,
        'pageSize': 10,
        'status': 'all',
      });
    });

    test('aligns Docker port guard routes', () async {
      responseBuilder = (HttpRequest request) {
        if (request.uri.path == '/api/v2/hosts/firewall/docker/ports') {
          return <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'base': <String, dynamic>{'isActive': true},
              'containers': <dynamic>[],
              'orphanPolicies': <dynamic>[],
            },
          };
        }
        return <String, dynamic>{'code': 200, 'data': null};
      };
      final api = FirewallV2Api(client);

      await api.loadFirewallDockerPorts();
      expect(requestMethods.last, 'GET');
      expect(requestPaths.last, '/api/v2/hosts/firewall/docker/ports');
      final ports = await api.loadFirewallDockerPorts();
      expect(ports.data?['base'], <String, dynamic>{'isActive': true});

      await api.loadFirewallDockerEndpoints();
      expect(requestPaths.last, '/api/v2/hosts/firewall/docker/endpoints');

      await api.operateFirewallDockerGuard(
        const FirewallDockerOperation(operation: 'initialize'),
      );
      expect(requestPaths.last, '/api/v2/hosts/firewall/docker/operate');
      expect(requestBodies.last, <String, dynamic>{'operation': 'initialize'});

      await api.batchUpsertFirewallDockerPolicies(
        const FirewallDockerPolicyBatch(
          policies: <Map<String, dynamic>>[
            <String, dynamic>{'uuid': 'policy-1'},
          ],
        ),
      );
      expect(requestPaths.last,
          '/api/v2/hosts/firewall/docker/policies/batch');
      expect(requestBodies.last, <String, dynamic>{
        'policies': <Map<String, dynamic>>[
          <String, dynamic>{'uuid': 'policy-1'},
        ],
      });

      await api.batchDeleteFirewallDockerPolicies(
        const FirewallDockerPolicyBatchDelete(uuids: <String>['policy-1']),
      );
      expect(requestPaths.last,
          '/api/v2/hosts/firewall/docker/policies/delete/batch');
      expect(requestBodies.last, <String, dynamic>{
        'uuids': <String>['policy-1'],
      });
    });

    test('aligns family operation route', () async {
      final api = FirewallV2Api(client);

      await api.operateFirewallFamily(
        const FirewallFamilyOperation(
          backend: 'nftables',
          family: 'ipv4',
          operation: 'repair',
          subsystem: 'system',
        ),
      );

      expect(requestPaths.single, '/api/v2/hosts/firewall/family/operate');
      expect(requestBodies.single, <String, dynamic>{
        'backend': 'nftables',
        'family': 'ipv4',
        'operation': 'repair',
        'subsystem': 'system',
      });
    });
  });
}
