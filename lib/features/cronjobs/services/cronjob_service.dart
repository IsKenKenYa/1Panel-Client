import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/cronjob_form_request_models.dart';
import 'package:onepanel_client/data/models/cronjob_list_models.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';
import 'package:onepanel_client/data/repositories/cronjob_repository.dart';
import 'package:onepanel_client/features/group/services/group_service.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';

class CronjobService {
  CronjobService({
    CronjobRepository? repository,
    GroupService? groupService,
  })  : _repository = repository ?? CronjobRepository(),
        _groupService = groupService ?? GroupService();

  final CronjobRepository _repository;
  final GroupService _groupService;

  Future<PageResult<CronjobSummary>> searchCronjobs(
      CronjobListQuery request) async {
    final result = await _repository.searchCronjobs(request);
    if (result.items.isEmpty) return result;
    final items =
        await Future.wait(result.items.map((CronjobSummary item) async {
      if (item.spec.isEmpty) return item;
      final nextHandles = await _repository.loadNextHandle(item.spec);
      return item.copyWith(
        nextHandlePreview: nextHandles.isEmpty ? null : nextHandles.first,
      );
    }));
    return PageResult<CronjobSummary>(
      items: items,
      total: result.total,
      page: result.page,
      pageSize: result.pageSize,
      totalPages: result.totalPages,
    );
  }

  Future<List<GroupInfo>> loadGroups({bool forceRefresh = false}) {
    return _groupService.listGroups('cronjob', forceRefresh: forceRefresh);
  }

  Future<void> updateStatus(int id, String status) {
    return _repository
        .updateStatus(CronjobStatusUpdate(id: id, status: status));
  }

  Future<void> handleOnce(int id) => _repository.handleOnce(id);

  Future<void> stop(int id) => _repository.stop(id);

  Future<void> delete(
    int id, {
    bool cleanData = false,
    bool cleanRemoteData = false,
  }) {
    return _repository.delete(
      CronjobBatchDeleteRequest(
        ids: <int>[id],
        cleanData: cleanData,
        cleanRemoteData: cleanRemoteData,
      ),
    );
  }

  Future<PageResult<CronjobRecordInfo>> searchRecords(
      CronjobRecordQuery request) {
    return _repository.searchRecords(request);
  }

  Future<String> loadRecordLog(int id) => _repository.loadRecordLog(id);

  Future<void> cleanRecords(CronjobRecordCleanRequest request) {
    return _repository.cleanRecords(request);
  }

  Future<List<CronjobScriptOption>> loadScriptOptions() {
    return _repository.loadScriptOptions();
  }
}
