import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/cache/app_icon_cache.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// 应用图标磁盘缓存的读写与过期行为。
///
/// 面板 `/apps/icon/:key` 对远程图标返回 302，弱网下每次进页面都重新
/// 请求会长时间停在默认图标，因此缓存必须能落盘并在重启后直接命中。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory sandbox;
  late PathProviderPlatform original;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('app_icon_cache_test');
    original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _SandboxPathProvider(sandbox.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = original;
    if (sandbox.existsSync()) await sandbox.delete(recursive: true);
  });

  test('read returns null when nothing was written', () async {
    expect(await AppIconCache.read('openresty'), isNull);
  });

  test('write then read returns a png data url', () async {
    final bytes = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]);
    await AppIconCache.write('openresty', bytes);

    final cached = await AppIconCache.read('openresty');

    expect(cached, startsWith('data:image/png;base64,'));
    expect(base64Decode(cached!.substring('data:image/png;base64,'.length)),
        bytes);
  });

  test('cache keys are independent per app', () async {
    await AppIconCache.write('openresty', Uint8List.fromList([1, 2, 3]));
    await AppIconCache.write('mysql', Uint8List.fromList([4, 5, 6]));

    expect(await AppIconCache.read('openresty'), isNotNull);
    expect(await AppIconCache.read('mysql'), isNotNull);
    expect(await AppIconCache.read('unknown-app'), isNull);
  });

  test('empty bytes are not written', () async {
    await AppIconCache.write('openresty', Uint8List(0));
    expect(await AppIconCache.read('openresty'), isNull);
  });

  test('clear removes cached files', () async {
    await AppIconCache.write('openresty', Uint8List.fromList([1, 2, 3]));
    expect(await AppIconCache.read('openresty'), isNotNull);

    await AppIconCache.clear();

    expect(await AppIconCache.read('openresty'), isNull);
    expect(
      Directory('${sandbox.path}/kenpanel_app_icons').existsSync(),
      isFalse,
    );
  });

  test('expired cache is treated as a miss', () async {
    await AppIconCache.write('openresty', Uint8List.fromList([1, 2, 3]));
    final directory = Directory('${sandbox.path}/kenpanel_app_icons');
    final iconFile = directory.listSync().whereType<File>().single;
    final old = DateTime.now().subtract(const Duration(days: 40));
    await iconFile.setLastModified(old);

    expect(await AppIconCache.read('openresty'), isNull);
  });
}

class _SandboxPathProvider extends PathProviderPlatform {
  _SandboxPathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}
