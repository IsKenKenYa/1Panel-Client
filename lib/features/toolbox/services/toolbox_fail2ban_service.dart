import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/data/repositories/toolbox_repository.dart';

class ToolboxFail2banSnapshot {
  const ToolboxFail2banSnapshot({
    required this.baseInfo,
    required this.configText,
    required this.records,
  });

  final Fail2banBaseInfo baseInfo;
  final String configText;
  final List<Fail2banRecord> records;
}

class ToolboxFail2banService {
  ToolboxFail2banService({ToolboxRepository? repository})
      : _repository = repository ?? ToolboxRepository();

  final ToolboxRepository _repository;

  Future<ToolboxFail2banSnapshot> loadSnapshot() async {
    final results = await Future.wait<dynamic>([
      _repository.getFail2banBaseInfo(),
      _repository.loadFail2banConf(),
      _repository.searchFail2banRecords(page: 1, pageSize: 20),
    ]);

    return ToolboxFail2banSnapshot(
      baseInfo: results[0] as Fail2banBaseInfo,
      configText: results[1] as String,
      records: results[2] as List<Fail2banRecord>,
    );
  }

  Future<void> updateConfig(Fail2banUpdate request) async {
    await _repository.updateFail2ban(request);
  }

  Future<void> operate(String operation) {
    return _repository.operateFail2ban(operation);
  }

  Future<void> operateSshd({
    required String operate,
    List<String> ips = const <String>[],
  }) {
    return _repository.operateFail2banSshd(
      operate: operate,
      ips: ips,
    );
  }
}
