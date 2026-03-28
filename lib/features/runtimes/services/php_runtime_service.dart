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

  Future<List<FpmStatusItem>> loadFpmStatus(int runtimeId) {
    return _repository.getPhpStatus(runtimeId);
  }
}
