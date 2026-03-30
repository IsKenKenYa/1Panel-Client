import 'package:flutter_test/flutter_test.dart';
import '../test_helper.dart';
import 'package:onepanel_client/api/v2/ai_v2.dart';
import 'package:onepanel_client/api/v2/command_v2.dart';
import 'package:onepanel_client/api/v2/toolbox_v2.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/mcp_models.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await setupTestEnvironment();

  late final TestApiClient apiClient;
  late final ToolboxV2Api toolboxApi;
  late final CommandV2Api commandApi;
  late final AIV2Api aiApi;

  final hasApiKey = SkipConditions.skipNoApiKey() == null;
  if (hasApiKey) {
    apiClient = TestApiClient(
      baseUrl: TestConfig.baseUrl,
      apiKey: TestConfig.apiKey,
    );
    toolboxApi = ToolboxV2Api(apiClient.client);
    commandApi = CommandV2Api(apiClient.client);
    aiApi = AIV2Api(apiClient.client);
  }

  tearDownAll(() async {
    if (hasApiKey) {
      apiClient.dispose();
    }
    await teardownTestEnvironment();
  });

  group('API连接测试', () {
    test(
      '应该能够连接到服务器',
      skip: SkipConditions.skipIntegration() ?? SkipConditions.skipNoApiKey(),
      () async {
        final response = await apiClient.authenticatedGet('/api/v2/health');
        expect(response.statusCode, anyOf(equals(200), equals(404)));
      },
    );

    test(
      '认证应该成功',
      skip: SkipConditions.skipIntegration() ?? SkipConditions.skipNoApiKey(),
      () async {
        final headers = TokenGenerator.generateAuthHeaders(TestConfig.apiKey);
        expect(headers.containsKey('1Panel-Token'), isTrue);
        expect(headers.containsKey('1Panel-Timestamp'), isTrue);
        expect(TokenGenerator.validateTokenFormat(headers['1Panel-Token']!),
            isTrue);
      },
    );
  });

  group('Toolbox API集成测试', () {
    test('应该能够获取设备基础信息', skip: SkipConditions.skipIntegration(), () async {
      final response = await toolboxApi.getDeviceBaseInfo();

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
    });

    test('应该能够获取Fail2ban基础信息', skip: SkipConditions.skipIntegration(),
        () async {
      final response = await toolboxApi.getFail2banBaseInfo();

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
    });

    test('应该能够获取FTP基础信息', skip: SkipConditions.skipIntegration(), () async {
      final response = await toolboxApi.getFtpBaseInfo();

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
    });

    test('应该能够获取清理数据列表', skip: SkipConditions.skipIntegration(), () async {
      final response = await toolboxApi.getCleanData();

      expect(response.statusCode, equals(200));
      expect(response.data, isA<List>());
    });

    test('应该能够获取清理树形结构', skip: SkipConditions.skipIntegration(), () async {
      final response = await toolboxApi.getCleanTree();

      expect(response.statusCode, equals(200));
      expect(response.data, isA<List>());
    });

    test('应该能够获取设备用户列表', skip: SkipConditions.skipIntegration(), () async {
      final response = await toolboxApi.getDeviceUsers();

      expect(response.statusCode, equals(200));
      expect(response.data, isA<List>());
    });

    test('应该能够获取时区选项', skip: SkipConditions.skipIntegration(), () async {
      final response = await toolboxApi.getDeviceZoneOptions();

      expect(response.statusCode, equals(200));
      expect(response.data, isA<List>());
    });

    test('应该能够搜索Clam扫描任务', skip: SkipConditions.skipIntegration(), () async {
      final request = PageRequest(page: 1, pageSize: 10);
      final response = await toolboxApi.searchClam(request);

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
    });

    test('应该能够搜索FTP账户', skip: SkipConditions.skipIntegration(), () async {
      final request = FtpSearch(page: 1, pageSize: 10);
      final response = await toolboxApi.searchFtp(request);

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
    });

    test('应该能够搜索Fail2ban记录', skip: SkipConditions.skipIntegration(), () async {
      final request = Fail2banSearch(page: 1, pageSize: 10);
      final response = await toolboxApi.searchFail2ban(request);

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
    });
  });

  group('Command API集成测试', () {
    test('应该能够获取命令树', skip: SkipConditions.skipIntegration(), () async {
      final response = await commandApi.getCommandTree();

      expect(response.statusCode, equals(200));
      expect(response.data, isA<List>());
    });

    test('应该能够获取命令列表', skip: SkipConditions.skipIntegration(), () async {
      final response = await commandApi.listCommands();

      expect(response.statusCode, equals(200));
      expect(response.data, isA<List>());
    });

    test('应该能够搜索命令', skip: SkipConditions.skipIntegration(), () async {
      final request = PageRequest(page: 1, pageSize: 10);
      final response = await commandApi.searchCommand(request);

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
    });

    test('应该能够搜索脚本', skip: SkipConditions.skipIntegration(), () async {
      final request = PageRequest(page: 1, pageSize: 10);
      final response = await commandApi.searchScript(request);

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
    });

    test('应该能够获取脚本选项', skip: SkipConditions.skipIntegration(), () async {
      final response = await commandApi.getScriptOptions();

      expect(response.statusCode, equals(200));
      expect(response.data, isA<List>());
    });
  });

  group('MCP Server API集成测试', () {
    test('应该能够搜索MCP服务器', skip: SkipConditions.skipIntegration(), () async {
      final request = McpServerSearch(page: 1, pageSize: 10);
      final response = await aiApi.searchMcpServers(request);

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
    });

    test('应该能够获取MCP绑定域名', skip: SkipConditions.skipIntegration(), () async {
      final response = await aiApi.getMcpBindDomain();

      // 可能没有绑定域名，所以接受200或404
      expect(response.statusCode, anyOf(equals(200), equals(404)));
    });
  });

  group('API错误处理测试', () {
    test('应该处理无效Token',
        skip: SkipConditions.skipIntegration() ?? SkipConditions.skipNoApiKey(),
        () async {
      final invalidClient = TestApiClient(
        baseUrl: TestConfig.baseUrl,
        apiKey: 'invalid_key',
      );

      try {
        await invalidClient.authenticatedGet('/api/v2/dashboard/base');
        fail('应该抛出异常');
      } catch (e) {
        expect(e, isA<Exception>());
      } finally {
        invalidClient.dispose();
      }
    });

    test(
      '应该处理无效路径',
      skip: SkipConditions.skipIntegration() ?? SkipConditions.skipNoApiKey(),
      () async {
        try {
          await apiClient.authenticatedGet('/api/v2/invalid/path');
          fail('应该抛出异常');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      },
    );
  });

  group('API性能测试', () {
    test('API响应时间应该小于5秒', skip: SkipConditions.skipIntegration(), () async {
      final stopwatch = Stopwatch()..start();

      await toolboxApi.getDeviceBaseInfo();

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('并发请求应该正常处理', skip: SkipConditions.skipIntegration(), () async {
      final futures = [
        toolboxApi.getDeviceBaseInfo(),
        toolboxApi.getFail2banBaseInfo(),
        toolboxApi.getFtpBaseInfo(),
      ];

      final responses = await Future.wait(futures);

      for (final response in responses) {
        expect(response.statusCode, equals(200));
      }
    });
  });
}
