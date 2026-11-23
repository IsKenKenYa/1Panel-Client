import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/storage/local_credential_vault.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('panel_vault_test');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  LocalCredentialVault build() =>
      LocalCredentialVault(() async => directory);

  group('本地凭据文件存储', () {
    test('写入后可读回，覆盖写入生效', () async {
      final vault = build();

      await vault.write('k1', 'first');
      expect(await vault.read('k1'), 'first');

      await vault.write('k1', 'second');
      expect(await vault.read('k1'), 'second');
    });

    test('删除不存在的键不报错，删除后回读为空', () async {
      final vault = build();

      await vault.delete('missing');
      await vault.write('k1', 'value');
      await vault.delete('k1');

      expect(await vault.read('k1'), isNull);
    });

    test('新建实例能读到已有文件内容', () async {
      await build().write('k1', 'value');

      expect(await build().read('k1'), 'value');
    });

    test('deleteAll 清空文件与缓存', () async {
      final vault = build();
      await vault.write('k1', 'value');
      await vault.write('k2', 'value');

      await vault.deleteAll();

      expect(await vault.read('k1'), isNull);
      final file = File('${directory.path}/panel_credentials.json');
      expect(await file.exists(), isFalse);
    });

    test('文件内容不是 JSON 对象时抛出格式错误，不静默覆盖', () async {
      final file = File('${directory.path}/panel_credentials.json');
      await file.writeAsString('[1,2,3]');

      await expectLater(
        build().read('k1'),
        throwsA(isA<FormatException>()),
      );
      expect(await file.readAsString(), '[1,2,3]');
    });

    test('写入后文件权限仅所有者可读写', () async {
      final vault = build();
      await vault.write('k1', 'value');

      final file = File('${directory.path}/panel_credentials.json');
      final mode = (await file.stat()).mode & 0x1FF;
      // 0o600；Windows 无 POSIX 权限位，跳过断言。
      if (!Platform.isWindows) {
        expect(mode, 0x180);
      }
    });

    test('文件里非字符串值被忽略，其余键仍可读', () async {
      final file = File('${directory.path}/panel_credentials.json');
      await file.writeAsString(jsonEncode({'k1': 'value', 'k2': 12}));

      final vault = build();
      expect(await vault.read('k1'), 'value');
      expect(await vault.read('k2'), isNull);
    });
  });
}