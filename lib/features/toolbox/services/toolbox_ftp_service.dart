import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/data/repositories/toolbox_repository.dart';

class ToolboxFtpSnapshot {
  const ToolboxFtpSnapshot({
    required this.baseInfo,
    required this.users,
  });

  final FtpBaseInfo baseInfo;
  final List<FtpInfo> users;
}

class ToolboxFtpService {
  ToolboxFtpService({ToolboxRepository? repository})
      : _repository = repository ?? ToolboxRepository();

  final ToolboxRepository _repository;

  Future<ToolboxFtpSnapshot> loadSnapshot() async {
    final results = await Future.wait<dynamic>([
      _repository.getFtpBaseInfo(),
      _repository.searchFtpUsers(page: 1, pageSize: 50),
    ]);

    return ToolboxFtpSnapshot(
      baseInfo: results[0] as FtpBaseInfo,
      users: results[1] as List<FtpInfo>,
    );
  }

  Future<void> syncUsers() async {
    await _repository.syncFtp();
  }
}
