import 'package:onepanel_client/api/v2/cronjob_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/cronjob_form_request_models.dart';
import 'package:onepanel_client/data/models/cronjob_list_models.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';

class CronjobRepository {
  CronjobRepository({
    ApiClientManager? clientManager,
    CronjobV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  CronjobV2Api? _api;

  Future<CronjobV2Api> _ensureApi() async {
    return _api ??= await _clientManager.getCronjobApi();
  }

  Future<PageResult<CronjobSummary>> searchCronjobs(
    CronjobListQuery request,
  ) async {
    final api = await _ensureApi();
    final response = await api.searchCronjobs(request);
    return response.data ??
        const PageResult<CronjobSummary>(items: <CronjobSummary>[], total: 0);
  }

  Future<List<String>> loadNextHandle(String spec) async {
    final api = await _ensureApi();
    final response =
        await api.loadNextHandle(CronjobNextPreviewRequest(spec: spec));
    return response.data ?? const <String>[];
  }

  Future<void> updateStatus(CronjobStatusUpdate request) async {
    final api = await _ensureApi();
    await api.updateCronjobStatus(request);
  }

  Future<void> handleOnce(int id) async {
    final api = await _ensureApi();
    await api.handleCronjobOnce(CronjobHandleRequest(id: id));
  }

  Future<void> stop(int id) async {
    final api = await _ensureApi();
    await api.stopCronjob(id);
  }

  Future<void> delete(CronjobBatchDeleteRequest request) async {
    final api = await _ensureApi();
    await api.deleteCronjob(request);
  }

  Future<PageResult<CronjobRecordInfo>> searchRecords(
    CronjobRecordQuery request,
  ) async {
    final api = await _ensureApi();
    final response = await api.searchCronjobRecords(request);
    return response.data ??
        const PageResult<CronjobRecordInfo>(
          items: <CronjobRecordInfo>[],
          total: 0,
        );
  }

  Future<String> loadRecordLog(int id) async {
    final api = await _ensureApi();
    final response = await api.getRecordLog(id);
    return response.data ?? '';
  }

  Future<void> cleanRecords(CronjobRecordCleanRequest request) async {
    final api = await _ensureApi();
    await api.cleanRecords(request);
  }

  Future<List<CronjobScriptOption>> loadScriptOptions() async {
    final api = await _ensureApi();
    final response = await api.getScriptOptions();
    return response.data ?? const <CronjobScriptOption>[];
  }
}
