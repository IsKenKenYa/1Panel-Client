import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_settings_provider.dart';
import 'package:onepanel_client/features/ssh/services/ssh_service.dart';

class _MockSshService extends Mock implements SSHService {}

void main() {
  late _MockSshService service;
  late SshSettingsProvider provider;

  const info = SshInfo(
    autoStart: true,
    isExist: true,
    isActive: true,
    message: 'running',
    port: '22',
    listenAddress: '0.0.0.0,::',
    passwordAuthentication: 'yes',
    pubkeyAuthentication: 'yes',
    permitRootLogin: 'yes',
    useDNS: 'no',
    currentUser: 'root',
  );

  setUpAll(() {
    registerFallbackValue(
      const SshUpdateRequest(key: 'UseDNS', newValue: 'no'),
    );
    registerFallbackValue(
      const SshFileUpdateRequest(value: 'config'),
    );
  });

  setUp(() {
    service = _MockSshService();
    when(() => service.loadInfo()).thenAnswer((_) async => info);
    when(() => service.loadRawConfig()).thenAnswer((_) async => 'config');
    when(() => service.operate(any())).thenAnswer((_) async {});
    when(() => service.updateSetting(
          key: any(named: 'key'),
          oldValue: any(named: 'oldValue'),
          newValue: any(named: 'newValue'),
        )).thenAnswer((_) async {});
    when(() => service.saveRawConfig(any())).thenAnswer((_) async {});
    provider = SshSettingsProvider(service: service);
  });

  test('load hydrates info and raw config', () async {
    await provider.load();

    expect(provider.info?.port, '22');
    expect(provider.rawConfig, 'config');
  });

  test('updateSetting reloads info', () async {
    await provider.load();

    final success = await provider.updateSetting(
      key: 'UseDNS',
      oldValue: 'no',
      newValue: 'yes',
    );

    expect(success, isTrue);
    verify(() => service.updateSetting(
          key: 'UseDNS',
          oldValue: 'no',
          newValue: 'yes',
        )).called(1);
  });
}
