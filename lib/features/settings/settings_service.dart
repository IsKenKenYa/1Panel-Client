import 'package:onepanel_client/api/v2/setting_v2.dart' as api;
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/data/repositories/setting_repository.dart';

class SettingsService {
  SettingsService({SettingRepository? repository})
      : _repository = repository ?? SettingRepository();

  final SettingRepository _repository;

  Future<api.SettingV2Api> _getApi() async {
    return _repository.ensureApi();
  }

  void resetForServerChange() {
    _repository.resetForServerChange();
  }

  Future<SystemSettingInfo?> getSystemSettings() async {
    final apiClient = await _getApi();
    final response = await apiClient.getSystemSettings();
    return response.data;
  }

  Future<TerminalInfo?> getTerminalSettings() async {
    final apiClient = await _getApi();
    final response = await apiClient.getTerminalSettings();
    return response.data;
  }

  Future<List<String>?> getNetworkInterfaces() async {
    final apiClient = await _getApi();
    final response = await apiClient.getNetworkInterfaces();
    return response.data;
  }

  Future<String?> getDashboardMemo() async {
    final apiClient = await _getApi();
    final response = await apiClient.getDashboardMemo();
    return response.data;
  }

  Future<void> updateDashboardMemo(String content) async {
    final apiClient = await _getApi();
    await apiClient.updateDashboardMemo(MemoUpdate(content: content));
  }

  Future<List<PasskeyInfo>> listPasskeys() async {
    final apiClient = await _getApi();
    final response = await apiClient.listPasskeys();
    return response.data ?? const <PasskeyInfo>[];
  }

  Future<PasskeyBeginResponse?> beginPasskeyRegister(String name) async {
    final apiClient = await _getApi();
    final response = await apiClient.beginPasskeyRegister(
      PasskeyRegisterRequest(name: name),
    );
    return response.data;
  }

  Future<void> finishPasskeyRegister({
    required String sessionId,
    required Map<String, dynamic> credential,
  }) async {
    final apiClient = await _getApi();
    await apiClient.finishPasskeyRegister(
      sessionId: sessionId,
      credential: credential,
    );
  }

  Future<void> deletePasskey(String id) async {
    final apiClient = await _getApi();
    await apiClient.deletePasskey(id);
  }

  Future<MfaOtp?> loadMfaInfo(MfaLoadRequest request) async {
    final apiClient = await _getApi();
    final response = await apiClient.loadMfaInfo(request);
    return response.data;
  }

  Future<MfaStatus?> getMfaStatus() async {
    final apiClient = await _getApi();
    final response = await apiClient.getMfaStatus();
    return response.data;
  }

  Future<void> bindMfa(MfaBindRequest request) async {
    final apiClient = await _getApi();
    await apiClient.bindMfa(request);
  }

  Future<void> unbindMfa(Map<String, dynamic> request) async {
    final apiClient = await _getApi();
    await apiClient.unbindMfa(request);
  }

  Future<dynamic> getSSLInfo() async {
    final apiClient = await _getApi();
    final response = await apiClient.getSSLInfo();
    return response.data;
  }

  Future<void> updateSSL(api.SSLUpdate request) async {
    final apiClient = await _getApi();
    await apiClient.updateSSL(request);
  }

  Future<void> downloadSSL() async {
    final apiClient = await _getApi();
    await apiClient.downloadSSL();
  }

  Future<dynamic> getUpgradeInfo() async {
    final apiClient = await _getApi();
    final response = await apiClient.getUpgradeInfo();
    return response.data;
  }

  Future<void> upgrade(api.UpgradeRequest request) async {
    final apiClient = await _getApi();
    await apiClient.upgrade(request);
  }

  Future<List<dynamic>?> getUpgradeReleases() async {
    final apiClient = await _getApi();
    final response = await apiClient.getUpgradeReleases();
    return response.data;
  }

  Future<String?> getReleaseNotes(String version) async {
    final apiClient = await _getApi();
    final response = await apiClient
        .getReleaseNotes(api.ReleaseNotesRequest(version: version));
    return response.data;
  }

  Future<dynamic> searchSnapshots(api.SnapshotSearch request) async {
    final apiClient = await _getApi();
    final response = await apiClient.searchSnapshots(request);
    return response.data;
  }

  Future<void> createSnapshot(api.SnapshotCreate request) async {
    final apiClient = await _getApi();
    await apiClient.createSnapshot(request);
  }

  Future<void> deleteSnapshot(api.SnapshotDelete request) async {
    final apiClient = await _getApi();
    await apiClient.deleteSnapshot(request);
  }

  Future<void> recoverSnapshot(api.SnapshotRecover request) async {
    final apiClient = await _getApi();
    await apiClient.recoverSnapshot(request);
  }

  Future<void> rollbackSnapshot(api.SnapshotRollback request) async {
    final apiClient = await _getApi();
    await apiClient.rollbackSnapshot(request);
  }

  Future<void> importSnapshot(api.SnapshotImport request) async {
    final apiClient = await _getApi();
    await apiClient.importSnapshot(request);
  }

  Future<void> updateSnapshotDescription(
      api.SnapshotDescriptionUpdate request) async {
    final apiClient = await _getApi();
    await apiClient.updateSnapshotDescription(request);
  }

  Future<void> updateProxySettings(api.ProxyUpdate request) async {
    final apiClient = await _getApi();
    await apiClient.updateProxySettings(request);
  }

  Future<List<Map<String, dynamic>>?> getBackupAccountOptions() async {
    final apiClient = await _getApi();
    final response = await apiClient.getBackupAccountOptions();
    return response.data;
  }

  Future<void> updateSystemSetting(api.SettingUpdate request) async {
    final apiClient = await _getApi();
    await apiClient.updateSystemSetting(request);
  }

  Future<dynamic> checkSettingsAvailable() async {
    final apiClient = await _getApi();
    final response = await apiClient.checkSettingsAvailable();
    return response.data;
  }

  Future<void> updateTerminalSettings(api.TerminalUpdate request) async {
    final apiClient = await _getApi();
    await apiClient.updateTerminalSettings(request);
  }

  Future<List<String>> getDefaultMenus() async {
    final apiClient = await _getApi();
    final response = await apiClient.getDefaultMenu();
    final raw = response.data;
    if (raw is List<dynamic>) {
      return raw.map((dynamic item) => item.toString()).toList(growable: false);
    }
    if (raw is Map<String, dynamic>) {
      final dynamic menus = raw['menus'] ?? raw['items'] ?? raw['data'];
      if (menus is List<dynamic>) {
        return menus
            .map((dynamic item) => item.toString())
            .toList(growable: false);
      }
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return <String>[raw.trim()];
    }
    return const <String>[];
  }

  Future<void> updateMenuSettings(api.MenuUpdate request) async {
    final apiClient = await _getApi();
    await apiClient.updateMenuSettings(request);
  }

  Future<dynamic> generateApiKey() async {
    final apiClient = await _getApi();
    final response = await apiClient.generateApiKey();
    return response.data;
  }

  Future<dynamic> getAppStoreConfig() async {
    final apiClient = await _getApi();
    final response = await apiClient.getAppStoreConfig();
    return response.data;
  }

  Future<void> updateAppStoreConfig(api.AppStoreConfigUpdate request) async {
    final apiClient = await _getApi();
    await apiClient.updateAppStoreConfig(request);
  }

  Future<dynamic> getAuthSetting() async {
    final apiClient = await _getApi();
    final response = await apiClient.getAuthSetting();
    return response.data;
  }

  Future<dynamic> getSSHConnection() async {
    final apiClient = await _getApi();
    final response = await apiClient.getSSHConnection();
    return response.data;
  }

  Future<void> saveSSHConnection(api.SSHConnectionSave request) async {
    final apiClient = await _getApi();
    await apiClient.saveSSHConnection(request);
  }

  Future<void> updatePasswordSettings(api.PasswordUpdate request) async {
    final apiClient = await _getApi();
    await apiClient.updatePasswordSettings(request);
  }

  Future<void> updateApiConfig(api.ApiConfigUpdate request) async {
    final apiClient = await _getApi();
    await apiClient.updateApiConfig(request);
  }
}
