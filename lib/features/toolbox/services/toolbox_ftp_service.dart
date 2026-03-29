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

  Future<ToolboxFtpSnapshot> loadSnapshot({
    int page = 1,
    int pageSize = 50,
    String? keyword,
  }) async {
    final results = await Future.wait<dynamic>([
      _repository.getFtpBaseInfo(),
      _repository.searchFtpUsers(
        page: page,
        pageSize: pageSize,
        keyword: keyword,
      ),
    ]);

    return ToolboxFtpSnapshot(
      baseInfo: results[0] as FtpBaseInfo,
      users: results[1] as List<FtpInfo>,
    );
  }

  Future<void> syncUsers() async {
    await _repository.syncFtp();
  }

  Future<void> createUser(FtpCreate request) {
    return _repository.createFtpUser(request);
  }

  Future<void> updateUser(FtpUpdate request) {
    return _repository.updateFtpUser(request);
  }

  Future<void> deleteUsers(List<int> ids) {
    return _repository.deleteFtpUsers(ids);
  }

  Future<void> operateService(String operation) {
    return _repository.operateFtp(operation);
  }
}
