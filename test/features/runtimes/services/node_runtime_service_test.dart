import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/repositories/runtime_repository.dart';
import 'package:onepanel_client/features/runtimes/services/node_runtime_service.dart';

class _FakeRuntimeRepository extends RuntimeRepository {
  int? requestedRuntimeId;
  RuntimeInfo? runtime;
  RuntimeUpdate? updatedRequest;

  @override
  Future<RuntimeInfo?> getRuntime(int id) async {
    requestedRuntimeId = id;
    return runtime;
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
        ..runtime = const RuntimeInfo(
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
          params: <String, dynamic>{
            'CONTAINER_NAME': 'node-main',
            'HOST_IP': '0.0.0.0',
          },
        );
      final service = NodeRuntimeService(repository: repository);

      await service.runScript(
        runtimeId: 7,
        scriptName: 'start',
        packageManager: 'npm',
      );

      expect(repository.requestedRuntimeId, 7);
      final request = repository.updatedRequest;
      expect(request, isNotNull);
      expect(request!.id, 7);
      expect(request.name, 'node-main');
      expect(request.params?['EXEC_SCRIPT'], 'start');
      expect(request.params?['CUSTOM_SCRIPT'], '0');
      expect(request.params?['PACKAGE_MANAGER'], 'npm');
    });

    test('runScript throws when runtime does not exist', () async {
      final repository = _FakeRuntimeRepository();
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
  });
}
