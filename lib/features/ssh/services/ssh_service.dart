import 'dart:typed_data';

import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/services/file_save_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/ssh_cert_models.dart';
import 'package:onepanel_client/data/models/ssh_log_models.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
import 'package:onepanel_client/data/repositories/ssh_repository.dart';

class SSHService {
  SSHService({
    SSHRepository? repository,
    ApiClientManager? clientManager,
    FileSaveService? fileSaveService,
  })  : _repository = repository ?? SSHRepository(),
        _clientManager = clientManager ?? ApiClientManager.instance,
        _fileSaveService = fileSaveService ?? FileSaveService();

  final SSHRepository _repository;
  final ApiClientManager _clientManager;
  final FileSaveService _fileSaveService;

  Future<SshInfo> loadInfo() => _repository.getSshInfo();

  Future<void> operate(String operation) => _repository.operateSsh(operation);

  Future<void> updateSetting({
    required String key,
    required String newValue,
    String oldValue = '',
  }) {
    return _repository.updateSsh(
      SshUpdateRequest(
        key: key,
        oldValue: oldValue,
        newValue: newValue,
      ),
    );
  }

  Future<String> loadRawConfig() => _repository.loadSshFile();

  Future<void> saveRawConfig(String value) {
    return _repository.updateSshFile(SshFileUpdateRequest(value: value));
  }

  Future<PageResult<SshCertInfo>> searchCerts({
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.searchCerts(
      SshCertSearchRequest(page: page, pageSize: pageSize),
    );
  }

  Future<void> createCert(SshCertOperate request) =>
      _repository.createCert(request);

  Future<void> updateCert(SshCertOperate request) =>
      _repository.updateCert(request);

  Future<void> deleteCerts(List<int> ids, {bool forceDelete = false}) {
    return _repository.deleteCerts(ids, forceDelete: forceDelete);
  }

  Future<void> syncCerts() => _repository.syncCerts();

  Future<PageResult<SshLogEntry>> searchLogs(SshLogSearchRequest request) {
    return _repository.searchLogs(request);
  }

  Future<FileSaveResult> exportLogs(SshLogSearchRequest request) async {
    final path = await _repository.exportLogs(request);
    if (path.isEmpty) {
      throw Exception('SSH log export path is empty');
    }
    final fileApi = await _clientManager.getFileApi();
    final response = await fileApi.downloadFile(path);
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('SSH log export is empty');
    }
    final fileName = path.split('/').last;
    return _fileSaveService.saveFile(
      fileName: fileName.isEmpty ? 'ssh-logs.txt' : fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: 'text/plain',
    );
  }

  Future<SshLocalConnectionInfo> loadLocalConnection() {
    return _repository.getLocalConnection();
  }

  Future<bool> checkLocalConnection([SshLocalConnectionInfo? request]) {
    return _repository.checkLocalConnection(request);
  }

  Future<void> updateLocalConnectionVisibility({
    required bool visible,
    bool withReset = false,
  }) {
    return _repository.updateLocalConnectionVisibility(
      visible: visible,
      withReset: withReset,
    );
  }

  Stream<List<SshSessionInfo>> watchSessions() => _repository.watchSessions();

  Future<void> connectSessions(SshSessionQuery query) {
    return _repository.connectSessions(query);
  }

  Future<void> disconnectSession(int pid) => _repository.disconnectSession(pid);

  Future<void> closeSessions() => _repository.closeSessions();

  String listenAddressLabel(SshInfo info) {
    final listenAddress = info.listenAddress.trim();
    if (listenAddress.isEmpty || listenAddress == '0.0.0.0,::') {
      return '0.0.0.0,:::${info.port}';
    }
    return listenAddress;
  }
}
