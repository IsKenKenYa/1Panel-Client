import 'package:flutter/foundation.dart';
import 'settings_service.dart';
import '../../api/v2/setting_v2.dart' as api;
import '../../data/models/setting_models.dart';
import '../../core/services/logger/logger_service.dart';

const String _settingsProviderPackage = 'features.settings.settings_provider';

class SettingsData {
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final SystemSettingInfo? systemSettings;
  final TerminalInfo? terminalSettings;
  final List<String>? networkInterfaces;
  final MfaOtp? mfaInfo;
  final MfaStatus? mfaStatus;
  final dynamic sslInfo;
  final dynamic upgradeInfo;
  final List<dynamic>? snapshots;
  final DateTime? lastUpdated;

  const SettingsData({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.systemSettings,
    this.terminalSettings,
    this.networkInterfaces,
    this.mfaInfo,
    this.mfaStatus,
    this.sslInfo,
    this.upgradeInfo,
    this.snapshots,
    this.lastUpdated,
  });

  SettingsData copyWith({
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    SystemSettingInfo? systemSettings,
    TerminalInfo? terminalSettings,
    List<String>? networkInterfaces,
    MfaOtp? mfaInfo,
    MfaStatus? mfaStatus,
    dynamic sslInfo,
    dynamic upgradeInfo,
    List<dynamic>? snapshots,
    DateTime? lastUpdated,
  }) {
    return SettingsData(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      systemSettings: systemSettings ?? this.systemSettings,
      terminalSettings: terminalSettings ?? this.terminalSettings,
      networkInterfaces: networkInterfaces ?? this.networkInterfaces,
      mfaInfo: mfaInfo ?? this.mfaInfo,
      mfaStatus: mfaStatus ?? this.mfaStatus,
      sslInfo: sslInfo ?? this.sslInfo,
      upgradeInfo: upgradeInfo ?? this.upgradeInfo,
      snapshots: snapshots ?? this.snapshots,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  SettingsData _data = const SettingsData();
  final SettingsService _service = SettingsService();

  SettingsData get data => _data;

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
      error: '$action失败: $error',
    );
    notifyListeners();
  }

  Future<void> loadSystemSettings() async {
    _data = _data.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final settings = await _service.getSystemSettings();

      _data = _data.copyWith(
        systemSettings: settings,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载系统设置', e, stackTrace: stackTrace);
    }
  }

  Future<void> loadTerminalSettings() async {
    try {
      final settings = await _service.getTerminalSettings();

      _data = _data.copyWith(terminalSettings: settings);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载终端设置', e, stackTrace: stackTrace);
    }
  }

  Future<void> loadNetworkInterfaces() async {
    try {
      final interfaces = await _service.getNetworkInterfaces();

      _data = _data.copyWith(networkInterfaces: interfaces);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载网络接口', e, stackTrace: stackTrace);
    }
  }

  Future<void> loadMfaInfo(MfaCredential request) async {
    try {
      final mfaInfo = await _service.loadMfaInfo(request);

      _data = _data.copyWith(mfaInfo: mfaInfo);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载MFA信息', e, stackTrace: stackTrace);
    }
  }

  Future<MfaOtp?> loadMfaOtp() async {
    try {
      final mfaInfo = await _service.loadMfaInfo(const MfaCredential(
        code: '',
        interval: '30',
        secret: '',
      ));
      _data = _data.copyWith(mfaInfo: mfaInfo);
      notifyListeners();
      return mfaInfo;
    } catch (e, stackTrace) {
      _setError('加载MFA OTP', e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> loadMfaStatus() async {
    try {
      final status = await _service.getMfaStatus();

      _data = _data.copyWith(mfaStatus: status);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载MFA状态', e, stackTrace: stackTrace);
    }
  }

  Future<void> loadSSLInfo() async {
    try {
      final sslInfo = await _service.getSSLInfo();

      _data = _data.copyWith(sslInfo: sslInfo);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载SSL信息', e, stackTrace: stackTrace);
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
      final result = await _service.searchSnapshots(api.SnapshotSearch());
      _data = _data.copyWith(snapshots: result?['items'] as List<dynamic>?);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载快照列表', e, stackTrace: stackTrace);
    }
  }

  Future<bool> updateSystemSetting(String key, String value) async {
    try {
      await _service
          .updateSystemSetting(api.SettingUpdate(key: key, value: value));
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
    String? cursorStyle,
    String? cursorBlink,
    String? scrollSensitivity,
    String? scrollback,
    String? lineHeight,
    String? letterSpacing,
  }) async {
    try {
      await _service.updateTerminalSettings(
        api.TerminalUpdate(
          lineTheme: lineTheme,
          fontSize: fontSize,
          fontFamily: fontFamily,
          cursorStyle: cursorStyle,
          cursorBlink: cursorBlink,
          scrollSensitivity: scrollSensitivity,
          scrollback: scrollback,
          lineHeight: lineHeight,
          letterSpacing: letterSpacing,
        ),
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
      await _service.updateProxySettings(api.ProxyUpdate(
        proxyUrl: proxyUrl,
        proxyPort: proxyPort,
      ));
      await loadSystemSettings();
      return true;
    } catch (e, stackTrace) {
      _setError('更新代理设置', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> bindMfa(MfaBindRequest request) async {
    try {
      await _service.bindMfa(request);
      await loadMfaStatus();
      return true;
    } catch (e, stackTrace) {
      _setError('绑定MFA', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> bindMfaWithCode(
      String code, String secret, String interval) async {
    try {
      await _service.bindMfa(MfaBindRequest(
        code: code,
        secret: secret,
        interval: interval,
      ));
      await loadMfaStatus();
      return true;
    } catch (e, stackTrace) {
      _setError('使用验证码绑定MFA', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> unbindMfa(String code) async {
    try {
      await _service.unbindMfa({'code': code});
      await loadMfaStatus();
      return true;
    } catch (e, stackTrace) {
      _setError('解绑MFA', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    try {
      await _service.updatePasswordSettings(api.PasswordUpdate(
        oldPassword: oldPassword,
        newPassword: newPassword,
      ));
      return true;
    } catch (e, stackTrace) {
      _setError('更新密码', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> generateApiKey() async {
    try {
      final result = await _service.generateApiKey();
      if (result != null) {
        await loadSystemSettings();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _setError('生成API Key', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> updateApiConfig({
    required String status,
    required String ipWhiteList,
    required int validityTime,
  }) async {
    try {
      await _service.updateApiConfig(api.ApiConfigUpdate(
        status: status,
        ipWhiteList: ipWhiteList,
        validityTime: validityTime,
      ));
      await loadSystemSettings();
      return true;
    } catch (e, stackTrace) {
      _setError('更新API配置', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> updateSSL({
    required String domain,
    required String sslType,
    required String cert,
    required String key,
  }) async {
    try {
      await _service.updateSSL(api.SSLUpdate(
        domain: domain,
        sslType: sslType,
        cert: cert,
        key: key,
      ));
      await loadSSLInfo();
      return true;
    } catch (e, stackTrace) {
      _setError('更新SSL配置', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> downloadSSL() async {
    try {
      await _service.downloadSSL();
      return true;
    } catch (e, stackTrace) {
      _setError('下载SSL', e, stackTrace: stackTrace);
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
      await _service.createSnapshot(api.SnapshotCreate(
        description: description,
        sourceAccountIDs: sourceAccountIDs,
        downloadAccountID: downloadAccountID,
      ));
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
      await _service.deleteSnapshot(api.SnapshotDelete(ids: ids));
      await loadSnapshots();
      return true;
    } catch (e, stackTrace) {
      _setError('删除快照', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> recoverSnapshot(int id) async {
    try {
      await _service.recoverSnapshot(api.SnapshotRecover(id: id));
      return true;
    } catch (e, stackTrace) {
      _setError('恢复快照', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> rollbackSnapshot(int id) async {
    try {
      await _service.rollbackSnapshot(api.SnapshotRollback(id: id));
      return true;
    } catch (e, stackTrace) {
      _setError('回滚快照', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> importSnapshot(String path) async {
    try {
      await _service.importSnapshot(api.SnapshotImport(path: path));
      await loadSnapshots();
      return true;
    } catch (e, stackTrace) {
      _setError('导入快照', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> updateSnapshotDescription(int id, String description) async {
    try {
      await _service.updateSnapshotDescription(
          api.SnapshotDescriptionUpdate(id: id, description: description));
      await loadSnapshots();
      return true;
    } catch (e, stackTrace) {
      _setError('更新快照描述', e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> upgrade({String? version}) async {
    try {
      await _service.upgrade(api.UpgradeRequest(version: version));
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
    _data = _data.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getSystemSettings(),
        _service.getTerminalSettings(),
        _service.getNetworkInterfaces(),
      ]);

      _data = _data.copyWith(
        systemSettings: results[0] as SystemSettingInfo?,
        terminalSettings: results[1] as TerminalInfo?,
        networkInterfaces: results[2] as List<String>?,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载设置数据', e, stackTrace: stackTrace);
    }
  }

  Future<void> refresh() async {
    _data = _data.copyWith(isRefreshing: true, error: null);
    notifyListeners();

    try {
      await load();
      _data = _data.copyWith(isRefreshing: false);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('刷新设置数据', e, stackTrace: stackTrace);
    }
  }

  void clearError() {
    _data = _data.copyWith(error: null);
    notifyListeners();
  }
}
