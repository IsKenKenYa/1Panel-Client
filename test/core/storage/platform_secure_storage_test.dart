import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/storage/local_credential_vault.dart';
import 'package:onepanel_client/core/storage/platform_secure_storage.dart';

void main() {
  late Directory directory;

  setUp(() async {
    final root = Directory('build/platform_secure_storage_tests');
    await root.create(recursive: true);
    directory = await root.createTemp('credentials_');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  PlatformSecureStorage open({String namespace = ''}) =>
      PlatformSecureStorage.forTesting(
        directory: directory,
        namespace: namespace,
      );

  File fileFor(String namespace) => File(
        '${directory.path}/${PlatformSecureStorage.credentialFileName(namespace)}',
      );

  test('首次读取不存在的凭据返回空值', () async {
    expect(await open().read(key: 'api_key'), isNull);
    expect(await fileFor('').exists(), isFalse);
  });

  test('保存内容可由独立文件读取实例重新打开', () async {
    await open().write(key: 'api_key', value: 'saved-key');

    final reopened = LocalCredentialVault(() async => directory);
    expect(await reopened.read('api_key'), 'saved-key');
    expect(jsonDecode(await fileFor('').readAsString()), {
      'api_key': 'saved-key',
    });
  });

  test('不同调用方的缓存和并发写入共用同一个文件', () async {
    final auth = open();
    final hive = open();
    final config = open();
    expect(await auth.read(key: 'auth_token'), isNull);
    expect(await hive.read(key: 'box_key'), isNull);
    expect(await config.read(key: 'api_key'), isNull);

    await Future.wait([
      auth.write(key: 'auth_token', value: 'token'),
      hive.write(key: 'box_key', value: 'encryption-key'),
      config.write(key: 'api_key', value: 'panel-key'),
    ]);

    final entries = jsonDecode(await fileFor('').readAsString());
    expect(entries, {
      'auth_token': 'token',
      'box_key': 'encryption-key',
      'api_key': 'panel-key',
    });
    expect(await auth.read(key: 'api_key'), 'panel-key');
  });

  test('命名空间分别保存同名凭据', () async {
    await open().write(key: 'api_key', value: 'default-key');
    await open(namespace: 'test').write(key: 'api_key', value: 'test-key');

    expect(await open().read(key: 'api_key'), 'default-key');
    expect(await open(namespace: 'test').read(key: 'api_key'), 'test-key');
    await open(namespace: 'test').deleteAll();
    expect(await open().read(key: 'api_key'), 'default-key');
    expect(await fileFor('test').exists(), isFalse);
  });

  test('更新和删除能由其他实例立即读取', () async {
    final first = open();
    final second = open();
    await first.write(key: 'api_key', value: 'first');
    await second.write(key: 'api_key', value: 'second');
    expect(await first.read(key: 'api_key'), 'second');

    await second.delete(key: 'api_key');
    expect(await first.read(key: 'api_key'), isNull);
    await first.delete(key: 'missing');
  });

  test('写入空值删除该条凭据', () async {
    await open().write(key: 'api_key', value: 'saved');
    await open().write(key: 'api_key', value: null);
    expect(await open().read(key: 'api_key'), isNull);
  });

  test('文件写入失败时保留已经保存的内容', () async {
    await open().write(key: 'api_key', value: 'saved');
    final file = fileFor('');
    await Directory('${file.path}.tmp').create();

    await expectLater(
      open().write(key: 'api_key', value: 'changed'),
      throwsA(isA<FileSystemException>()),
    );
    expect(await open().read(key: 'api_key'), 'saved');
    expect(jsonDecode(await file.readAsString()), {'api_key': 'saved'});
  });
}
