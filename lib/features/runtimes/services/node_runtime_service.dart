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
    return _repository.getNodePackageScripts(NodePackageRequest(codeDir: codeDir));
  }

  Future<void> runScript({
    required int runtimeId,
    required String scriptName,
    required String packageManager,
  }) {
    return operateModule(
      runtimeId: runtimeId,
      module: scriptName,
      operate: 'script',
      packageManager: packageManager,
    );
  }
}
