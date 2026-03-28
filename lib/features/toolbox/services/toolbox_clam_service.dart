import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/data/repositories/toolbox_repository.dart';

class ToolboxClamSnapshot {
  const ToolboxClamSnapshot({
    required this.tasks,
    required this.records,
  });

  final List<ClamBaseInfo> tasks;
  final List<ClamLogInfo> records;
}

class ToolboxClamService {
  ToolboxClamService({ToolboxRepository? repository})
      : _repository = repository ?? ToolboxRepository();

  final ToolboxRepository _repository;

  Future<ToolboxClamSnapshot> loadSnapshot() async {
    var tasks = await _repository.searchClamTasks(page: 1, pageSize: 20);
    if (tasks.isEmpty) {
      final fallback = await _repository.getClamBaseInfo();
      if (fallback.id != null ||
          (fallback.name != null && fallback.name!.isNotEmpty)) {
        tasks = [fallback];
      }
    }

    final taskId = tasks.isNotEmpty ? tasks.first.id : null;
    final records = taskId == null
        ? const <ClamLogInfo>[]
        : await _repository.searchClamRecords(
            clamId: taskId,
            page: 1,
            pageSize: 20,
          );

    return ToolboxClamSnapshot(
      tasks: tasks,
      records: records,
    );
  }
}
