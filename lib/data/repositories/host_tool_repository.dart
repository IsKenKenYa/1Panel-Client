import 'package:onepanel_client/api/v2/host_tool_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/host_tool_models.dart';

class HostToolRepository {
  HostToolRepository({
    ApiClientManager? clientManager,
    HostToolV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  HostToolV2Api? _api;

  Future<HostToolV2Api> _ensureApi() async {
    return _api ??= await _clientManager.getHostToolApi();
  }

  Future<HostToolStatusResponse> getToolStatus(HostToolRequest request) async {
    final api = await _ensureApi();
    return (await api.getToolStatus(request)).data ??
        const HostToolStatusResponse();
  }

  Future<HostToolConfigResponse> getToolConfig(
    HostToolConfigRequest request,
  ) async {
    final api = await _ensureApi();
    return (await api.getToolConfig(request)).data ??
        const HostToolConfigResponse();
  }

  Future<void> initTool(HostToolCreateRequest request) async {
    final api = await _ensureApi();
    await api.initTool(request);
  }

  Future<void> operateTool(HostToolRequest request) async {
    final api = await _ensureApi();
    await api.operateTool(request);
  }

  Future<List<HostToolProcessConfig>> getSupervisorProcesses() async {
    final api = await _ensureApi();
    return (await api.getSupervisorProcesses()).data ??
        const <HostToolProcessConfig>[];
  }

  Future<void> upsertSupervisorProcess(
    HostToolProcessConfigRequest request,
  ) async {
    final api = await _ensureApi();
    await api.upsertSupervisorProcess(request);
  }

  Future<void> operateSupervisorProcess(
    HostToolProcessOperateRequest request,
  ) async {
    final api = await _ensureApi();
    await api.operateSupervisorProcess(request);
  }

  Future<String> operateSupervisorProcessFile(
    HostToolProcessFileRequest request,
  ) async {
    final api = await _ensureApi();
    return (await api.operateSupervisorProcessFile(request)).data ?? '';
  }
}
