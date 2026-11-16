@TestOn('browser')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onepanel_client/core/storage/browser_vault.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const password = 'browser-local-password-2026';
  late BrowserVault vault;
  late String boxName;

  setUp(() async {
    await Hive.initFlutter();
    boxName = 'vault_test_${DateTime.now().microsecondsSinceEpoch}';
    vault = BrowserVault(boxName: boxName);
    await vault.initialize();
  });

  tearDown(() async {
    vault.lock();
    if (Hive.isBoxOpen(boxName)) await Hive.box<dynamic>(boxName).close();
    await Hive.deleteBoxFromDisk(boxName);
  });

  test('凭据加密保存在 IndexedDB，重新打开后需要密码', () async {
    await vault.unlock(password);
    await vault.write('api_key', 'private-panel-key');
    final stored = Hive.box<dynamic>(boxName).toMap();
    expect(jsonEncode(stored), isNot(contains('private-panel-key')));
    expect(jsonEncode(stored), isNot(contains(password)));
    vault.lock();
    expect(() => vault.read('api_key'), throwsStateError);
    await Hive.box<dynamic>(boxName).close();
    vault = BrowserVault(boxName: boxName);
    await vault.initialize();
    expect(vault.isConfigured, isTrue);
    expect(vault.isUnlocked, isFalse);
    await vault.unlock(password);
    expect(await vault.read('api_key'), 'private-panel-key');
  });

  test('错误密码保留加密数据并允许正确密码再次解锁', () async {
    await vault.unlock(password);
    await vault.write('api_key', 'preserved-key');
    vault.lock();
    final before = jsonEncode(Hive.box<dynamic>(boxName).toMap());
    await expectLater(vault.unlock('incorrect-password'), throwsA(anything));
    expect(vault.isUnlocked, isFalse);
    expect(jsonEncode(Hive.box<dynamic>(boxName).toMap()), before);
    await vault.unlock(password);
    expect(await vault.read('api_key'), 'preserved-key');
  });

  test('并发写入分别保存，删除只影响指定凭据', () async {
    await vault.unlock(password);
    await Future.wait(List.generate(
      12,
      (i) => vault.write('server_$i', 'credential_$i'),
    ));
    vault.lock();
    await vault.unlock(password);
    for (var i = 0; i < 12; i++) {
      expect(await vault.read('server_$i'), 'credential_$i');
    }
    await vault.delete('server_0');
    expect(await vault.read('server_0'), isNull);
    expect(await vault.read('server_1'), 'credential_1');
  });

  test('浏览器密钥模式重新打开后可读取凭据', () async {
    await vault.unlockWithBrowserKey();
    expect(vault.usesBrowserKey, isTrue);
    await vault.write('api_key', 'browser-protected-key');
    vault.lock();
    await Hive.box<dynamic>(boxName).close();
    vault = BrowserVault(boxName: boxName);
    await vault.initialize();
    await vault.unlockWithBrowserKey();
    expect(await vault.read('api_key'), 'browser-protected-key');
    await expectLater(vault.unlock(password), throwsStateError);
  });

  test('加密数据绑定存储键名，交换密文时拒绝读取并保留数据', () async {
    await vault.unlock(password);
    await vault.write('server_a', 'credential_a');
    await vault.write('server_b', 'credential_b');
    final box = Hive.box<dynamic>(boxName);
    final entries = box.keys.where((key) => key != 'metadata').toList();
    expect(entries, hasLength(2));
    await box.put(entries[0], box.get(entries[1]));
    await expectLater(vault.read('server_a'), throwsA(anything));
    expect(box.length, 3);
  });
}
