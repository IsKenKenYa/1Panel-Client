import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart' as api;
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/features/settings/settings_service.dart';

class _FakeSettingsService extends SettingsService {
  String? lastStoreUrl;
  api.SSHConnectionSave? lastSshRequest;

  dynamic _appStoreConfig = <String, dynamic>{'storeUrl': 'https://store.old'};
  dynamic _sshConnection = <String, dynamic>{
    'host': '10.0.0.1',
    'port': 22,
    'user': 'root',
  };

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
  Future<dynamic> getSSHConnection() async {
    return _sshConnection;
  }

  @override
  Future<void> updateAppStoreConfig(api.AppStoreConfigUpdate request) async {
    lastStoreUrl = request.storeUrl;
    _appStoreConfig = <String, dynamic>{'storeUrl': request.storeUrl};
  }

  @override
  Future<void> saveSSHConnection(api.SSHConnectionSave request) async {
    lastSshRequest = request;
    _sshConnection = <String, dynamic>{
      'host': request.host,
      'port': request.port,
      'user': request.user,
    };
  }
}

void main() {
  group('SettingsProvider', () {
    test('load also hydrates app store, auth and ssh summary data', () async {
      final service = _FakeSettingsService();
      final provider = SettingsProvider(service: service);

      await provider.load();

      expect(provider.data.systemSettings?.panelName, 'Demo Panel');
      expect(provider.data.networkInterfaces, contains('eth0'));
      expect((provider.data.appStoreConfig as Map)['storeUrl'],
          'https://store.old');
      expect((provider.data.authSetting as Map)['captcha'], isTrue);
      expect((provider.data.sshConnection as Map)['host'], '10.0.0.1');
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
      expect(service.lastSshRequest?.host, '10.0.0.2');
      expect(service.lastSshRequest?.port, 2222);
      expect((provider.data.sshConnection as Map)['host'], '10.0.0.2');
      expect((provider.data.sshConnection as Map)['port'], 2222);
    });
  });
}
