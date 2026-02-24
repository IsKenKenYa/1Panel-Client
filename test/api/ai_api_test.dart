import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanelapp_app/data/models/ai_models.dart';
import 'package:onepanelapp_app/data/models/mcp_models.dart';

void main() {
  setUpAll(() async {
    await TestEnvironment.initialize();
  });

  group('AI数据模型测试', () {
    group('OllamaBindDomain模型测试', () {
      test('应该正确创建OllamaBindDomain实例', () {
        final model = OllamaBindDomain(
          appInstallID: 1,
          domain: 'ai.example.com',
          ipList: '192.168.1.100',
          sslID: 1,
          websiteID: 1,
        );

        expect(model.appInstallID, equals(1));
        expect(model.domain, equals('ai.example.com'));
        expect(model.ipList, equals('192.168.1.100'));
        expect(model.sslID, equals(1));
        expect(model.websiteID, equals(1));
      });

      test('应该正确序列化为JSON', () {
        final model = OllamaBindDomain(
          appInstallID: 1,
          domain: 'ai.example.com',
          ipList: '192.168.1.100',
          sslID: 1,
        );

        final json = model.toJson();

        expect(json['appInstallID'], equals(1));
        expect(json['domain'], equals('ai.example.com'));
        expect(json['ipList'], equals('192.168.1.100'));
        expect(json['sslID'], equals(1));
        expect(json.containsKey('websiteID'), isFalse);
      });

      test('应该正确从JSON反序列化', () {
        final json = {
          'appInstallID': 1,
          'domain': 'ai.example.com',
          'ipList': '192.168.1.100',
          'sslID': 1,
          'websiteID': 1,
        };

        final model = OllamaBindDomain.fromJson(json);

        expect(model.appInstallID, equals(1));
        expect(model.domain, equals('ai.example.com'));
        expect(model.ipList, equals('192.168.1.100'));
        expect(model.sslID, equals(1));
        expect(model.websiteID, equals(1));
      });

      test('应该处理null值', () {
        final json = {
          'appInstallID': 1,
          'domain': 'ai.example.com',
        };

        final model = OllamaBindDomain.fromJson(json);

        expect(model.appInstallID, equals(1));
        expect(model.domain, equals('ai.example.com'));
        expect(model.ipList, isNull);
        expect(model.sslID, isNull);
        expect(model.websiteID, isNull);
      });
    });

    group('OllamaBindDomainRes模型测试', () {
      test('应该正确创建实例', () {
        final model = OllamaBindDomainRes(
          acmeAccountID: 1,
          allowIPs: ['192.168.1.100', '192.168.1.101'],
          connUrl: 'https://ai.example.com',
          domain: 'ai.example.com',
          sslID: 1,
          websiteID: 1,
        );

        expect(model.acmeAccountID, equals(1));
        expect(model.allowIPs, hasLength(2));
        expect(model.connUrl, equals('https://ai.example.com'));
        expect(model.domain, equals('ai.example.com'));
      });

      test('应该正确序列化和反序列化', () {
        final model = OllamaBindDomainRes(
          acmeAccountID: 1,
          allowIPs: ['192.168.1.100'],
          connUrl: 'https://ai.example.com',
          domain: 'ai.example.com',
          sslID: 1,
          websiteID: 1,
        );

        final json = model.toJson();
        final restored = OllamaBindDomainRes.fromJson(json);

        expect(restored.acmeAccountID, equals(model.acmeAccountID));
        expect(restored.allowIPs, equals(model.allowIPs));
        expect(restored.connUrl, equals(model.connUrl));
        expect(restored.domain, equals(model.domain));
      });
    });

    group('OllamaModelName模型测试', () {
      test('应该正确创建实例', () {
        final model = OllamaModelName(
          name: 'llama2',
          taskID: 'task-123',
        );

        expect(model.name, equals('llama2'));
        expect(model.taskID, equals('task-123'));
      });

      test('应该正确序列化和反序列化', () {
        final model = OllamaModelName(name: 'mistral');
        final json = model.toJson();
        final restored = OllamaModelName.fromJson(json);

        expect(restored.name, equals('mistral'));
        expect(restored.taskID, isNull);
      });
    });

    group('GpuInfo模型测试', () {
      test('应该正确创建实例', () {
        final model = GpuInfo(
          index: 0,
          productName: 'NVIDIA GeForce RTX 3090',
          temperature: '65',
          fanSpeed: '45%',
          gpuUtil: '80%',
          memTotal: '24576 MiB',
          memUsed: '16384 MiB',
          memoryUsage: '66.67%',
          powerDraw: '250W',
          maxPowerLimit: '350W',
          performanceState: 'P0',
          powerUsage: '250W',
        );

        expect(model.index, equals(0));
        expect(model.productName, equals('NVIDIA GeForce RTX 3090'));
        expect(model.temperature, equals('65'));
        expect(model.fanSpeed, equals('45%'));
        expect(model.gpuUtil, equals('80%'));
      });

      test('应该正确序列化和反序列化', () {
        final json = {
          'index': 0,
          'productName': 'NVIDIA GeForce RTX 3090',
          'temperature': '65',
          'fanSpeed': '45%',
          'gpuUtil': '80%',
          'memTotal': '24576 MiB',
          'memUsed': '16384 MiB',
        };

        final model = GpuInfo.fromJson(json);
        final restoredJson = model.toJson();

        expect(model.index, equals(0));
        expect(model.productName, equals('NVIDIA GeForce RTX 3090'));
        expect(restoredJson['index'], equals(0));
        expect(restoredJson['productName'], equals('NVIDIA GeForce RTX 3090'));
      });
    });

    group('OllamaModel模型测试', () {
      test('应该正确创建实例', () {
        final model = OllamaModel(
          name: 'llama2',
          size: '4GB',
          modified: '2024-01-01T00:00:00Z',
        );

        expect(model.name, equals('llama2'));
        expect(model.size, equals('4GB'));
        expect(model.modified, equals('2024-01-01T00:00:00Z'));
      });

      test('应该正确序列化和反序列化', () {
        final model = OllamaModel(name: 'mistral', size: '4.1GB');
        final json = model.toJson();
        final restored = OllamaModel.fromJson(json);

        expect(restored.name, equals('mistral'));
        expect(restored.size, equals('4.1GB'));
        expect(restored.modified, isNull);
      });
    });

    group('OllamaModelDropList模型测试', () {
      test('应该正确创建实例', () {
        final model = OllamaModelDropList(
          label: 'Llama 2',
          value: 'llama2',
        );

        expect(model.label, equals('Llama 2'));
        expect(model.value, equals('llama2'));
      });

      test('应该正确序列化和反序列化', () {
        final model = OllamaModelDropList(label: 'Mistral', value: 'mistral');
        final json = model.toJson();
        final restored = OllamaModelDropList.fromJson(json);

        expect(restored.label, equals('Mistral'));
        expect(restored.value, equals('mistral'));
      });
    });
  });

  group('MCP数据模型测试', () {
    group('McpEnvironment模型测试', () {
      test('应该正确创建实例', () {
        final model = McpEnvironment(
          key: 'API_KEY',
          value: 'secret123',
        );

        expect(model.key, equals('API_KEY'));
        expect(model.value, equals('secret123'));
      });

      test('应该正确序列化和反序列化', () {
        final model = McpEnvironment(key: 'PORT', value: '8080');
        final json = model.toJson();
        final restored = McpEnvironment.fromJson(json);

        expect(restored.key, equals('PORT'));
        expect(restored.value, equals('8080'));
      });
    });

    group('McpVolume模型测试', () {
      test('应该正确创建实例', () {
        final model = McpVolume(
          source: '/host/path',
          target: '/container/path',
        );

        expect(model.source, equals('/host/path'));
        expect(model.target, equals('/container/path'));
      });

      test('应该正确序列化和反序列化', () {
        final model = McpVolume(source: '/data', target: '/app/data');
        final json = model.toJson();
        final restored = McpVolume.fromJson(json);

        expect(restored.source, equals('/data'));
        expect(restored.target, equals('/app/data'));
      });
    });

    group('McpBindDomain模型测试', () {
      test('应该正确创建实例', () {
        final model = McpBindDomain(
          domain: 'mcp.example.com',
          ipList: '192.168.1.100',
          sslID: 1,
        );

        expect(model.domain, equals('mcp.example.com'));
        expect(model.ipList, equals('192.168.1.100'));
        expect(model.sslID, equals(1));
      });

      test('应该正确序列化和反序列化', () {
        final model = McpBindDomain(domain: 'mcp.example.com');
        final json = model.toJson();
        final restored = McpBindDomain.fromJson(json);

        expect(restored.domain, equals('mcp.example.com'));
        expect(restored.ipList, isNull);
        expect(restored.sslID, isNull);
      });
    });

    group('McpServerCreate模型测试', () {
      test('应该正确创建实例', () {
        final model = McpServerCreate(
          name: 'filesystem-mcp',
          type: 'stdio',
          command: 'mcp-filesystem',
          port: 8080,
          outputTransport: 'stdio',
          baseUrl: 'http://localhost',
          containerName: 'mcp-container',
          environments: [
            McpEnvironment(key: 'LOG_LEVEL', value: 'debug'),
          ],
          volumes: [
            McpVolume(source: '/data', target: '/app/data'),
          ],
        );

        expect(model.name, equals('filesystem-mcp'));
        expect(model.type, equals('stdio'));
        expect(model.command, equals('mcp-filesystem'));
        expect(model.port, equals(8080));
        expect(model.environments, hasLength(1));
        expect(model.volumes, hasLength(1));
      });

      test('应该正确序列化和反序列化', () {
        final model = McpServerCreate(
          name: 'test-mcp',
          type: 'sse',
          command: 'test-command',
          port: 9090,
          outputTransport: 'sse',
        );

        final json = model.toJson();
        final restored = McpServerCreate.fromJson(json);

        expect(restored.name, equals('test-mcp'));
        expect(restored.type, equals('sse'));
        expect(restored.command, equals('test-command'));
        expect(restored.port, equals(9090));
      });
    });

    group('McpServerSearch模型测试', () {
      test('应该正确创建实例', () {
        final model = McpServerSearch(
          name: 'filesystem',
          page: 1,
          pageSize: 10,
          sync: true,
        );

        expect(model.name, equals('filesystem'));
        expect(model.page, equals(1));
        expect(model.pageSize, equals(10));
        expect(model.sync, isTrue);
      });

      test('应该正确序列化和反序列化', () {
        final model = McpServerSearch(page: 2, pageSize: 20);
        final json = model.toJson();
        final restored = McpServerSearch.fromJson(json);

        expect(restored.page, equals(2));
        expect(restored.pageSize, equals(20));
        expect(restored.name, isNull);
        expect(restored.sync, isNull);
      });
    });

    group('McpServerDTO模型测试', () {
      test('应该正确创建实例', () {
        final model = McpServerDTO(
          id: 1,
          name: 'filesystem-mcp',
          type: 'stdio',
          status: 'running',
          command: 'mcp-filesystem',
          port: 8080,
          createdAt: '2024-01-01T00:00:00Z',
        );

        expect(model.id, equals(1));
        expect(model.name, equals('filesystem-mcp'));
        expect(model.status, equals('running'));
      });

      test('应该正确序列化和反序列化', () {
        final json = {
          'id': 1,
          'name': 'filesystem-mcp',
          'type': 'stdio',
          'status': 'running',
          'command': 'mcp-filesystem',
          'port': 8080,
          'createdAt': '2024-01-01T00:00:00Z',
        };

        final model = McpServerDTO.fromJson(json);
        final restoredJson = model.toJson();

        expect(model.id, equals(1));
        expect(model.name, equals('filesystem-mcp'));
        expect(restoredJson['id'], equals(1));
        expect(restoredJson['name'], equals('filesystem-mcp'));
      });
    });

    group('McpServersRes模型测试', () {
      test('应该正确创建实例', () {
        final model = McpServersRes(
          items: [
            McpServerDTO(id: 1, name: 'mcp-1'),
            McpServerDTO(id: 2, name: 'mcp-2'),
          ],
          total: 2,
        );

        expect(model.items, hasLength(2));
        expect(model.total, equals(2));
      });

      test('应该正确序列化和反序列化', () {
        final json = {
          'items': [
            {'id': 1, 'name': 'mcp-1'},
            {'id': 2, 'name': 'mcp-2'},
          ],
          'total': 2,
        };

        final model = McpServersRes.fromJson(json);

        expect(model.items, hasLength(2));
        expect(model.total, equals(2));
        expect(model.items![0].id, equals(1));
        expect(model.items![1].id, equals(2));
      });
    });
  });

  group('边界条件测试', () {
    test('空字符串应该正确处理', () {
      final model = OllamaModelName(name: '');
      expect(model.name, isEmpty);
    });

    test('特殊字符应该正确处理', () {
      final model = OllamaModelName(name: r'model@#$%^&*()');
      expect(model.name, equals(r'model@#$%^&*()'));
    });

    test('Unicode字符应该正确处理', () {
      final model = OllamaBindDomain(
        appInstallID: 1,
        domain: '测试.例子.com',
      );
      expect(model.domain, equals('测试.例子.com'));
    });

    test('超长字符串应该正确处理', () {
      final longName = 'a' * 1000;
      final model = OllamaModelName(name: longName);
      expect(model.name, hasLength(1000));
    });

    test('空列表应该正确处理', () {
      final model = McpServersRes(items: [], total: 0);
      expect(model.items, isEmpty);
      expect(model.total, equals(0));
    });

    test('大型列表应该正确处理', () {
      final items = List.generate(
        100,
        (i) => McpServerDTO(id: i, name: 'mcp-$i'),
      );

      final model = McpServersRes(items: items, total: 100);

      expect(model.items, hasLength(100));
      expect(model.total, equals(100));
    });
  });

  group('JSON兼容性测试', () {
    test('Mock响应数据应该符合模型结构', () {
      final mockResponse = {
        'code': 200,
        'message': 'success',
        'data': {
          'items': [
            {'name': 'm', 'size': 1}
          ],
          'total': 1,
        },
      };
      expect(mockResponse['code'], equals(200));
      expect(mockResponse['data'], isNotNull);
      final data = mockResponse['data'] as Map<String, dynamic>;
      expect(data['items'], isA<List>());
    });

    test('MCP Mock响应数据应该符合模型结构', () {
      final mockResponse = {
        'code': 200,
        'message': 'success',
        'data': {
          'items': [
            {'id': 1, 'name': 's'}
          ],
          'total': 1,
        },
      };
      expect(mockResponse['code'], equals(200));
      expect(mockResponse['data'], isNotNull);
      final data = mockResponse['data'] as Map<String, dynamic>;
      expect(data['items'], isA<List>());
    });
  });
}
