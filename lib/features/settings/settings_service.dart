import 'package:onepanel_client/api/v2/setting_v2.dart' as api;
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
import 'package:onepanel_client/data/repositories/setting_repository.dart';

/// Settings business service.
///
/// The interface exposes **business-semantic parameters** (atomic values), not
/// API-layer DTOs. DTO construction lives inside this implementation so the
/// State layer (Provider) never imports `setting_v2.dart`. This keeps the seam
/// between State and API/Infra intact — see AGENTS.md architecture rules.
class SettingsService {
  SettingsService({SettingRepository? repository})
      : _repository = repository ?? SettingRepository();

  SettingsService.forServer(ApiConfig server)
      : _repository = SettingRepository.forServer(server);

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

  Future<dynamic> getUpgradeInfo() async {
    final apiClient = await _getApi();
    final response = await apiClient.getUpgradeInfo();
    return response.data;
  }

  Future<void> upgrade({String? version}) async {
    final apiClient = await _getApi();
    await apiClient.upgrade(api.UpgradeRequest(version: version));
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

  Future<dynamic> searchSnapshots() async {
    final apiClient = await _getApi();
    final response = await apiClient.searchSnapshots(api.SnapshotSearch());
    return response.data;
  }

  Future<void> createSnapshot({
    String? description,
    required String sourceAccountIDs,
    required int downloadAccountID,
  }) async {
    final apiClient = await _getApi();
    await apiClient.createSnapshot(api.SnapshotCreate(
      description: description,
      sourceAccountIDs: sourceAccountIDs,
      downloadAccountID: downloadAccountID,
    ));
  }

  Future<void> deleteSnapshot(List<int> ids) async {
    final apiClient = await _getApi();
    await apiClient.deleteSnapshot(api.SnapshotDelete(ids: ids));
  }

  Future<void> recoverSnapshot(int id) async {
    final apiClient = await _getApi();
    await apiClient.recoverSnapshot(api.SnapshotRecover(id: id));
  }

  Future<void> rollbackSnapshot(int id) async {
    final apiClient = await _getApi();
    await apiClient.rollbackSnapshot(api.SnapshotRollback(id: id));
  }

  Future<void> importSnapshot(String path) async {
    final apiClient = await _getApi();
    await apiClient.importSnapshot(api.SnapshotImport(path: path));
  }

  Future<void> updateSnapshotDescription(int id, String description) async {
    final apiClient = await _getApi();
    await apiClient.updateSnapshotDescription(
        api.SnapshotDescriptionUpdate(id: id, description: description));
  }

  Future<void> updateProxySettings({String? proxyUrl, int? proxyPort}) async {
    final apiClient = await _getApi();
    await apiClient.updateProxySettings(api.ProxyUpdate(
      proxyUrl: proxyUrl,
      proxyPort: proxyPort,
    ));
  }

  Future<List<Map<String, dynamic>>?> getBackupAccountOptions() async {
    final apiClient = await _getApi();
    final response = await apiClient.getBackupAccountOptions();
    return response.data;
  }

  Future<void> updateSystemSetting(String key, String value) async {
    final apiClient = await _getApi();
    await apiClient.updateSystemSetting(api.SettingUpdate(key: key, value: value));
  }

  Future<dynamic> checkSettingsAvailable() async {
    final apiClient = await _getApi();
    final response = await apiClient.checkSettingsAvailable();
    return response.data;
  }

  Future<void> updateTerminalSettings({
    String? lineTheme,
    String? fontSize,
    String? fontFamily,
    String? backgroundColor,
    String? foregroundColor,
    String? cursorStyle,
    String? cursorBlink,
    String? scrollSensitivity,
    String? scrollback,
    String? lineHeight,
    String? letterSpacing,
  }) async {
    final apiClient = await _getApi();
    await apiClient.updateTerminalSettings(api.TerminalUpdate(
      lineTheme: lineTheme,
      fontSize: fontSize,
      fontFamily: fontFamily,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      cursorStyle: cursorStyle,
      cursorBlink: cursorBlink,
      scrollSensitivity: scrollSensitivity,
      scrollback: scrollback,
      lineHeight: lineHeight,
      letterSpacing: letterSpacing,
    ));
  }

  // Server API returns menu data in three different formats (List, Map with
  // nested key, or single String) across versions, so all shapes are handled.
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

  Future<void> updateMenuSettings(List<String> menus) async {
    final apiClient = await _getApi();
    await apiClient.updateMenuSettings(api.MenuUpdate(menus: menus));
  }

  Future<dynamic> getAppStoreConfig() async {
    final apiClient = await _getApi();
    final response = await apiClient.getAppStoreConfig();
    return response.data;
  }

  Future<void> updateAppStoreConfig(String? storeUrl) async {
    final apiClient = await _getApi();
    await apiClient.updateAppStoreConfig(
        api.AppStoreConfigUpdate(storeUrl: storeUrl));
  }

  Future<dynamic> getAuthSetting() async {
    final apiClient = await _getApi();
    final response = await apiClient.getAuthSetting();
    return response.data;
  }

  Future<SshLocalConnectionInfo> getSSHConnection() async {
    final apiClient = await _getApi();
    final response = await apiClient.getSSHConnection();
    return response.data ?? const SshLocalConnectionInfo();
  }

  Future<void> saveSSHConnection({
    String? addr,
    int? port,
    String? user,
    String? authMode,
    String? password,
    String? privateKey,
    String? passPhrase,
    String? localSSHConnShow,
  }) async {
    final apiClient = await _getApi();
    await apiClient.saveSSHConnection(api.SSHConnectionSave(
      addr: addr,
      port: port,
      user: user,
      authMode: authMode,
      password: password,
      privateKey: privateKey,
      passPhrase: passPhrase,
      localSSHConnShow: localSSHConnShow,
    ));
  }

  Future<bool> checkSSHConnection({
    String? addr,
    int? port,
    String? user,
    String? authMode,
    String? password,
    String? privateKey,
    String? passPhrase,
  }) async {
    final apiClient = await _getApi();
    final response = await apiClient.checkSSHConnection(api.SSHConnectionCheck(
      addr: addr,
      port: port,
      user: user,
      authMode: authMode,
      password: password,
      privateKey: privateKey,
      passPhrase: passPhrase,
    ));
    return response.data ?? false;
  }

  Future<void> updateDefaultSSHConnection({
    required bool visible,
    bool withReset = false,
  }) async {
    final apiClient = await _getApi();
    await apiClient.updateDefaultSSHConnection(api.SSHDefaultUpdate(
      withReset: withReset,
      defaultConn: visible ? 'Enable' : 'Disable',
    ));
  }

}
