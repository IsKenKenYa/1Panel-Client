import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/ai_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/ai/agent_models.dart';

void main() {
  group('AIV2Api alignment', () {
    late HttpServer server;
    late DioClient client;
    late Map<String, dynamic>? requestBody;
    late String requestMethod;
    late String requestPath;
    late Map<String, dynamic> Function() responseBuilder;

    setUp(() async {
      requestBody = null;
      requestMethod = '';
      requestPath = '';
      responseBuilder = () => <String, dynamic>{'code': 200, 'data': null};

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestMethod = request.method;
        requestPath = request.uri.path;

        final payload = await utf8.decoder.bind(request).join();
        requestBody = payload.isEmpty
            ? null
            : jsonDecode(payload) as Map<String, dynamic>;

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBuilder()));
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

    test('aligns /ai/agents/browser/get route and parses payload', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'enabled': true,
              'executablePath': '/usr/bin/chromium-browser',
              'defaultProfile': 'default',
              'headless': true,
              'noSandbox': false,
            },
          };

      final api = AIV2Api(client);
      final response = await api.getAgentBrowserConfig(
        const AgentBrowserConfigReq(agentId: 11),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/ai/agents/browser/get');
      expect(requestBody, <String, dynamic>{'agentId': 11});
      expect(response.data?.enabled, isTrue);
      expect(response.data?.defaultProfile, 'default');
      expect(response.data?.executablePath, '/usr/bin/chromium-browser');
    });

    test('aligns /ai/agents/browser/update route and payload', () async {
      final api = AIV2Api(client);
      await api.updateAgentBrowserConfig(
        const AgentBrowserConfigUpdateReq(
          agentId: 11,
          defaultProfile: 'work',
          enabled: true,
          headless: false,
          noSandbox: true,
        ),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/ai/agents/browser/update');
      expect(requestBody, <String, dynamic>{
        'agentId': 11,
        'defaultProfile': 'work',
        'enabled': true,
        'headless': false,
        'noSandbox': true,
      });
    });

    test('aligns /ai/agents/channel/feishu/approve route and payload',
        () async {
      final api = AIV2Api(client);
      await api.approveAgentFeishuPairing(
        const AgentFeishuPairingApproveReq(
          agentId: 11,
          pairingCode: 'PAIR-1234',
        ),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/ai/agents/channel/feishu/approve');
      expect(requestBody, <String, dynamic>{
        'agentId': 11,
        'pairingCode': 'PAIR-1234',
      });
    });

    test('aligns /ai/agents/agent/* routes and parses wrapped payloads',
        () async {
      final api = AIV2Api(client);

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{'output': 'created-role'},
          };
      final createResp = await api.createAgentRole(
        const AgentRoleCreateReq(
          agentId: 11,
          name: 'oncall',
          model: 'gpt-4',
          bindings: <AgentRoleBinding>[
            AgentRoleBinding(channel: 'telegram', accountId: 'acc-1'),
          ],
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/ai/agents/agent/create');
      expect(requestBody, <String, dynamic>{
        'agentId': 11,
        'name': 'oncall',
        'model': 'gpt-4',
        'bindings': <Map<String, dynamic>>[
          <String, dynamic>{'channel': 'telegram', 'accountId': 'acc-1'},
        ],
      });
      expect(createResp.data?.output, 'created-role');

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'telegram',
                'bound': true,
                'accountIds': <String>['acc-1'],
              },
            ],
          };
      final channels = await api
          .getAgentRoleChannels(const AgentRoleChannelsReq(agentId: 11));
      expect(requestPath, '/api/v2/ai/agents/agent/channels');
      expect(requestBody, <String, dynamic>{'agentId': 11});
      expect(channels.data?.first.bound, isTrue);

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'role-1',
                'name': 'oncall',
                'workspace': 'team-alpha',
                'bindings': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'channel': 'telegram',
                    'accountId': 'acc-1'
                  },
                ],
              },
            ],
          };
      final roles =
          await api.listAgentRoles(const AgentConfiguredAgentsReq(agentId: 11));
      expect(requestPath, '/api/v2/ai/agents/agent/list');
      expect(requestBody, <String, dynamic>{'agentId': 11});
      expect(roles.data?.first.id, 'role-1');

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'AGENTS.md', 'content': '# role'},
            ],
          };
      final markdownFiles = await api.listAgentRoleMarkdownFiles(
        const AgentRoleMarkdownFilesReq(agentId: 11, workspace: 'team-alpha'),
      );
      expect(requestPath, '/api/v2/ai/agents/agent/md/list');
      expect(requestBody, <String, dynamic>{
        'agentId': 11,
        'workspace': 'team-alpha',
      });
      expect(markdownFiles.data?.first.name, 'AGENTS.md');

      await api.updateAgentRoleMarkdownFiles(
        const AgentRoleMarkdownFilesUpdateReq(
          agentId: 11,
          workspace: 'team-alpha',
          files: <AgentRoleMarkdownFileUpdateItem>[
            AgentRoleMarkdownFileUpdateItem(
                name: 'AGENTS.md', content: '# next'),
          ],
          restart: true,
        ),
      );
      expect(requestPath, '/api/v2/ai/agents/agent/md/update');
      expect(requestBody, <String, dynamic>{
        'agentId': 11,
        'workspace': 'team-alpha',
        'files': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'AGENTS.md', 'content': '# next'},
        ],
        'restart': true,
      });

      await api.bindAgentRoleChannel(
        const AgentRoleBindReq(
          agentId: 11,
          channel: 'telegram',
          id: 'role-1',
          accountId: 'acc-1',
        ),
      );
      expect(requestPath, '/api/v2/ai/agents/agent/bind');
      expect(requestBody, <String, dynamic>{
        'agentId': 11,
        'channel': 'telegram',
        'id': 'role-1',
        'accountId': 'acc-1',
      });

      await api.unbindAgentRoleChannel(
        const AgentRoleBindReq(
          agentId: 11,
          channel: 'telegram',
          id: 'role-1',
        ),
      );
      expect(requestPath, '/api/v2/ai/agents/agent/unbind');
      expect(requestBody, <String, dynamic>{
        'agentId': 11,
        'channel': 'telegram',
        'id': 'role-1',
      });

      await api.deleteAgentRole(
        const AgentRoleDeleteReq(agentId: 11, id: 'role-1'),
      );
      expect(requestPath, '/api/v2/ai/agents/agent/delete');
      expect(requestBody, <String, dynamic>{'agentId': 11, 'id': 'role-1'});
    });

    test(
        'aligns model/plugin/remark/website routes and parses /ai/agents/model/get payload',
        () async {
      final api = AIV2Api(client);

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'accountId': 7,
              'model': 'gpt-4.1-mini',
              'fallbacks': <String>['gpt-4o-mini'],
            },
          };
      final modelResp =
          await api.getAgentModelConfig(const AgentIdReq(agentId: 11));
      expect(requestPath, '/api/v2/ai/agents/model/get');
      expect(requestBody, <String, dynamic>{'agentId': 11});
      expect(modelResp.data?.accountId, 7);
      expect(modelResp.data?.model, 'gpt-4.1-mini');
      expect(modelResp.data?.fallbacks, <String>['gpt-4o-mini']);

      await api.uninstallAgentPlugin(
        const AgentPluginUninstallReq(
            agentId: 11, type: 'browser', taskID: 'task-1'),
      );
      expect(requestPath, '/api/v2/ai/agents/plugin/uninstall');
      expect(requestBody, <String, dynamic>{
        'agentId': 11,
        'type': 'browser',
        'taskID': 'task-1',
      });

      await api.upgradeAgentPlugin(
        const AgentPluginUpgradeReq(
            agentId: 11, type: 'browser', taskID: 'task-2'),
      );
      expect(requestPath, '/api/v2/ai/agents/plugin/upgrade');
      expect(requestBody, <String, dynamic>{
        'agentId': 11,
        'type': 'browser',
        'taskID': 'task-2',
      });

      await api.updateAgentRemark(
          const AgentRemarkUpdateReq(id: 11, remark: 'edge'));
      expect(requestPath, '/api/v2/ai/agents/remark');
      expect(requestBody, <String, dynamic>{'id': 11, 'remark': 'edge'});

      await api.bindAgentWebsite(
        const AgentWebsiteBindReq(agentId: 11, websiteId: 22),
      );
      expect(requestPath, '/api/v2/ai/agents/website/bind');
      expect(requestBody, <String, dynamic>{'agentId': 11, 'websiteId': 22});
    });
  });
}
