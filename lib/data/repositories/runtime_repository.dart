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
}
