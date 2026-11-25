import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/storage/platform_secure_storage.dart';
import 'package:onepanel_client/features/server/server_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const namespace = 'credential_persistence_test.';
  const phase = String.fromEnvironment(
    'STORAGE_CHECK_PHASE',
    defaultValue: 'write',
  );
  const repository = ServerRepository();

  setUpAll(() {
    SharedPreferences.setPrefix('kenpanel.credential_persistence_test.');
    ApiConfigManager.useStorageNamespace(namespace);
  });

  testWidgets('服务器凭据跨进程保存与读取（$phase）', (_) async {
    const id = 'persistence-server';
    final storage = await PlatformSecureStorage.create(namespace: namespace);
    final platformStorage = await PlatformSecureStorage.create();
    const platformKey = 'credential_persistence_test.platform_key';
    if (phase == 'write') {
      await platformStorage.write(key: platformKey, value: 'platform-test-value');
      expect(await platformStorage.read(key: platformKey), 'platform-test-value');
      await ApiConfigManager.clearServerDirectory();
      await storage.deleteAll();
      expect((await ApiConfigManager.getServerDirectory()).servers, isEmpty);
      await repository.saveConfig(ApiConfig(
        id: id,
        name: 'Persistence test',
        url: 'https://panel.example.com',
        apiKey: 'persistence-test-key',
        additionalCredentials: const {'appId': 'test-app'},
      ));
      final saved = await repository.readConfig(id);
      expect(saved.apiKey, 'persistence-test-key');
      expect((await ApiConfigManager.getServerDirectory()).selectedId, id);
      return;
    }
    expect(phase, 'read');
    addTearDown(() async {
      await ApiConfigManager.clearServerDirectory();
      await storage.deleteAll();
      await platformStorage.delete(key: platformKey);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    });
    expect(await platformStorage.read(key: platformKey), 'platform-test-value');
    final saved = await repository.readConfig(id);
    expect(saved.apiKey, 'persistence-test-key');
    expect(saved.additionalCredentials, {'appId': 'test-app'});
    expect((await ApiConfigManager.getServerDirectory()).selectedId, id);

    await repository.updateConfig(
      ApiConfig(
        id: id,
        name: 'Edited panel',
        url: saved.url,
        apiKey: 'updated-test-key',
      ),
      expected: saved,
    );
    final edited = await repository.readConfig(id);
    expect(edited.name, 'Edited panel');
    expect(edited.apiKey, 'updated-test-key');

    await repository.removeConfig(id);
    final directory = await ApiConfigManager.getServerDirectory();
    expect(directory.servers, isEmpty);
    expect(directory.selectedId, isNull);
  });
}
