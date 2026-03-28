import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/repositories/runtime_repository.dart';

class PhpRuntimeService {
  PhpRuntimeService({
    RuntimeRepository? repository,
  }) : _repository = repository ?? RuntimeRepository();

  final RuntimeRepository _repository;

  Future<PHPExtensionsRes> loadExtensions(int runtimeId) {
    return _repository.getPhpExtensions(runtimeId);
  }

  Future<void> installExtension(
    int runtimeId,
    String extensionName, {
    String taskId = '',
  }) {
    return _repository.installPhpExtension(
      PHPExtensionInstallRequest(
        id: runtimeId,
        name: extensionName,
        taskId: taskId,
      ),
    );
  }

  Future<void> uninstallExtension(
    int runtimeId,
    String extensionName, {
    String taskId = '',
  }) {
    return _repository.uninstallPhpExtension(
      PHPExtensionInstallRequest(
        id: runtimeId,
        name: extensionName,
        taskId: taskId,
      ),
    );
  }

  Future<PHPConfig?> loadConfig(int runtimeId) {
    return _repository.loadPhpConfig(runtimeId);
  }

  Future<void> saveConfig(PHPConfigUpdate request) {
    return _repository.updatePhpConfig(request);
  }

  Future<PHPConfigFileContent> loadConfigFile({
    required int runtimeId,
    required String type,
  }) {
    return _repository.loadPhpConfigFile(
      PHPConfigFileRequest(
        id: runtimeId,
        type: type,
      ),
    );
  }

  Future<void> saveConfigFile({
    required int runtimeId,
    required String type,
    required String content,
  }) {
    return _repository.updatePhpConfigFile(
      PHPConfigFileUpdate(
        id: runtimeId,
        type: type,
        content: content,
      ),
    );
  }

  Future<PHPFpmConfig> loadFpmConfig(int runtimeId) {
    return _repository.loadPhpFpmConfig(runtimeId);
  }

  Future<void> saveFpmConfig({
    required int runtimeId,
    required Map<String, String> params,
  }) {
    return _repository.updatePhpFpmConfig(
      PHPFpmConfig(
        id: runtimeId,
        params: params,
      ),
    );
  }

  Future<PHPContainerConfig> loadContainerConfig(int runtimeId) {
    return _repository.loadPhpContainerConfig(runtimeId);
  }

  Future<void> saveContainerConfig(PHPContainerConfig request) {
    return _repository.updatePhpContainerConfig(request);
  }

  Future<List<FpmStatusItem>> loadFpmStatus(int runtimeId) {
    return _repository.getPhpStatus(runtimeId);
  }

  Future<List<SupervisorProcessInfo>> loadSupervisorProcesses(int runtimeId) {
    return _repository.getSupervisorProcesses(runtimeId);
  }

  Future<void> operateSupervisorProcess({
    required int runtimeId,
    required String name,
    required String operate,
  }) {
    return _repository.operateSupervisorProcess(
      SupervisorProcessOperateRequest(
        operate: operate,
        name: name,
        id: runtimeId,
      ),
    );
  }

  Future<void> upsertSupervisorProcess({
    required int runtimeId,
    required String operate,
    required String name,
    required String command,
    required String user,
    required String dir,
    required String numprocs,
    required String environment,
  }) {
    return _repository.upsertSupervisorProcess(
      SupervisorProcessUpsertRequest(
        operate: operate,
        name: name,
        command: command,
        user: user,
        dir: dir,
        numprocs: numprocs,
        id: runtimeId,
        environment: environment,
      ),
    );
  }

  Future<String> loadSupervisorFile({
    required int runtimeId,
    required String name,
    required String file,
  }) {
    return _repository.operateSupervisorProcessFile(
      SupervisorProcessFileRequest(
        operate: 'get',
        name: name,
        file: file,
        id: runtimeId,
      ),
    );
  }

  Future<void> updateSupervisorFile({
    required int runtimeId,
    required String name,
    required String file,
    required String content,
  }) async {
    await _repository.operateSupervisorProcessFile(
      SupervisorProcessFileRequest(
        operate: 'update',
        name: name,
        file: file,
        id: runtimeId,
        content: content,
      ),
    );
  }

  Future<void> clearSupervisorLog({
    required int runtimeId,
    required String name,
    required String file,
  }) async {
    await _repository.operateSupervisorProcessFile(
      SupervisorProcessFileRequest(
        operate: 'clear',
        name: name,
        file: file,
        id: runtimeId,
      ),
    );
  }
}
