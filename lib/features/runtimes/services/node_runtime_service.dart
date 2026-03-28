import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/repositories/runtime_repository.dart';

class NodeRuntimeService {
  NodeRuntimeService({
    RuntimeRepository? repository,
  }) : _repository = repository ?? RuntimeRepository();

  final RuntimeRepository _repository;

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

  Future<void> runScript({
    required int runtimeId,
    required String scriptName,
    required String packageManager,
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
  }
}
