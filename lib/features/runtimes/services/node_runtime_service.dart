import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/repositories/runtime_repository.dart';

class NodeScriptExecutionFeedback {
  const NodeScriptExecutionFeedback({
    required this.isSuccess,
    required this.status,
    this.message,
    this.timedOut = false,
    this.attempts = 0,
  });

  final bool isSuccess;
  final String status;
  final String? message;
  final bool timedOut;
  final int attempts;
}

class NodeRuntimeService {
  NodeRuntimeService({
    RuntimeRepository? repository,
  }) : _repository = repository ?? RuntimeRepository();

  final RuntimeRepository _repository;

  static const Set<String> _runningStatuses = <String>{
    'Starting',
    'Building',
    'Recreating',
    'Creating',
  };

  static const Set<String> _failedStatuses = <String>{
    'Error',
    'SystemRestart',
  };

  Future<List<NodeModuleInfo>> loadModules(int runtimeId) {
    return _repository.getNodeModules(NodeModuleRequest(id: runtimeId));
  }

  Future<void> operateModule({
    required int runtimeId,
    required String module,
    required String operate,
    required String packageManager,
  }) {
    return _repository.operateNodeModule(
      NodeModuleRequest(
        id: runtimeId,
        module: module,
        operate: operate,
        packageManager: packageManager,
      ),
    );
  }

  Future<void> installModule({
    required int runtimeId,
    required String module,
    required String packageManager,
  }) {
    return operateModule(
      runtimeId: runtimeId,
      module: module,
      operate: 'install',
      packageManager: packageManager,
    );
  }

  Future<void> uninstallModule({
    required int runtimeId,
    required String module,
    required String packageManager,
  }) {
    return operateModule(
      runtimeId: runtimeId,
      module: module,
      operate: 'uninstall',
      packageManager: packageManager,
    );
  }

  Future<List<NodeScriptInfo>> loadScripts(String codeDir) {
    return _repository
        .getNodePackageScripts(NodePackageRequest(codeDir: codeDir));
  }

  Future<NodeScriptExecutionFeedback> runScript({
    required int runtimeId,
    required String scriptName,
    required String packageManager,
    int maxPollAttempts = 24,
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    final runtime = await _repository.getRuntime(runtimeId);
    if (runtime == null) {
      throw Exception('runtime.detail.loadFailed');
    }

    final normalizedScript = scriptName.trim();
    if (normalizedScript.isEmpty) {
      throw Exception('runtime.form.execScriptRequired');
    }

    final normalizedManager =
        packageManager.trim().isEmpty ? 'npm' : packageManager.trim();

    final params = <String, dynamic>{
      ...(runtime.params ?? const <String, dynamic>{}),
      'EXEC_SCRIPT': normalizedScript,
      'CUSTOM_SCRIPT': '0',
      'PACKAGE_MANAGER': normalizedManager,
    };

    final update = RuntimeUpdate(
      id: runtimeId,
      appDetailId: runtime.appDetailId,
      appId: runtime.appId,
      name: runtime.name ?? 'node-$runtimeId',
      resource: runtime.resource,
      type: runtime.type,
      image: runtime.image,
      version: runtime.version,
      source: runtime.source,
      codeDir: runtime.codeDir,
      port: int.tryParse(runtime.port ?? ''),
      remark: runtime.remark,
      rebuild: true,
      params: params,
      exposedPorts: runtime.exposedPorts,
      environments: runtime.environments,
      volumes: runtime.volumes,
      extraHosts: runtime.extraHosts,
    );

    await _repository.updateRuntime(update);

    return _waitForRuntimeExecution(
      runtimeId: runtimeId,
      maxPollAttempts: maxPollAttempts,
      pollInterval: pollInterval,
    );
  }

  Future<NodeScriptExecutionFeedback> _waitForRuntimeExecution({
    required int runtimeId,
    required int maxPollAttempts,
    required Duration pollInterval,
  }) async {
    RuntimeInfo? latest;

    for (var i = 0; i < maxPollAttempts; i++) {
      if (i > 0) {
        await Future<void>.delayed(pollInterval);
      }

      try {
        await _repository.syncRuntimeStatus();
      } catch (_) {
        // Ignore sync transient errors and continue polling current runtime detail.
      }

      latest = await _repository.getRuntime(runtimeId);
      final status = (latest?.status ?? '').trim();

      if (!_runningStatuses.contains(status)) {
        return NodeScriptExecutionFeedback(
          isSuccess: !_failedStatuses.contains(status),
          status: status,
          message: latest?.message,
          attempts: i + 1,
        );
      }
    }

    final status = (latest?.status ?? '').trim();
    return NodeScriptExecutionFeedback(
      isSuccess: false,
      status: status,
      message: latest?.message,
      timedOut: true,
      attempts: maxPollAttempts,
    );
  }
}
