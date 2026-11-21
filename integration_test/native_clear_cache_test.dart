import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/services/cache/file_preview_cache_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const testBundleId = String.fromEnvironment('ONEPANEL_CACHE_TEST_BUNDLE_ID');
  testWidgets(
    '原生清除缓存仅清除文件预览缓存',
    (tester) async {
      final package = await PackageInfo.fromPlatform();
      expect(package.packageName, allOf(testBundleId, endsWith('.cachetest')));

      final runId = DateTime.now().microsecondsSinceEpoch;
      SharedPreferences.setPrefix('native_clear_cache_test.$runId.');
      final preferences = await SharedPreferences.getInstance();
      addTearDown(preferences.clear);
      await preferences.setString('app_ui_render_mode', 'native');
      await preferences.setString('app_theme_mode', 'dark');

      const asset = 'lib/l10n/app_en.arb';
      final assetData = await rootBundle.load(asset);
      final filePath = '/native_clear_cache_test/$runId/$asset';
      const connectionId = 'first';
      final cache = FilePreviewCacheManager();
      final contents = assetData.buffer.asUint8List(
        assetData.offsetInBytes,
        assetData.lengthInBytes,
      );
      final viewerPath = (await cache.saveToTempFile(contents, 'preview.arb'))!;
      expect(await File(viewerPath).readAsBytes(), contents);
      await cache.releaseViewerFile(viewerPath);
      expect(await File(viewerPath).exists(), isFalse);
      await cache.loadFile(
        connectionId: connectionId,
        filePath: filePath,
        fileName: 'app_en.arb',
        downloadFn: () async => contents,
        strategy: CacheStrategy.hybrid,
      );
      addTearDown(() => cache.removeFile(connectionId, filePath));
      expect(cache.isInMemoryCache(connectionId, filePath), isTrue);
      expect(await cache.isInDiskCache(connectionId, filePath), isTrue);
      expect(cache.isInMemoryCache('second', filePath), isFalse);
      expect(await cache.isInDiskCache('second', filePath), isFalse);

      final download = Completer<Uint8List>();
      final started = Completer<void>();
      final inFlightPath = '$filePath.pending';
      final inFlight = cache.loadFile(
        connectionId: connectionId,
        filePath: inFlightPath,
        fileName: 'pending.arb',
        strategy: CacheStrategy.hybrid,
        downloadFn: () {
          started.complete();
          return download.future;
        },
      );
      await started.future;
      final response = await NativeChannelManager.instance.handleMethodCall(
        'clearCache',
        null,
      );

      expect(response, containsPair('success', true));
      download.complete(contents);
      expect((await inFlight)?.data.length, assetData.lengthInBytes);
      expect(cache.isInMemoryCache(connectionId, inFlightPath), isFalse);
      expect(await cache.isInDiskCache(connectionId, inFlightPath), isFalse);
      expect(cache.isInMemoryCache(connectionId, filePath), isFalse);
      expect(await cache.isInDiskCache(connectionId, filePath), isFalse);
      await preferences.reload();
      expect(preferences.getString('app_ui_render_mode'), 'native');
      expect(preferences.getString('app_theme_mode'), 'dark');
    },
    skip: testBundleId.isEmpty,
  );
}
