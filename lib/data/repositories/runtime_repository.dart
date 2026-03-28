import 'package:onepanel_client/api/v2/runtime_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';

class RuntimeRepository {
  RuntimeRepository({
    ApiClientManager? clientManager,
    RuntimeV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  RuntimeV2Api? _api;

  Future<RuntimeV2Api> _ensureApi() async {
    return _api ??= await _clientManager.getRuntimeApi();
  }

  Future<PageResult<RuntimeInfo>> searchRuntimes(RuntimeSearch request) async {
    final api = await _ensureApi();
    final response = await api.getRuntimes(request);
    return response.data ??
        const PageResult<RuntimeInfo>(items: <RuntimeInfo>[], total: 0);
  }

  Future<RuntimeInfo?> getRuntime(int id) async {
    final api = await _ensureApi();
    final response = await api.getRuntime(id);
    return response.data;
  }

  Future<RuntimeInfo?> createRuntime(RuntimeCreate request) async {
    final api = await _ensureApi();
    final response = await api.createRuntime(request);
    return response.data;
  }

  Future<void> updateRuntime(RuntimeUpdate request) async {
    final api = await _ensureApi();
    await api.updateRuntime(request);
  }

  Future<void> deleteRuntime(RuntimeDelete request) async {
    final api = await _ensureApi();
    await api.deleteRuntime(request);
  }

  Future<void> operateRuntime(RuntimeOperate request) async {
    final api = await _ensureApi();
    await api.operateRuntime(request);
  }

  Future<void> syncRuntimeStatus() async {
    final api = await _ensureApi();
    await api.syncRuntimeStatus();
  }

  Future<void> updateRuntimeRemark(RuntimeRemarkUpdate request) async {
    final api = await _ensureApi();
    await api.updateRuntimeRemark(request);
  }

  Future<PHPExtensionsRes> getPhpExtensions(int runtimeId) async {
    final api = await _ensureApi();
    final response = await api.getPhpExtensions(runtimeId);
    return response.data ?? const PHPExtensionsRes();
  }

  Future<void> installPhpExtension(PHPExtensionInstallRequest request) async {
    final api = await _ensureApi();
    await api.installPhpExtension(request);
  }

  Future<void> uninstallPhpExtension(
    PHPExtensionInstallRequest request,
  ) async {
    final api = await _ensureApi();
    await api.uninstallPhpExtension(request);
  }

  Future<PHPConfig?> loadPhpConfig(int runtimeId) async {
    final api = await _ensureApi();
    final response = await api.loadPhpConfig(runtimeId);
    return response.data;
  }

  Future<void> updatePhpConfig(PHPConfigUpdate request) async {
    final api = await _ensureApi();
    await api.updatePhpConfig(request);
  }

  Future<List<FpmStatusItem>> getPhpStatus(int runtimeId) async {
    final api = await _ensureApi();
    final response = await api.getPhpStatus(runtimeId);
    return response.data ?? const <FpmStatusItem>[];
  }

  Future<List<NodeModuleInfo>> getNodeModules(NodeModuleRequest request) async {
    final api = await _ensureApi();
    final response = await api.getNodeModules(request);
    return response.data ?? const <NodeModuleInfo>[];
  }

  Future<void> operateNodeModule(NodeModuleRequest request) async {
    final api = await _ensureApi();
    await api.operateNodeModule(request);
  }

  Future<List<NodeScriptInfo>> getNodePackageScripts(
    NodePackageRequest request,
  ) async {
    final api = await _ensureApi();
    final response = await api.getNodePackageScripts(request);
    return response.data ?? const <NodeScriptInfo>[];
  }
}
