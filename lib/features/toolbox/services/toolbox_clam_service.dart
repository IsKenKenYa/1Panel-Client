import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/data/repositories/toolbox_repository.dart';

class ToolboxClamSnapshot {
  const ToolboxClamSnapshot({
    required this.tasks,
    required this.records,
    required this.selectedTaskId,
  });

  final List<ClamBaseInfo> tasks;
  final List<ClamLogInfo> records;
  final int? selectedTaskId;
}

class ToolboxClamService {
  ToolboxClamService({ToolboxRepository? repository})
      : _repository = repository ?? ToolboxRepository();

  final ToolboxRepository _repository;

  Future<ToolboxClamSnapshot> loadSnapshot({
    int taskPage = 1,
    int taskPageSize = 20,
    int recordPage = 1,
    int recordPageSize = 20,
    int? selectedTaskId,
  }) async {
    var tasks = await _repository.searchClamTasks(
      page: taskPage,
      pageSize: taskPageSize,
    );
    if (tasks.isEmpty) {
      final fallback = await _repository.getClamBaseInfo();
      if (fallback.id != null ||
          (fallback.name != null && fallback.name!.isNotEmpty)) {
        tasks = [fallback];
      }
    }

    final taskId = selectedTaskId ?? (tasks.isNotEmpty ? tasks.first.id : null);
    final records = taskId == null
        ? const <ClamLogInfo>[]
        : await _repository.searchClamRecords(
            clamId: taskId,
            page: recordPage,
            pageSize: recordPageSize,
          );

    return ToolboxClamSnapshot(
      tasks: tasks,
      records: records,
      selectedTaskId: taskId,
    );
  }

  Future<List<ClamLogInfo>> loadRecords({
    required int clamId,
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.searchClamRecords(
      clamId: clamId,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> createTask(ClamCreate request) {
    return _repository.createClamTask(request);
  }

  Future<void> updateTask(ClamUpdate request) {
    return _repository.updateClamTask(request);
  }

  Future<void> deleteTasks({
    required List<int> ids,
    bool removeInfected = false,
  }) {
    return _repository.deleteClamTasks(
      ids: ids,
      removeInfected: removeInfected,
    );
  }

  Future<void> handleTask(int id) {
    return _repository.handleClam(id);
  }

  Future<void> operateService(String operation) {
    return _repository.operateClam(operation);
  }

  Future<void> cleanRecords(int taskId) {
    return _repository.cleanClamRecords(taskId);
  }
}
