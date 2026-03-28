import 'package:onepanel_client/data/models/process_detail_models.dart';
import 'package:onepanel_client/data/models/process_models.dart';
import 'package:onepanel_client/data/models/process_ws_models.dart';
import 'package:onepanel_client/data/repositories/process_repository.dart';

class ProcessService {
  ProcessService({
    ProcessRepository? repository,
  }) : _repository = repository ?? ProcessRepository();

  final ProcessRepository _repository;

  Future<ProcessDetail> loadDetail(int pid) =>
      _repository.getProcessDetail(pid);

  Future<void> stopProcess(int pid) => _repository.stopProcess(pid);

  Future<List<ListeningProcess>> loadListening() =>
      _repository.getListeningProcesses();

  Stream<List<ProcessSummary>> watchProcesses() => _repository.watchProcesses();

  Future<void> connectProcesses(ProcessListQuery query) {
    return _repository.connectProcesses(
      ProcessWsMessage.process(
        pid: query.pid,
        name: query.name,
        username: query.username,
      ),
    );
  }

  Future<void> closeProcesses() => _repository.closeProcesses();

  List<ProcessSummary> mergeListeningData(
    List<ProcessSummary> processes,
    List<ListeningProcess> listening,
  ) {
    final listeningMap = <int, List<int>>{
      for (final item in listening) item.pid: item.ports,
    };
    return processes
        .map(
          (item) => item.copyWith(
            listeningPorts: listeningMap[item.pid] ?? const <int>[],
          ),
        )
        .where(
          (item) =>
              item.status.isNotEmpty && item.name.isNotEmpty && item.pid > 0,
        )
        .toList(growable: false);
  }
}
