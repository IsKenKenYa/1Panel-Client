import 'dart:async';

import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/script_library_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/data/repositories/script_library_repository.dart';
import 'package:onepanel_client/features/group/services/group_service.dart';

class ScriptLibraryService {
  ScriptLibraryService({
    ScriptLibraryRepository? repository,
    GroupService? groupService,
  })  : _repository = repository ?? ScriptLibraryRepository(),
        _groupService = groupService ?? GroupService();

  final ScriptLibraryRepository _repository;
  final GroupService _groupService;

  Future<PageResult<ScriptLibraryInfo>> searchScripts(
    ScriptLibraryQuery request,
  ) {
    return _repository.searchScripts(request);
  }

  Future<List<GroupInfo>> loadGroups({bool forceRefresh = false}) {
    return _groupService.listGroups('script', forceRefresh: forceRefresh);
  }

  Future<ScriptSyncState> syncScripts() async {
    final taskId = 'script-sync-${DateTime.now().millisecondsSinceEpoch}';
    await _repository.syncScripts(taskId);
    return ScriptSyncState(taskId: taskId, isRunning: true);
  }

  Future<void> deleteScripts(List<int> ids) => _repository.deleteScripts(ids);

  Stream<String> watchRunOutput() => _repository.watchRunOutput();
  Stream<bool> watchRunState() => _repository.watchRunState();

  Future<void> startRun(int scriptId) {
    return _repository.startRun(ScriptRunRequest(scriptId: scriptId));
  }

  Future<void> stopRun() => _repository.stopRun();
}
