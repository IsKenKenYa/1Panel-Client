import 'package:onepanel_client/api/v2/script_library_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/network/script_run_ws_client.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/script_library_models.dart';

class ScriptLibraryRepository {
  ScriptLibraryRepository({
    ApiClientManager? clientManager,
    ScriptLibraryV2Api? api,
    ScriptRunWsClient? runWsClient,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api,
        _runWsClient = runWsClient ?? ScriptRunWsClient();

  final ApiClientManager _clientManager;
  ScriptLibraryV2Api? _api;
  final ScriptRunWsClient _runWsClient;

  Future<ScriptLibraryV2Api> _ensureApi() async {
    return _api ??= await _clientManager.getScriptLibraryApi();
  }

  Future<PageResult<ScriptLibraryInfo>> searchScripts(
    ScriptLibraryQuery request,
  ) async {
    final api = await _ensureApi();
    final response = await api.searchScripts(request);
    return response.data ??
        const PageResult<ScriptLibraryInfo>(
          items: <ScriptLibraryInfo>[],
          total: 0,
        );
  }

  Future<void> syncScripts(String taskId) async {
    final api = await _ensureApi();
    await api.syncScripts(taskId);
  }

  Future<void> deleteScripts(List<int> ids) async {
    final api = await _ensureApi();
    await api.deleteScripts(ScriptDeleteRequest(ids: ids));
  }

  Stream<String> watchRunOutput() => _runWsClient.output;
  Stream<bool> watchRunState() => _runWsClient.runningState;

  Future<void> startRun(ScriptRunRequest request) {
    return _runWsClient.connect(
      scriptId: request.scriptId,
      cols: request.cols,
      rows: request.rows,
      operateNode: request.operateNode,
    );
  }

  Future<void> stopRun() => _runWsClient.close();
}
