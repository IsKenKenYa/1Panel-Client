import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';

/// Immutable snapshot of all settings UI state.
///
/// Extracted from settings_provider.dart to keep the provider file under
/// the 1000 LOC hard limit (architecture review R5 candidate 2).
class SettingsData {
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final SystemSettingInfo? systemSettings;
  final TerminalInfo? terminalSettings;
  final List<String>? networkInterfaces;
  final dynamic upgradeInfo;
  final dynamic appStoreConfig;
  final dynamic authSetting;
  final SshLocalConnectionInfo? sshConnection;
  final String? dashboardMemo;
  final bool isMemoLoading;
  final bool isMemoSaving;
  final List<dynamic>? snapshots;
  final DateTime? lastUpdated;

  const SettingsData({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.systemSettings,
    this.terminalSettings,
    this.networkInterfaces,
    this.upgradeInfo,
    this.appStoreConfig,
    this.authSetting,
    this.sshConnection,
    this.dashboardMemo,
    this.isMemoLoading = false,
    this.isMemoSaving = false,
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
    dynamic upgradeInfo,
    dynamic appStoreConfig,
    dynamic authSetting,
    SshLocalConnectionInfo? sshConnection,
    String? dashboardMemo,
    bool? isMemoLoading,
    bool? isMemoSaving,
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
      upgradeInfo: upgradeInfo ?? this.upgradeInfo,
      appStoreConfig: appStoreConfig ?? this.appStoreConfig,
      authSetting: authSetting ?? this.authSetting,
      sshConnection: sshConnection ?? this.sshConnection,
      dashboardMemo: dashboardMemo ?? this.dashboardMemo,
      isMemoLoading: isMemoLoading ?? this.isMemoLoading,
      isMemoSaving: isMemoSaving ?? this.isMemoSaving,
      snapshots: snapshots ?? this.snapshots,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
