import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'settings_data.dart';
import 'settings_service.dart';
import '../../data/models/setting_models.dart';
import '../../core/services/logger/logger_service.dart';

const String _settingsProviderPackage = 'features.settings.settings_provider';

class SettingsProvider extends ChangeNotifier with SafeChangeNotifier {
  SettingsProvider({
    SettingsService? service,
    this.serverUrl,
  }) : _service = service ?? SettingsService();

  SettingsProvider.forServer(ApiConfig server)
      : this(service: SettingsService.forServer(server), serverUrl: server.url);

  final String? serverUrl;
  SettingsData _data = const SettingsData();
  final SettingsService _service;

  SettingsData get data => _data;
  String? _loadError;
  String? get loadError => _loadError;
  int _loadGeneration = 0;

  void _setError(
    String action,
    Object error, {
    StackTrace? stackTrace,
  }) {
    appLogger.eWithPackage(
      _settingsProviderPackage,
      '$action failed',
      error: error,
      stackTrace: stackTrace,
    );
    _data = _data.copyWith(
      isLoading: false,
      isRefreshing: false,
      error: '$action失败: ${ErrorMessageUtils.userFacingMessage(error)}',
    );
    notifyListeners();
  }

  /// The server API returns this value as inconsistent types (bool, num,
  /// String, Map, List) across different versions, so every branch must be
  /// handled defensively.
  bool _isSystemSettingsAvailable(dynamic status) {
    if (status == null) {
      return true;
    }
    if (status is bool) {
      return status;
    }
    if (status is num) {
      return status != 0;
    }
    if (status is String) {
      final normalized = status.trim().toLowerCase();
      if (normalized.isEmpty) {
        return true;
      }
      if (normalized == 'false' ||
          normalized == 'disable' ||
          normalized == 'disabled' ||
          normalized == '0' ||
          normalized == 'no') {
        return false;
      }
      if (normalized == 'true' ||
          normalized == 'enable' ||
          normalized == 'enabled' ||
          normalized == '1' ||
          normalized == 'yes') {
        return true;
      }
      return true;
    }
    if (status is Map) {
      final map = status.cast<dynamic, dynamic>();
      for (final key in <String>[
        'available',
        'isAvailable',
        'status',
        'enabled',
        'enable',
        'value',
      ]) {
        if (map.containsKey(key)) {
          return _isSystemSettingsAvailable(map[key]);
        }
      }
      return true;
    }
    if (status is List && status.length == 1) {
      return _isSystemSettingsAvailable(status.first);
    }
    return true;
  }

  Future<void> loadSystemSettings() async {
    final generation = ++_loadGeneration;
    final hasData = _data.systemSettings != null;
    _loadError = null;
    _data = _data.copyWith(isLoading: !hasData, isRefreshing: hasData);
    notifyListeners();

    try {
      final settings = await _service.getSystemSettings();
      if (generation != _loadGeneration || isDisposed) return;
      if (settings == null) throw const FormatException('Missing panel settings');
      _data = _data.copyWith(
        systemSettings: settings,
        isLoading: false,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    } catch (e, stackTrace) {
      if (generation != _loadGeneration || isDisposed) return;
      _loadError = ErrorMessageUtils.userFacingMessage(e);
      _setError('加载系统设置', e, stackTrace: stackTrace);
    }
  }

  Future<bool> loadTerminalSettings() async {
    try {
      final settings = await _service.getTerminalSettings();
      if (settings == null) throw const FormatException('Missing terminal settings');
      _data = _data.copyWith(terminalSettings: settings);
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _setError('加载终端设置', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> loadNetworkInterfaces() async {
    try {
      final interfaces = await _service.getNetworkInterfaces();

      _data = _data.copyWith(networkInterfaces: interfaces);
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _setError('加载网络接口', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> loadDashboardMemo() async {
    _data = _data.copyWith(isMemoLoading: true);
    notifyListeners();

    try {
      final memo = await _service.getDashboardMemo();
      _data = _data.copyWith(
        dashboardMemo: memo,
        isMemoLoading: false,
      );
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        _settingsProviderPackage,
        'loadDashboardMemo failed',
        error: e,
        stackTrace: stackTrace,
      );
      _data = _data.copyWith(
        isMemoLoading: false,
        error: '加载仪表盘备忘录失败: ${ErrorMessageUtils.userFacingMessage(e)}',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDashboardMemo(String content) async {
    _data = _data.copyWith(isMemoSaving: true, error: null);
    notifyListeners();

    try {
      await _service.updateDashboardMemo(content);
      _data = _data.copyWith(
        dashboardMemo: content,
        isMemoSaving: false,
      );
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        _settingsProviderPackage,
        'updateDashboardMemo failed',
        error: e,
        stackTrace: stackTrace,
      );
      _data = _data.copyWith(
        isMemoSaving: false,
        error: '更新仪表盘备忘录失败: ${ErrorMessageUtils.userFacingMessage(e)}',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadAppStoreConfig() async {
    try {
      final config = await _service.getAppStoreConfig();
      _data = _data.copyWith(appStoreConfig: config);
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _setError('加载应用商店配置', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> loadAuthSetting() async {
    try {
      final setting = await _service.getAuthSetting();
      _data = _data.copyWith(authSetting: setting);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载认证设置', e, stackTrace: stackTrace);
    }
  }

  Future<bool> loadSSHConnection() async {
    try {
      final connection = await _service.getSSHConnection();
      _data = _data.copyWith(sshConnection: connection);
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _setError('加载SSH连接', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> loadUpgradeInfo() async {
    try {
      final upgradeInfo = await _service.getUpgradeInfo();

      _data = _data.copyWith(upgradeInfo: upgradeInfo);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载升级信息', e, stackTrace: stackTrace);
    }
  }

  Future<void> loadSnapshots() async {
    try {
      final result = await _service.searchSnapshots();
      _data = _data.copyWith(snapshots: result?['items'] as List<dynamic>?);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载快照列表', e, stackTrace: stackTrace);
    }
  }

  Future<bool> updateSystemSetting(String key, String value) async {
    try {
      final availableStatus = await _service.checkSettingsAvailable();
      if (!_isSystemSettingsAvailable(availableStatus)) {
        throw StateError('系统设置当前不可更新');
      }

      await _service.updateSystemSetting(key, value);
      await loadSystemSettings();
      return true;
    } catch (e, stackTrace) {
      _setError('更新系统设置', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> updateTerminalSettings({
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
    try {
      await _service.updateTerminalSettings(
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
      );
      await loadTerminalSettings();
      return true;
    } catch (e, stackTrace) {
      _setError('更新终端设置', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> updateProxySettings({
    String? proxyUrl,
    int? proxyPort,
  }) async {
    try {
      await _service.updateProxySettings(
        proxyUrl: proxyUrl,
        proxyPort: proxyPort,
      );
      await loadSystemSettings();
      return true;
    } catch (e, stackTrace) {
      _setError('更新代理设置', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> updateAppStoreConfig(String? storeUrl) async {
    try {
      await _service.updateAppStoreConfig(storeUrl);
      await loadAppStoreConfig();
      return true;
    } catch (e, stackTrace) {
      _setError('更新应用商店配置', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> saveSSHConnection({
    String? host,
    int? port,
    String? user,
    String? password,
    String? privateKey,
    String? passPhrase,
  }) async {
    try {
      final authMode =
          (privateKey != null && privateKey.trim().isNotEmpty) ? 'key' : 'password';
      await _service.saveSSHConnection(
        addr: host,
        port: port,
        user: user,
        authMode: authMode,
        password: password,
        privateKey: privateKey,
        passPhrase: passPhrase,
        localSSHConnShow: _data.sshConnection?.localSSHConnShow,
      );
      await loadSSHConnection();
      return true;
    } catch (e, stackTrace) {
      _setError('保存SSH连接', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> checkSSHConnection({
    String? host,
    int? port,
    String? user,
    String? authMode,
    String? password,
    String? privateKey,
    String? passPhrase,
  }) async {
    try {
      return await _service.checkSSHConnection(
        addr: host,
        port: port,
        user: user,
        authMode: authMode,
        password: password,
        privateKey: privateKey,
        passPhrase: passPhrase,
      );
    } catch (e, stackTrace) {
      _setError('测试SSH连接', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> updateDefaultSSHConnectionVisibility({
    required bool visible,
    bool withReset = false,
  }) async {
    try {
      await _service.updateDefaultSSHConnection(
        visible: visible,
        withReset: withReset,
      );
      await loadSSHConnection();
      return true;
    } catch (e, stackTrace) {
      _setError('更新默认SSH连接显示', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> createSnapshot({
    String? description,
    required String sourceAccountIDs,
    required int downloadAccountID,
  }) async {
    appLogger.dWithPackage(
      _settingsProviderPackage,
      'createSnapshot: source=$sourceAccountIDs download=$downloadAccountID',
    );
    try {
      await _service.createSnapshot(
        description: description,
        sourceAccountIDs: sourceAccountIDs,
        downloadAccountID: downloadAccountID,
      );
      await loadSnapshots();
      return true;
    } catch (e, stackTrace) {
      _setError('创建快照', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> loadBackupAccountOptions() async {
    try {
      final result = await _service.getBackupAccountOptions();
      appLogger.dWithPackage(
        _settingsProviderPackage,
        'loadBackupAccountOptions count=${result?.length ?? 0}',
      );
      return result;
    } catch (e, stackTrace) {
      _setError('加载备份账户选项', e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<bool> deleteSnapshot(List<int> ids) async {
    try {
      await _service.deleteSnapshot(ids);
      await loadSnapshots();
      return true;
    } catch (e, stackTrace) {
      _setError('删除快照', e, stackTrace: stackTrace);
      return false;
    }
  }

  // recover/rollback may restart the server, so we don't call loadSnapshots()
  // afterwards -- an immediate refresh would be unreliable.
  Future<bool> recoverSnapshot(int id) async {
    try {
      await _service.recoverSnapshot(id);
      return true;
    } catch (e, stackTrace) {
      _setError('恢复快照', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> rollbackSnapshot(int id) async {
    try {
      await _service.rollbackSnapshot(id);
      return true;
    } catch (e, stackTrace) {
      _setError('回滚快照', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> importSnapshot(String path) async {
    try {
      await _service.importSnapshot(path);
      await loadSnapshots();
      return true;
    } catch (e, stackTrace) {
      _setError('导入快照', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> updateSnapshotDescription(int id, String description) async {
    try {
      await _service.updateSnapshotDescription(id, description);
      await loadSnapshots();
      return true;
    } catch (e, stackTrace) {
      _setError('更新快照描述', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> upgrade({String? version}) async {
    try {
      await _service.upgrade(version: version);
      return true;
    } catch (e, stackTrace) {
      _setError('执行升级', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<List<dynamic>?> getUpgradeReleases() async {
    try {
      return await _service.getUpgradeReleases();
    } catch (e, stackTrace) {
      _setError('获取升级版本列表', e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<String?> getReleaseNotes(String version) async {
    try {
      return await _service.getReleaseNotes(version);
    } catch (e, stackTrace) {
      _setError('获取发布说明', e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> load() async {
    if (_data.isLoading || _data.isRefreshing) return;
    await loadSystemSettings();
  }

  Future<void> refresh() => load();

  void clearError() {
    _data = _data.copyWith(error: null);
    notifyListeners();
  }
}
