import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
import 'package:onepanel_client/features/settings/settings_data.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/features/settings/settings_service.dart';

class _FakeSettingsService extends SettingsService {
  String? dashboardMemo;
  String? lastMemoUpdate;
  int loadDashboardMemoCount = 0;
  int updateDashboardMemoCount = 0;

  dynamic settingsAvailability = true;
  int checkSettingsAvailableCallCount = 0;

  String? lastTerminalFontSize;
  String? lastTerminalFontFamily;
  String? lastProxyUrl;
  int? lastProxyPort;
  String? lastUpgradeVersion;

  bool shouldThrowOnLoad = false;
  bool shouldThrowOnMemo = false;

  @override
  Future<SystemSettingInfo?> getSystemSettings() async {
    if (shouldThrowOnLoad) throw Exception('load failed');
    return const SystemSettingInfo(panelName: 'Test Panel');
  }

  @override
  Future<TerminalInfo?> getTerminalSettings() async {
    if (shouldThrowOnLoad) throw Exception('load failed');
    return const TerminalInfo(fontSize: '14');
  }

  @override
  Future<List<String>?> getNetworkInterfaces() async {
    if (shouldThrowOnLoad) throw Exception('load failed');
    return const <String>['eth0'];
  }

  @override
  Future<dynamic> getAppStoreConfig() async => <String, dynamic>{};

  @override
  Future<dynamic> getAuthSetting() async => <String, dynamic>{};

  @override
  Future<SshLocalConnectionInfo> getSSHConnection() async {
    return const SshLocalConnectionInfo();
  }

  @override
  Future<String?> getDashboardMemo() async {
    loadDashboardMemoCount++;
    if (shouldThrowOnMemo) throw Exception('memo load failed');
    return dashboardMemo;
  }

  @override
  Future<void> updateDashboardMemo(String content) async {
    updateDashboardMemoCount++;
    if (shouldThrowOnMemo) throw Exception('memo update failed');
    lastMemoUpdate = content;
    dashboardMemo = content;
  }

  @override
  Future<dynamic> checkSettingsAvailable() async {
    checkSettingsAvailableCallCount++;
    return settingsAvailability;
  }

  @override
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
    lastTerminalFontSize = fontSize;
    lastTerminalFontFamily = fontFamily;
  }

  @override
  Future<void> updateProxySettings({String? proxyUrl, int? proxyPort}) async {
    lastProxyUrl = proxyUrl;
    lastProxyPort = proxyPort;
  }

  @override
  Future<void> upgrade({String? version}) async {
    lastUpgradeVersion = version;
  }
}

void main() {
  group('SettingsProvider - loadDashboardMemo', () {
    test('loads memo into data', () async {
      final service = _FakeSettingsService()..dashboardMemo = 'My memo';
      final provider = SettingsProvider(service: service);

      await provider.loadDashboardMemo();

      expect(provider.data.dashboardMemo, 'My memo');
      expect(provider.data.isMemoLoading, isFalse);
      expect(service.loadDashboardMemoCount, 1);
    });

    test('handles null memo', () async {
      final service = _FakeSettingsService()..dashboardMemo = null;
      final provider = SettingsProvider(service: service);

      await provider.loadDashboardMemo();

      expect(provider.data.dashboardMemo, isNull);
      expect(provider.data.isMemoLoading, isFalse);
    });

    test('sets error when memo load fails', () async {
      final service = _FakeSettingsService()..shouldThrowOnMemo = true;
      final provider = SettingsProvider(service: service);

      await provider.loadDashboardMemo();

      expect(provider.data.isMemoLoading, isFalse);
      expect(provider.data.error, contains('备忘录'));
    });
  });

  group('SettingsProvider - updateDashboardMemo', () {
    test('updates memo and returns true', () async {
      final service = _FakeSettingsService();
      final provider = SettingsProvider(service: service);

      final result = await provider.updateDashboardMemo('New memo');

      expect(result, isTrue);
      expect(provider.data.dashboardMemo, 'New memo');
      expect(provider.data.isMemoSaving, isFalse);
      expect(service.lastMemoUpdate, 'New memo');
    });

    test('returns false and sets error when update fails', () async {
      final service = _FakeSettingsService()..shouldThrowOnMemo = true;
      final provider = SettingsProvider(service: service);

      final result = await provider.updateDashboardMemo('Fail memo');

      expect(result, isFalse);
      expect(provider.data.isMemoSaving, isFalse);
      expect(provider.data.error, contains('备忘录'));
    });
  });

  group('SettingsProvider - clearError', () {
    test('clears error and notifies', () async {
      final service = _FakeSettingsService()..settingsAvailability = false;
      final provider = SettingsProvider(service: service);

      await provider.updateSystemSetting('key', 'value');
      expect(provider.data.error, isNotNull);

      provider.clearError();
      expect(provider.data.error, isNull);
    });
  });

  group('SettingsProvider - load() error handling', () {
    test('sets error when main load fails', () async {
      final service = _FakeSettingsService()..shouldThrowOnLoad = true;
      final provider = SettingsProvider(service: service);

      await provider.load();

      expect(provider.data.isLoading, isFalse);
      expect(provider.data.error, isNotNull);
    });

    test('sets isLoading during load', () async {
      final service = _FakeSettingsService();
      final provider = SettingsProvider(service: service);

      final loadFuture = provider.load();

      expect(provider.data.isLoading, isTrue);

      await loadFuture;

      expect(provider.data.isLoading, isFalse);
    });
  });

  group('SettingsProvider - updateTerminalSettings', () {
    test('sends terminal update and reloads', () async {
      final service = _FakeSettingsService();
      final provider = SettingsProvider(service: service);

      final result = await provider.updateTerminalSettings(
        fontSize: '16',
        fontFamily: 'Monaco',
      );

      expect(result, isTrue);
      expect(service.lastTerminalFontSize, '16');
      expect(service.lastTerminalFontFamily, 'Monaco');
    });
  });

  group('SettingsProvider - updateProxySettings', () {
    test('sends proxy update and reloads', () async {
      final service = _FakeSettingsService();
      final provider = SettingsProvider(service: service);

      final result = await provider.updateProxySettings(
        proxyUrl: 'http://proxy.example.com',
        proxyPort: 8080,
      );

      expect(result, isTrue);
      expect(service.lastProxyUrl, 'http://proxy.example.com');
      expect(service.lastProxyPort, 8080);
    });
  });

  group('SettingsProvider - upgrade', () {
    test('sends upgrade request', () async {
      final service = _FakeSettingsService();
      final provider = SettingsProvider(service: service);

      final result = await provider.upgrade(version: '2.0.0');

      expect(result, isTrue);
      expect(service.lastUpgradeVersion, '2.0.0');
    });
  });

  group('SettingsData - copyWith', () {
    test('preserves unmodified fields', () {
      const data = SettingsData(
        isLoading: true,
        dashboardMemo: 'memo',
        isMemoSaving: true,
      );

      final copied = data.copyWith(isLoading: false);

      expect(copied.isLoading, isFalse);
      expect(copied.dashboardMemo, 'memo');
      expect(copied.isMemoSaving, isTrue);
    });

    test('can reset error to null', () {
      const data = SettingsData(error: 'some error');

      final copied = data.copyWith(error: null);

      expect(copied.error, isNull);
    });

    test('default values are correct', () {
      const data = SettingsData();

      expect(data.isLoading, isFalse);
      expect(data.isRefreshing, isFalse);
      expect(data.error, isNull);
      expect(data.systemSettings, isNull);
      expect(data.isMemoLoading, isFalse);
      expect(data.isMemoSaving, isFalse);
    });
  });
}
