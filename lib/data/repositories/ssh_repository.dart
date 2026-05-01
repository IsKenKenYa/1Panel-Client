import 'dart:async';
import 'dart:convert';

import 'package:onepanel_client/api/v2/ssh_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/network/process_ws_client.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/process_models.dart';
import 'package:onepanel_client/data/models/ssh_cert_models.dart';
import 'package:onepanel_client/data/models/ssh_log_models.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';

class SSHRepository {
  SSHRepository({
    ApiClientManager? clientManager,
    SshV2Api? api,
    ProcessWsClient? wsClient,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api,
        _wsClient = wsClient ?? ProcessWsClient();

  final ApiClientManager _clientManager;
  SshV2Api? _api;
  final ProcessWsClient _wsClient;
  final StreamController<List<SshSessionInfo>> _sessionController =
      StreamController<List<SshSessionInfo>>.broadcast();

  StreamSubscription<dynamic>? _sessionSubscription;

  Future<SshV2Api> _ensureApi() async {
    return _api ??= await _clientManager.getSshApi();
  }

  Future<SshInfo> getSshInfo() async {
    final api = await _ensureApi();
    final response = await api.getSshInfo();
    if (response.data == null) {
      throw Exception('SSH info unavailable');
    }
    return response.data!;
  }

  Future<void> operateSsh(String operation) async {
    final api = await _ensureApi();
    await api.operateSsh(SshOperateRequest(operation: operation));
  }

  Future<void> updateSsh(SshUpdateRequest request) async {
    final api = await _ensureApi();
    await api.updateSsh(request);
  }

  Future<String> loadSshFile([String name = 'sshdConf']) async {
    final api = await _ensureApi();
    final response = await api.loadSshFile(SshFileLoadRequest(name: name));
    return response.data ?? '';
  }

  Future<void> updateSshFile(SshFileUpdateRequest request) async {
    final api = await _ensureApi();
    await api.updateSshFile(request);
  }

  Future<PageResult<SshCertInfo>> searchCerts(
      SshCertSearchRequest request) async {
    final api = await _ensureApi();
    final response = await api.searchSshCerts(request);
    return response.data ??
        const PageResult<SshCertInfo>(items: <SshCertInfo>[], total: 0);
  }

  Future<void> createCert(SshCertOperate request) async {
    final api = await _ensureApi();
    await api.createSshCert(_encodeCert(request));
  }

  Future<void> updateCert(SshCertOperate request) async {
    final api = await _ensureApi();
    await api.updateSshCert(_encodeCert(request));
  }

  Future<void> deleteCerts(List<int> ids, {bool forceDelete = false}) async {
    final api = await _ensureApi();
    await api.deleteSshCerts(ForceDelete(ids: ids, forceDelete: forceDelete));
  }

  Future<void> syncCerts() async {
    final api = await _ensureApi();
    await api.syncSshCerts();
  }

  Future<PageResult<SshLogEntry>> searchLogs(
      SshLogSearchRequest request) async {
    final api = await _ensureApi();
    final response = await api.searchSshLogs(request);
    return response.data ??
        const PageResult<SshLogEntry>(items: <SshLogEntry>[], total: 0);
  }

  Future<String> exportLogs(SshLogSearchRequest request) async {
    final api = await _ensureApi();
    final response = await api.exportSshLogs(request);
    return response.data ?? '';
  }

  Future<SshLocalConnectionInfo> getLocalConnection() async {
    final api = await _ensureApi();
    final response = await api.getSshConn();
    return response.data ?? const SshLocalConnectionInfo();
  }

  Future<bool> checkLocalConnection([SshLocalConnectionInfo? request]) async {
    final api = await _ensureApi();
    final response = await api.checkSshInfo(request: request);
    return response.data ?? false;
  }

  Future<void> updateLocalConnectionVisibility({
    required bool visible,
    bool withReset = false,
  }) async {
    final api = await _ensureApi();
    await api.setDefaultSshConn(
      SshDefaultConnectionVisibilityUpdate(
        withReset: withReset,
        defaultConn: visible ? 'Enable' : 'Disable',
      ),
    );
  }

  Stream<List<SshSessionInfo>> watchSessions() => _sessionController.stream;

  Future<void> connectSessions(SshSessionQuery query) async {
    _sessionSubscription ??= _wsClient.messages.listen((dynamic event) {
      final rawItems = (event as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(SshSessionInfo.fromJson)
          .toList(growable: false);
      _sessionController.add(rawItems);
    }, onError: _sessionController.addError);
    await _wsClient.connect();
    await _wsClient.send(query.toJson());
  }

  Future<void> disconnectSession(int pid) async {
    final processApi = await _clientManager.getProcessApi();
    await processApi.stopProcess(ProcessStopRequest(pid: pid));
  }

  Future<void> closeSessions() async {
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;
    await _wsClient.close();
  }

  SshCertOperate _encodeCert(SshCertOperate request) {
    String encodeIfNeeded(String value) {
      if (value.isEmpty) return value;
      return base64.encode(utf8.encode(value));
    }

    return SshCertOperate(
      id: request.id,
      name: request.name,
      mode: request.mode,
      encryptionMode: request.encryptionMode,
      passPhrase: encodeIfNeeded(request.passPhrase),
      publicKey: encodeIfNeeded(request.publicKey),
      privateKey: encodeIfNeeded(request.privateKey),
      description: request.description,
    );
  }
}
