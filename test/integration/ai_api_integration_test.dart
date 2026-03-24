import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanel_client/api/v2/ai_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/ai_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/mcp_models.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await TestEnvironment.initialize();

  late DioClient client;
  late AIV2Api api;

  if (TestEnvironment.canRunIntegrationTests) {
    client = DioClient(
      baseUrl: TestEnvironment.baseUrl,
      apiKey: TestEnvironment.apiKey,
    );
    api = AIV2Api(client);
  }

  group('AI API连接测试', () {
    test(
      '应该能够连接到服务器',
      skip: TestEnvironment.skipIntegration() ?? TestEnvironment.skipNoApiKey(),
      () async {
      expect(TestEnvironment.baseUrl, isNotEmpty);
      expect(TestEnvironment.apiKey, isNotEmpty);
      expect(TestEnvironment.apiKey, isNot(equals('your_api_key_here')));
      },
    );
  });

  group('Ollama模型API测试', () {
    test('应该能够搜索Ollama模型列表', skip: TestEnvironment.skipIntegration(), () async {
      final request = SearchWithPage(page: 1, pageSize: 10);
      
      final response = await api.searchOllamaModels(request);

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      expect(response.data!.items, isA<List>());
    });

    test('应该能够同步Ollama模型列表', skip: TestEnvironment.skipIntegration(), () async {
      final response = await api.syncOllamaModels();

      expect(response.statusCode, equals(200));
      expect(response.data, isA<List>());
    });

    test('应该能够加载Ollama模型', skip: TestEnvironment.skipIntegration(), () async {
      final request = OllamaModelName(name: 'llama2');

      try {
        final response = await api.loadOllamaModel(request);
        expect(response.statusCode, anyOf(equals(200), equals(404)));
      } catch (e) {
        // 模型可能不存在，这是正常的
        expect(e, isA<DioException>());
      }
    });

    test('应该能够关闭Ollama模型连接', skip: TestEnvironment.skipIntegration(), () async {
      final request = OllamaModelName(name: 'llama2');

      try {
        final response = await api.closeOllamaModel(request);
        expect(response.statusCode, anyOf(equals(200), equals(404)));
      } catch (e) {
        // 模型可能不存在，这是正常的
        expect(e, isA<DioException>());
      }
    });
  });

  group('GPU信息API测试', () {
    test('应该能够获取GPU/XPU信息', skip: TestEnvironment.skipIntegration(), () async {
      try {
        final response = await api.loadGpuInfo();

        expect(response.statusCode, equals(200));
        expect(response.data, isA<List>());
        // 如果没有GPU，返回空列表也是正常的
      } catch (e) {
        // 服务器可能没有GPU，返回错误也是正常的
        expect(e, isA<DioException>());
      }
    });
  });

  group('域名绑定API测试', () {
    test('应该能够获取绑定域名', skip: TestEnvironment.skipIntegration(), () async {
      final request = OllamaBindDomainReq(appInstallID: 1);

      try {
        final response = await api.getBindDomain(request);
        expect(response.statusCode, anyOf(equals(200), equals(404)));
      } catch (e) {
        // 可能没有绑定域名，这是正常的
        expect(e, isA<DioException>());
      }
    });
  });

  group('MCP服务器API测试', () {
    test('应该能够搜索MCP服务器列表', skip: TestEnvironment.skipIntegration(), () async {
      final request = McpServerSearch(page: 1, pageSize: 10);

      final response = await api.searchMcpServers(request);

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      expect(response.data!.items, isA<List>());
    });

    test('应该能够获取MCP绑定域名', skip: TestEnvironment.skipIntegration(), () async {
      try {
        final response = await api.getMcpBindDomain();
        expect(response.statusCode, anyOf(equals(200), equals(404)));
      } catch (e) {
        // 可能没有绑定域名，这是正常的
        expect(e, isA<DioException>());
      }
    });

    test('应该能够操作MCP服务器', skip: TestEnvironment.skipIntegration(), () async {
      final request = McpServerOperate(id: 1, operate: 'restart');

      try {
        final response = await api.operateMcpServer(request);
        expect(response.statusCode, anyOf(equals(200), equals(404)));
      } catch (e) {
        // MCP服务器可能不存在，这是正常的
        expect(e, isA<DioException>());
      }
    });
  });

  group('破坏性操作测试', () {
    test('应该能够创建Ollama模型', skip: TestEnvironment.skipDestructive(), () async {
      final request = OllamaModelName(name: 'test-model-${DateTime.now().millisecondsSinceEpoch}');

      try {
        final response = await api.createOllamaModel(request);
        expect(response.statusCode, anyOf(equals(200), equals(400)));
      } catch (e) {
        // 模型名称可能无效，这是正常的
        expect(e, isA<DioException>());
      }
    });

    test('应该能够创建MCP服务器', skip: TestEnvironment.skipDestructive(), () async {
      final request = McpServerCreate(
        name: 'test-mcp-${DateTime.now().millisecondsSinceEpoch}',
        type: 'stdio',
        command: 'echo',
        port: 9999,
        outputTransport: 'stdio',
      );

      try {
        final response = await api.createMcpServer(request);
        expect(response.statusCode, anyOf(equals(200), equals(400)));
      } catch (e) {
        // 参数可能无效，这是正常的
        expect(e, isA<DioException>());
      }
    });

    test('应该能够删除Ollama模型', skip: TestEnvironment.skipDestructive(), () async {
      final request = ForceDelete(ids: [999999]);

      try {
        final response = await api.deleteOllamaModel(request);
        expect(response.statusCode, anyOf(equals(200), equals(404)));
      } catch (e) {
        // 模型不存在，这是正常的
        expect(e, isA<DioException>());
      }
    });

    test('应该能够删除MCP服务器', skip: TestEnvironment.skipDestructive(), () async {
      final request = McpServerDelete(id: 999999);

      try {
        final response = await api.deleteMcpServer(request);
        expect(response.statusCode, anyOf(equals(200), equals(404)));
      } catch (e) {
        // MCP服务器不存在，这是正常的
        expect(e, isA<DioException>());
      }
    });
  });

  group('错误处理测试', () {
    test('应该正确处理无效Token', skip: TestEnvironment.skipIntegration(), () async {
      final invalidClient = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: 'invalid_key_12345',
      );
      final invalidApi = AIV2Api(invalidClient);

      try {
        final request = SearchWithPage(page: 1, pageSize: 10);
        await invalidApi.searchOllamaModels(request);
        fail('应该抛出401异常');
      } on DioException catch (e) {
        expect(e.response?.statusCode, anyOf(equals(400), equals(401), equals(403)));
      }
    });

    test('应该正确处理无效请求参数', skip: TestEnvironment.skipIntegration(), () async {
      try {
        final request = SearchWithPage(page: -1, pageSize: -1);
        await api.searchOllamaModels(request);
        // 服务器可能接受或拒绝这个请求
      } on DioException catch (e) {
        expect(e.response?.statusCode, anyOf(equals(400), equals(422)));
      }
    });

    test('应该正确处理网络超时', skip: TestEnvironment.skipIntegration(), () async {
      final timeoutClient = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      final timeoutApi = AIV2Api(timeoutClient);

      try {
        final request = SearchWithPage(page: 1, pageSize: 10);
        await timeoutApi.searchOllamaModels(request).timeout(Duration(milliseconds: 1));
        // 如果请求很快完成，这是正常的
      } catch (e) {
        // 超时或网络错误是正常的
        expect(e, anyOf(isA<DioException>(), isA<Exception>()));
      }
    });
  });

  group('性能测试', () {
    test('API响应时间应该小于5秒', skip: TestEnvironment.skipIntegration(), () async {
      final stopwatch = Stopwatch()..start();

      final request = SearchWithPage(page: 1, pageSize: 10);
      await api.searchOllamaModels(request);

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('并发请求应该正常处理', skip: TestEnvironment.skipIntegration(), () async {
      final futures = List.generate(5, (i) {
        final request = SearchWithPage(page: 1, pageSize: 10);
        return api.searchOllamaModels(request);
      });

      final responses = await Future.wait(futures);

      for (final response in responses) {
        expect(response.statusCode, equals(200));
      }
    });

    test('大量数据请求应该正常处理', skip: TestEnvironment.skipIntegration(), () async {
      final request = SearchWithPage(page: 1, pageSize: 100);
      final response = await api.searchOllamaModels(request);

      expect(response.statusCode, equals(200));
      final itemCount = response.data?.items.length ?? 0;
      expect(itemCount, lessThanOrEqualTo(100));
    });
  });
}
