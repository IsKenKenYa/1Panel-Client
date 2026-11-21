import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/features/settings/settings_service.dart';

class _FakeSettingsService extends SettingsService {
  String? lastStoreUrl;
  String? lastSshAddr;
  int? lastSshPort;
  String? lastSystemSettingKey;
  String? lastSystemSettingValue;
  dynamic settingsAvailability = true;
  int checkSettingsAvailableCallCount = 0;

  dynamic _appStoreConfig = <String, dynamic>{'storeUrl': 'https://store.old'};
  SshLocalConnectionInfo _sshConnection = const SshLocalConnectionInfo(
    addr: '10.0.0.1',
    port: 22,
    user: 'root',
  );

  @override
  Future<SystemSettingInfo?> getSystemSettings() async {
    return const SystemSettingInfo(panelName: 'Demo Panel');
  }

  @override
  Future<TerminalInfo?> getTerminalSettings() async {
    return const TerminalInfo(fontSize: '14');
  }

  @override
  Future<List<String>?> getNetworkInterfaces() async {
    return const <String>['eth0', 'wlan0'];
  }

  @override
  Future<dynamic> getAppStoreConfig() async {
    return _appStoreConfig;
  }

  @override
  Future<dynamic> getAuthSetting() async {
    return const <String, dynamic>{'captcha': true};
  }

  @override
  Future<SshLocalConnectionInfo> getSSHConnection() async {
    return _sshConnection;
  }

  @override
  Future<void> updateAppStoreConfig(String? storeUrl) async {
    lastStoreUrl = storeUrl;
    _appStoreConfig = <String, dynamic>{'storeUrl': storeUrl};
  }

  @override
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
    lastSshAddr = addr;
    lastSshPort = port;
    _sshConnection = SshLocalConnectionInfo(
      addr: addr ?? '',
      port: port ?? 22,
      user: user ?? '',
      authMode: authMode ?? 'password',
      password: password,
      privateKey: privateKey,
      passPhrase: passPhrase,
      localSSHConnShow:
          localSSHConnShow ?? _sshConnection.localSSHConnShow,
    );
  }

  @override
  Future<dynamic> checkSettingsAvailable() async {
    checkSettingsAvailableCallCount += 1;
    return settingsAvailability;
  }

  @override
  Future<void> updateSystemSetting(String key, String value) async {
    lastSystemSettingKey = key;
    lastSystemSettingValue = value;
  }
}

void main() {
  group('SettingsProvider', () {
    test('loads panel settings and reads each detail on demand', () async {
      final service = _FakeSettingsService();
      final provider = SettingsProvider(service: service);

      await provider.load();

      expect(provider.data.systemSettings?.panelName, 'Demo Panel');
      expect(provider.data.appStoreConfig, isNull);
      expect(provider.data.authSetting, isNull);
      expect(provider.data.sshConnection, isNull);
      expect(provider.data.networkInterfaces, isNull);
      await provider.loadNetworkInterfaces();
      await provider.loadAppStoreConfig();
      await provider.loadAuthSetting();
      await provider.loadSSHConnection();
      expect(provider.data.networkInterfaces, contains('eth0'));
      expect((provider.data.appStoreConfig as Map)['storeUrl'],
          'https://store.old');
      expect((provider.data.authSetting as Map)['captcha'], isTrue);
      expect(provider.data.sshConnection?.addr, '10.0.0.1');
    });

    test('updateAppStoreConfig writes and reloads latest value', () async {
      final service = _FakeSettingsService();
      final provider = SettingsProvider(service: service);

      final ok = await provider.updateAppStoreConfig('https://store.new');

      expect(ok, isTrue);
      expect(service.lastStoreUrl, 'https://store.new');
      expect((provider.data.appStoreConfig as Map)['storeUrl'],
          'https://store.new');
    });

    test('saveSSHConnection writes and reloads latest summary', () async {
      final service = _FakeSettingsService();
      final provider = SettingsProvider(service: service);

      final ok = await provider.saveSSHConnection(
        host: '10.0.0.2',
        port: 2222,
        user: 'admin',
      );

      expect(ok, isTrue);
      expect(service.lastSshAddr, '10.0.0.2');
      expect(service.lastSshPort, 2222);
      expect(provider.data.sshConnection?.addr, '10.0.0.2');
      expect(provider.data.sshConnection?.port, 2222);
    });

    test('updateSystemSetting checks availability before update', () async {
      final service = _FakeSettingsService();
      final provider = SettingsProvider(service: service);

      final ok = await provider.updateSystemSetting('panelName', 'Panel X');

      expect(ok, isTrue);
      expect(service.checkSettingsAvailableCallCount, 1);
      expect(service.lastSystemSettingKey, 'panelName');
      expect(service.lastSystemSettingValue, 'Panel X');
    });

    test('updateSystemSetting stops when setting is unavailable', () async {
      final service = _FakeSettingsService()..settingsAvailability = false;
      final provider = SettingsProvider(service: service);

      final ok = await provider.updateSystemSetting('panelName', 'Panel Y');

      expect(ok, isFalse);
      expect(service.checkSettingsAvailableCallCount, 1);
      expect(service.lastSystemSettingKey, isNull);
      expect(provider.data.error, contains('更新系统设置失败'));
    });
  });
}
