import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import '../core/mock_api_responses.dart';
import 'package:onepanel_client/data/models/container_models.dart';

void main() {
  setUpAll(() async {
    await TestEnvironment.initialize();
  });

  group('Container数据模型测试', () {
    group('ContainerOperate模型测试', () {
      test('应该正确创建实例', () {
        final model = ContainerOperate(
          name: 'nginx-server',
          image: 'nginx:latest',
          containerID: 'abc123',
          memory: 512,
          nanoCPUs: 1000000000,
          network: 'bridge',
          restartPolicy: 'always',
          env: ['NGINX_HOST=localhost'],
          cmd: ['nginx', '-g', 'daemon off;'],
        );

        expect(model.name, equals('nginx-server'));
        expect(model.image, equals('nginx:latest'));
        expect(model.containerID, equals('abc123'));
        expect(model.memory, equals(512));
        expect(model.nanoCPUs, equals(1000000000));
        expect(model.network, equals('bridge'));
        expect(model.restartPolicy, equals('always'));
        expect(model.env, hasLength(1));
        expect(model.cmd, hasLength(3));
      });

      test('应该正确序列化为JSON', () {
        final model = ContainerOperate(
          name: 'mysql-db',
          image: 'mysql:8.0',
          memory: 1024,
          env: ['MYSQL_ROOT_PASSWORD=secret'],
        );

        final json = model.toJson();

        expect(json['name'], equals('mysql-db'));
        expect(json['image'], equals('mysql:8.0'));
        expect(json['memory'], equals(1024));
        expect(json['env'], equals(['MYSQL_ROOT_PASSWORD=secret']));
      });

      test('应该正确从JSON反序列化', () {
        final json = {
          'name': 'redis-cache',
          'image': 'redis:7',
          'memory': 256,
          'network': 'host',
          'restartPolicy': 'unless-stopped',
        };

        final model = ContainerOperate.fromJson(json);

        expect(model.name, equals('redis-cache'));
        expect(model.image, equals('redis:7'));
        expect(model.memory, equals(256));
        expect(model.network, equals('host'));
        expect(model.restartPolicy, equals('unless-stopped'));
      });
    });

    group('ContainerOperation模型测试', () {
      test('应该正确创建实例', () {
        final model = ContainerOperation(
          names: ['nginx-server', 'mysql-db'],
          operation: 'start',
        );

        expect(model.names, hasLength(2));
        expect(model.names[0], equals('nginx-server'));
        expect(model.operation, equals('start'));
      });

      test('应该正确序列化和反序列化', () {
        final model = ContainerOperation(
          names: ['redis-cache'],
          operation: 'restart',
        );

        final json = model.toJson();
        final restored = ContainerOperation.fromJson(json);

        expect(restored.names, hasLength(1));
        expect(restored.names[0], equals('redis-cache'));
        expect(restored.operation, equals('restart'));
      });
    });

    group('ContainerCreateByCommand模型测试', () {
      test('应该正确序列化和反序列化', () {
        final model = ContainerCreateByCommand(
          command: 'docker run -d nginx:latest',
          name: 'nginx-demo',
        );

        final json = model.toJson();
        final restored = ContainerCreateByCommand.fromJson(json);

        expect(restored.command, equals('docker run -d nginx:latest'));
        expect(restored.name, equals('nginx-demo'));
      });
    });

    group('ContainerInfo模型测试', () {
      test('应该正确创建实例', () {
        final model = ContainerInfo(
          id: 'abc123def456',
          name: 'nginx-server',
          image: 'nginx:latest',
          status: 'running',
          state: 'running',
          createTime: '2024-01-01T00:00:00Z',
          ipAddress: '172.17.0.2',
          network: 'bridge',
        );

        expect(model.id, equals('abc123def456'));
        expect(model.name, equals('nginx-server'));
        expect(model.image, equals('nginx:latest'));
        expect(model.status, equals('running'));
        expect(model.state, equals('running'));
      });

      test('应该正确序列化和反序列化', () {
        final json = {
          'id': 'abc123',
          'name': 'mysql-db',
          'image': 'mysql:8.0',
          'status': 'running',
          'state': 'running',
          'createTime': '2024-01-01T00:00:00Z',
          'ipAddress': '172.17.0.3',
        };

        final model = ContainerInfo.fromJson(json);
        final restoredJson = model.toJson();

        expect(model.id, equals('abc123'));
        expect(model.name, equals('mysql-db'));
        expect(restoredJson['status'], equals('running'));
      });
    });

    group('ContainerStats模型测试', () {
      test('应该正确创建实例', () {
        final model = ContainerStats(
          cache: 1024000,
          cpuPercent: 25.5,
          ioRead: 204800,
          ioWrite: 102400,
          memory: 512000,
          networkRX: 1024000,
          networkTX: 512000,
        );

        expect(model.cpuPercent, equals(25.5));
        expect(model.cache, equals(1024000));
        expect(model.memory, equals(512000));
        expect(model.ioRead, equals(204800));
      });
    });

    group('ContainerStatus模型测试', () {
      test('应该正确创建实例', () {
        final model = ContainerStatus(
          all: 10,
          running: 5,
          paused: 1,
          exited: 3,
          created: 1,
          dead: 0,
          removing: 0,
          restarting: 0,
          containerCount: 10,
          imageCount: 15,
          imageSize: 5000000000,
          networkCount: 3,
          volumeCount: 5,
          composeCount: 2,
          composeTemplateCount: 1,
          repoCount: 2,
        );

        expect(model.running, equals(5));
        expect(model.exited, equals(3));
        expect(model.paused, equals(1));
        expect(model.all, equals(10));
      });
    });

    group('PortHelper模型测试', () {
      test('应该正确创建实例', () {
        final model = PortHelper(
          containerPort: '80',
          hostPort: '8080',
          protocol: 'tcp',
          hostIP: '0.0.0.0',
        );

        expect(model.containerPort, equals('80'));
        expect(model.hostPort, equals('8080'));
        expect(model.protocol, equals('tcp'));
        expect(model.hostIP, equals('0.0.0.0'));
      });

      test('应该正确序列化和反序列化', () {
        final model = PortHelper(
          containerPort: '443',
          hostPort: '8443',
        );

        final json = model.toJson();
        final restored = PortHelper.fromJson(json);

        expect(restored.containerPort, equals('443'));
        expect(restored.hostPort, equals('8443'));
      });
    });

    group('VolumeHelper模型测试', () {
      test('应该正确创建实例', () {
        final model = VolumeHelper(
          sourceDir: '/host/data',
          containerDir: '/container/data',
          mode: 'rw',
        );

        expect(model.sourceDir, equals('/host/data'));
        expect(model.containerDir, equals('/container/data'));
        expect(model.mode, equals('rw'));
      });

      test('应该正确序列化和反序列化', () {
        final model = VolumeHelper(
          sourceDir: '/var/www',
          containerDir: '/usr/share/nginx/html',
          mode: 'ro',
        );

        final json = model.toJson();
        final restored = VolumeHelper.fromJson(json);

        expect(restored.sourceDir, equals('/var/www'));
        expect(restored.containerDir, equals('/usr/share/nginx/html'));
        expect(restored.mode, equals('ro'));
      });
    });
  });

  group('边界条件测试', () {
    test('空容器名称应该正确处理', () {
      expect(
        () => ContainerOperate(name: '', image: 'nginx'),
        returnsNormally,
      );
    });

    test('空镜像名称应该正确处理', () {
      expect(
        () => ContainerOperate(name: 'test', image: ''),
        returnsNormally,
      );
    });

    test('空列表应该正确处理', () {
      final model = ContainerOperation(names: [], operation: 'start');
      expect(model.names, isEmpty);
    });

    test('特殊字符容器名称应该正确处理', () {
      final model = ContainerOperate(
        name: r'test-container_v1.0',
        image: 'nginx',
      );
      expect(model.name, equals(r'test-container_v1.0'));
    });

    test('Unicode字符应该正确处理', () {
      final model = ContainerOperate(
        name: '测试容器',
        image: 'nginx',
      );
      expect(model.name, equals('测试容器'));
    });

    test('超长容器名称应该正确处理', () {
      final longName = 'a' * 100;
      final model = ContainerOperate(name: longName, image: 'nginx');
      expect(model.name, hasLength(100));
    });

    test('大量端口映射应该正确处理', () {
      final ports = List.generate(
        100,
        (i) => PortHelper(containerPort: '${8080 + i}', hostPort: '${9000 + i}'),
      );

      final model = ContainerOperate(
        name: 'test',
        image: 'nginx',
        exposedPorts: ports,
      );

      expect(model.exposedPorts, hasLength(100));
    });
  });

  group('JSON兼容性测试', () {
    test('Mock容器列表响应数据应该符合模型结构', () {
      final mockResponse = MockContainerResponses.containerList();
      expect(mockResponse['data'], isNotNull);
      expect(mockResponse['data'], isA<List>());
    });

    test('Mock镜像列表响应数据应该符合模型结构', () {
      final mockResponse = MockContainerResponses.imageList();
      expect(mockResponse['data'], isNotNull);
      expect(mockResponse['data'], isA<List>());
    });

    test('Mock网络列表响应数据应该符合模型结构', () {
      final mockResponse = MockContainerResponses.networkList();
      expect(mockResponse['data'], isNotNull);
      expect(mockResponse['data'], isA<List>());
    });

    test('Mock卷列表响应数据应该符合模型结构', () {
      final mockResponse = MockContainerResponses.volumeList();
      expect(mockResponse['data'], isNotNull);
      expect(mockResponse['data'], isA<List>());
    });
  });
}
