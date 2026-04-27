import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'settings_service.dart';
import '../../api/v2/setting_v2.dart' as api;
import '../../data/models/setting_models.dart';
import '../../data/models/ssh_settings_models.dart';
import '../../core/services/passkey_service.dart';
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
  final dynamic appStoreConfig;
  final dynamic authSetting;
  final SshLocalConnectionInfo? sshConnection;
  final String? dashboardMemo;
  final bool isMemoLoading;
  final bool isMemoSaving;
  final List<PasskeyInfo> passkeys;
  final bool isPasskeysLoading;
  final bool isPasskeyRegistering;
  final String? passkeyDeletingId;
  final bool isPasskeySupported;
  final String? passkeyUnsupportedReason;
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
    this.appStoreConfig,
    this.authSetting,
    this.sshConnection,
    this.dashboardMemo,
    this.isMemoLoading = false,
    this.isMemoSaving = false,
    this.passkeys = const <PasskeyInfo>[],
    this.isPasskeysLoading = false,
    this.isPasskeyRegistering = false,
    this.passkeyDeletingId,
    this.isPasskeySupported = false,
    this.passkeyUnsupportedReason,
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
    dynamic appStoreConfig,
    dynamic authSetting,
    SshLocalConnectionInfo? sshConnection,
    String? dashboardMemo,
    bool? isMemoLoading,
    bool? isMemoSaving,
    List<PasskeyInfo>? passkeys,
    bool? isPasskeysLoading,
    bool? isPasskeyRegistering,
    String? passkeyDeletingId,
    bool? isPasskeySupported,
    String? passkeyUnsupportedReason,
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
      appStoreConfig: appStoreConfig ?? this.appStoreConfig,
      authSetting: authSetting ?? this.authSetting,
      sshConnection: sshConnection ?? this.sshConnection,
      dashboardMemo: dashboardMemo ?? this.dashboardMemo,
      isMemoLoading: isMemoLoading ?? this.isMemoLoading,
      isMemoSaving: isMemoSaving ?? this.isMemoSaving,
      passkeys: passkeys ?? this.passkeys,
      isPasskeysLoading: isPasskeysLoading ?? this.isPasskeysLoading,
      isPasskeyRegistering:
          isPasskeyRegistering ?? this.isPasskeyRegistering,
      passkeyDeletingId: passkeyDeletingId,
      isPasskeySupported: isPasskeySupported ?? this.isPasskeySupported,
      passkeyUnsupportedReason: passkeyUnsupportedReason,
      snapshots: snapshots ?? this.snapshots,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class SettingsProvider extends ChangeNotifier with SafeChangeNotifier {
  SettingsProvider({
    SettingsService? service,
    PasskeyService? passkeyService,
  })  : _service = service ?? SettingsService(),
        _passkeyService = passkeyService ?? PasskeyService();

  SettingsData _data = const SettingsData();
  final SettingsService _service;
  final PasskeyService _passkeyService;

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

  Future<void> loadDashboardMemo() async {
    _data = _data.copyWith(isMemoLoading: true);
    notifyListeners();

    try {
      final memo = await _service.getDashboardMemo();
      _data = _data.copyWith(
        dashboardMemo: memo,
        isMemoLoading: false,
      );
      notifyListeners();
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        _settingsProviderPackage,
        'loadDashboardMemo failed',
        error: e,
        stackTrace: stackTrace,
      );
      _data = _data.copyWith(
        isMemoLoading: false,
        error: '加载仪表盘备忘录失败: $e',
      );
      notifyListeners();
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
        error: '更新仪表盘备忘录失败: $e',
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> loadPasskeys() async {
    _data = _data.copyWith(isPasskeysLoading: true, error: null);
    notifyListeners();

    try {
      final availability = await _passkeyService.getAvailability();
      if (!availability.isSupported) {
        _data = _data.copyWith(
          passkeys: const <PasskeyInfo>[],
          isPasskeysLoading: false,
          isPasskeySupported: false,
          passkeyUnsupportedReason: availability.reason,
        );
        notifyListeners();
        return;
      }

      final items = await _service.listPasskeys();
      _data = _data.copyWith(
        passkeys: items,
        isPasskeysLoading: false,
        isPasskeySupported: true,
        passkeyUnsupportedReason: null,
      );
      notifyListeners();
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        _settingsProviderPackage,
        'loadPasskeys failed',
        error: e,
        stackTrace: stackTrace,
      );
      _data = _data.copyWith(
        isPasskeysLoading: false,
        error: '加载 Passkey 列表失败: $e',
      );
      notifyListeners();
    }
  }

  Future<bool> registerPasskey(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      _data = _data.copyWith(error: 'Passkey 名称不能为空');
      notifyListeners();
      return false;
    }

    _data = _data.copyWith(isPasskeyRegistering: true, error: null);
    notifyListeners();

    try {
      final availability = await _passkeyService.getAvailability();
      if (!availability.isSupported) {
        _data = _data.copyWith(
          isPasskeyRegistering: false,
          isPasskeySupported: false,
          passkeyUnsupportedReason: availability.reason,
          error: availability.reason ?? '当前平台不支持 Passkey',
        );
        notifyListeners();
        return false;
      }

      final begin = await _service.beginPasskeyRegister(normalizedName);
      final sessionId = begin?.sessionId;
      final publicKey = begin?.publicKey;
      if (sessionId == null || sessionId.isEmpty || publicKey is! Map<String, dynamic>) {
        _data = _data.copyWith(
          isPasskeyRegistering: false,
          error: 'Passkey 注册初始化失败',
        );
        notifyListeners();
        return false;
      }

      final credential = await _passkeyService.registerCredential(publicKey);
      await _service.finishPasskeyRegister(
        sessionId: sessionId,
        credential: credential,
      );
      await loadPasskeys();

      _data = _data.copyWith(isPasskeyRegistering: false);
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        _settingsProviderPackage,
        'registerPasskey failed',
        error: e,
        stackTrace: stackTrace,
      );
      _data = _data.copyWith(
        isPasskeyRegistering: false,
        error: _passkeyService.toUserMessage(e),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePasskey(String id) async {
    _data = _data.copyWith(passkeyDeletingId: id, error: null);
    notifyListeners();

    try {
      await _service.deletePasskey(id);
      await loadPasskeys();
      _data = _data.copyWith(passkeyDeletingId: null);
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        _settingsProviderPackage,
        'deletePasskey failed',
        error: e,
        stackTrace: stackTrace,
      );
      _data = _data.copyWith(
        passkeyDeletingId: null,
        error: '删除 Passkey 失败: $e',
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAppStoreConfig() async {
    try {
      final config = await _service.getAppStoreConfig();
      _data = _data.copyWith(appStoreConfig: config);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载应用商店配置', e, stackTrace: stackTrace);
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

  Future<void> loadSSHConnection() async {
    try {
      final connection = await _service.getSSHConnection();
      _data = _data.copyWith(sshConnection: connection);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载SSH连接', e, stackTrace: stackTrace);
    }
  }

  Future<void> loadMfaInfo(MfaLoadRequest request) async {
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
      final mfaInfo = await _service.loadMfaInfo(const MfaLoadRequest(
        title: '1Panel Client',
        interval: 30,
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
      final availableStatus = await _service.checkSettingsAvailable();
      if (!_isSystemSettingsAvailable(availableStatus)) {
        throw StateError('系统设置当前不可更新');
      }

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
        api.TerminalUpdate(
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

  Future<bool> updateAppStoreConfig(String? storeUrl) async {
    try {
      await _service
          .updateAppStoreConfig(api.AppStoreConfigUpdate(storeUrl: storeUrl));
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
        api.SSHConnectionSave(
          addr: host,
          port: port,
          user: user,
          authMode: authMode,
          password: password,
          privateKey: privateKey,
          passPhrase: passPhrase,
          localSSHConnShow: _data.sshConnection?.localSSHConnShow,
        ),
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
        api.SSHConnectionCheck(
          addr: host,
          port: port,
          user: user,
          authMode: authMode,
          password: password,
          privateKey: privateKey,
          passPhrase: passPhrase,
        ),
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
        api.SSHDefaultUpdate(
          withReset: withReset,
          defaultConn: visible ? 'Enable' : 'Disable',
        ),
      );
      await loadSSHConnection();
      return true;
    } catch (e, stackTrace) {
      _setError('更新默认SSH连接显示', e, stackTrace: stackTrace);
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

      dynamic appStoreConfig;
      dynamic authSetting;
      SshLocalConnectionInfo? sshConnection;
      String? dashboardMemo;
      var passkeys = const <PasskeyInfo>[];
      var isPasskeySupported = false;
      String? passkeyUnsupportedReason;

      try {
        appStoreConfig = await _service.getAppStoreConfig();
      } catch (e, stackTrace) {
        appLogger.wWithPackage(
          _settingsProviderPackage,
          '加载应用商店配置失败，继续主链路',
          error: e,
          stackTrace: stackTrace,
        );
      }

      try {
        authSetting = await _service.getAuthSetting();
      } catch (e, stackTrace) {
        appLogger.wWithPackage(
          _settingsProviderPackage,
          '加载认证设置失败，继续主链路',
          error: e,
          stackTrace: stackTrace,
        );
      }

      try {
        sshConnection = await _service.getSSHConnection();
      } catch (e, stackTrace) {
        appLogger.wWithPackage(
          _settingsProviderPackage,
          '加载SSH连接失败，继续主链路',
          error: e,
          stackTrace: stackTrace,
        );
      }

      try {
        dashboardMemo = await _service.getDashboardMemo();
      } catch (e, stackTrace) {
        appLogger.wWithPackage(
          _settingsProviderPackage,
          '加载仪表盘备忘录失败，继续主链路',
          error: e,
          stackTrace: stackTrace,
        );
      }

      try {
        final availability = await _passkeyService.getAvailability();
        isPasskeySupported = availability.isSupported;
        passkeyUnsupportedReason = availability.reason;
        if (availability.isSupported) {
          passkeys = await _service.listPasskeys();
        }
      } catch (e, stackTrace) {
        appLogger.wWithPackage(
          _settingsProviderPackage,
          '加载 Passkey 列表失败，继续主链路',
          error: e,
          stackTrace: stackTrace,
        );
      }

      _data = _data.copyWith(
        systemSettings: results[0] as SystemSettingInfo?,
        terminalSettings: results[1] as TerminalInfo?,
        networkInterfaces: results[2] as List<String>?,
        appStoreConfig: appStoreConfig,
        authSetting: authSetting,
        sshConnection: sshConnection,
        dashboardMemo: dashboardMemo,
        passkeys: passkeys,
        isPasskeySupported: isPasskeySupported,
        passkeyUnsupportedReason: passkeyUnsupportedReason,
        isPasskeysLoading: false,
        isPasskeyRegistering: false,
        passkeyDeletingId: null,
        isMemoLoading: false,
        isMemoSaving: false,
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
