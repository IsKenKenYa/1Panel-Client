import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';
import 'package:onepanel_client/core/storage/local_credential_vault.dart';

void main() {
  late Directory directory;

  setUp(() async {
    final root = Directory('build/local_credential_vault_tests');
    await root.create(recursive: true);
    directory = await root.createTemp('vault_');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  LocalCredentialVault build() => LocalCredentialVault(() async => directory);

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
      expect(await build().read('k1'), isNull);
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
      expect(await build().read('k1'), isNull);
      final file = File('${directory.path}/panel_credentials.json');
      expect(await file.exists(), isFalse);
    });

    test('文件不存在时 deleteAll 正常完成', () async {
      final vault = build();

      await vault.deleteAll();

      expect(await vault.read('k1'), isNull);
      expect(await build().read('k1'), isNull);
    });

    test('文件内容不是 JSON 对象时拒绝读写并保留原文', () async {
      final file = File('${directory.path}/panel_credentials.json');
      await file.writeAsString('[1,2,3]');
      final vault = build();

      await expectLater(
        vault.read('k1'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        vault.write('k1', 'value'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        vault.delete('k1'),
        throwsA(isA<FormatException>()),
      );
      expect(await file.readAsString(), '[1,2,3]');
    });

    test('写入后文件权限仅所有者可读写', () async {
      final vault = build();
      await vault.write('k1', 'value');

      final file = File('${directory.path}/panel_credentials.json');
      final mode = (await file.stat()).mode & 0x1FF;
      // 0o600；macOS 与 Linux 使用桌面文件权限。
      if (!PlatformCapabilities.current().isOhos &&
          (Platform.isMacOS || Platform.isLinux)) {
        expect(mode, 0x180);
      }
    });

    test('文件包含非字符串值时拒绝读写并保留全部条目', () async {
      final file = File('${directory.path}/panel_credentials.json');
      final contents = jsonEncode({'k1': 'value', 'k2': 12});
      await file.writeAsString(contents);

      final vault = build();
      await expectLater(
        vault.read('k1'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        vault.write('k3', 'next'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        vault.delete('k1'),
        throwsA(isA<FormatException>()),
      );
      expect(await file.readAsString(), contents);
    });

    test('写入失败后缓存与文件保持原值，解除占用后可以重试', () async {
      final vault = build();
      await vault.write('k1', 'saved');
      final file = File('${directory.path}/panel_credentials.json');
      final contents = await file.readAsString();
      final blocker = Directory('${file.path}.tmp');
      await blocker.create();

      await expectLater(
        vault.write('k1', 'changed'),
        throwsA(isA<FileSystemException>()),
      );

      expect(await vault.read('k1'), 'saved');
      expect(await build().read('k1'), 'saved');
      expect(await file.readAsString(), contents);

      await blocker.delete();
      await vault.write('k1', 'changed');
      expect(await vault.read('k1'), 'changed');
      expect(await build().read('k1'), 'changed');
    });

    test('首次写入失败后不会在缓存中发布新条目', () async {
      final vault = build();
      final file = File('${directory.path}/panel_credentials.json');
      final blocker = Directory('${file.path}.tmp');
      await blocker.create();

      await expectLater(
        vault.write('k1', 'unsaved'),
        throwsA(isA<FileSystemException>()),
      );

      expect(await vault.read('k1'), isNull);
      expect(await build().read('k1'), isNull);
      expect(await file.exists(), isFalse);

      await blocker.delete();
      await vault.write('k1', 'saved');
      expect(await build().read('k1'), 'saved');
    });

    test('删除条目失败后缓存与文件保留原条目', () async {
      final vault = build();
      await vault.write('k1', 'saved');
      await vault.write('k2', 'retained');
      final file = File('${directory.path}/panel_credentials.json');
      final contents = await file.readAsString();
      final blocker = Directory('${file.path}.tmp');
      await blocker.create();

      await expectLater(
        vault.delete('k1'),
        throwsA(isA<FileSystemException>()),
      );

      expect(await vault.read('k1'), 'saved');
      expect(await vault.read('k2'), 'retained');
      expect(await build().read('k1'), 'saved');
      expect(await file.readAsString(), contents);

      await blocker.delete();
      await vault.delete('k1');
      expect(await vault.read('k1'), isNull);
      expect(await build().read('k1'), isNull);
      expect(await build().read('k2'), 'retained');
    });

    test('删除文件失败后保留缓存与原文件内容', () async {
      final vault = build();
      await vault.write('k1', 'saved');
      final file = File('${directory.path}/panel_credentials.json');
      final contents = await file.readAsString();
      final retained = await file.rename('${directory.path}/retained.json');
      final blocker = Directory(file.path);
      await blocker.create();
      await File('${blocker.path}/occupied').writeAsString('occupied');

      await expectLater(
        vault.deleteAll(),
        throwsA(isA<FileSystemException>()),
      );

      expect(await vault.read('k1'), 'saved');
      expect(await retained.readAsString(), contents);

      await blocker.delete(recursive: true);
      await retained.rename(file.path);
      expect(await build().read('k1'), 'saved');
      await vault.deleteAll();
      expect(await vault.read('k1'), isNull);
      expect(await build().read('k1'), isNull);
    });

    test('独立文件的同名条目分别保存与删除', () async {
      final first = build();
      final second = LocalCredentialVault(
        () async => directory,
        fileName: 'isolated_credentials.json',
      );
      await first.write('k1', 'first');
      await second.write('k1', 'second');

      expect(await build().read('k1'), 'first');
      expect(
        await LocalCredentialVault(
          () async => directory,
          fileName: 'isolated_credentials.json',
        ).read('k1'),
        'second',
      );

      await second.deleteAll();
      expect(await first.read('k1'), 'first');
      expect(await build().read('k1'), 'first');
      expect(await second.read('k1'), isNull);
    });
  });
}
