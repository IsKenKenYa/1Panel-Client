import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/repositories/runtime_repository.dart';
import 'package:onepanel_client/features/runtimes/services/node_runtime_service.dart';

class _FakeRuntimeRepository extends RuntimeRepository {
  int? requestedRuntimeId;
  List<RuntimeInfo?> runtimes = <RuntimeInfo?>[];
  RuntimeUpdate? updatedRequest;
  int _runtimeReadIndex = 0;

  @override
  Future<RuntimeInfo?> getRuntime(int id) async {
    requestedRuntimeId = id;
    if (runtimes.isEmpty) {
      return null;
    }
    if (_runtimeReadIndex >= runtimes.length) {
      return runtimes.last;
    }
    final value = runtimes[_runtimeReadIndex];
    _runtimeReadIndex += 1;
    return value;
  }

  @override
  Future<void> updateRuntime(RuntimeUpdate request) async {
    updatedRequest = request;
  }
}

void main() {
  group('NodeRuntimeService', () {
    test('runScript updates runtime with upstream node script protocol',
        () async {
      final repository = _FakeRuntimeRepository()
        ..runtimes = const <RuntimeInfo?>[
          RuntimeInfo(
            id: 7,
            appDetailId: 2,
            appId: 3,
            name: 'node-main',
            resource: 'appstore',
            type: 'node',
            image: 'node:20-alpine',
            version: '20',
            source: 'https://registry.npmjs.org/',
            codeDir: '/opt/node',
            port: '3000',
            remark: 'prod',
            status: 'Running',
            params: <String, dynamic>{
              'CONTAINER_NAME': 'node-main',
              'HOST_IP': '0.0.0.0',
            },
          ),
          RuntimeInfo(
            id: 7,
            status: 'Recreating',
            params: <String, dynamic>{
              'CONTAINER_NAME': 'node-main',
            },
          ),
          RuntimeInfo(
            id: 7,
            status: 'Running',
            params: <String, dynamic>{
              'CONTAINER_NAME': 'node-main',
            },
          ),
        ];
      final service = NodeRuntimeService(repository: repository);

      final feedback = await service.runScript(
        runtimeId: 7,
        scriptName: 'start',
        packageManager: 'npm',
        maxPollAttempts: 4,
        pollInterval: const Duration(milliseconds: 1),
      );

      expect(repository.requestedRuntimeId, 7);
      final request = repository.updatedRequest;
      expect(request, isNotNull);
      expect(request!.id, 7);
      expect(request.name, 'node-main');
      expect(request.params?['EXEC_SCRIPT'], 'start');
      expect(request.params?['CUSTOM_SCRIPT'], '0');
      expect(request.params?['PACKAGE_MANAGER'], 'npm');
      expect(feedback.isSuccess, isTrue);
      expect(feedback.status, 'Running');
      expect(feedback.timedOut, isFalse);
    });

    test('runScript throws when runtime does not exist', () async {
      final repository = _FakeRuntimeRepository()
        ..runtimes = const <RuntimeInfo?>[];
      final service = NodeRuntimeService(repository: repository);

      expect(
        service.runScript(
          runtimeId: 404,
          scriptName: 'start',
          packageManager: 'npm',
        ),
        throwsException,
      );
    });

    test('runScript returns timeout feedback when runtime keeps recreating',
        () async {
      final repository = _FakeRuntimeRepository()
        ..runtimes = const <RuntimeInfo?>[
          RuntimeInfo(id: 9, status: 'Running'),
          RuntimeInfo(id: 9, status: 'Recreating'),
          RuntimeInfo(id: 9, status: 'Recreating'),
          RuntimeInfo(id: 9, status: 'Recreating'),
        ];
      final service = NodeRuntimeService(repository: repository);

      final feedback = await service.runScript(
        runtimeId: 9,
        scriptName: 'build',
        packageManager: 'npm',
        maxPollAttempts: 2,
        pollInterval: const Duration(milliseconds: 1),
      );

      expect(feedback.isSuccess, isFalse);
      expect(feedback.timedOut, isTrue);
      expect(feedback.status, 'Recreating');
      expect(feedback.attempts, 2);
    });
  });
}
