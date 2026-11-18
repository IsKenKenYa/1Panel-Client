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
      final cache = FilePreviewCacheManager();
      await cache.loadFile(
        filePath: filePath,
        fileName: 'app_en.arb',
        downloadFn: () async => assetData.buffer.asUint8List(
          assetData.offsetInBytes,
          assetData.lengthInBytes,
        ),
        strategy: CacheStrategy.hybrid,
      );
      addTearDown(() => cache.removeFile(filePath));
      expect(cache.isInMemoryCache(filePath), isTrue);
      expect(await cache.isInDiskCache(filePath), isTrue);

      final response = await NativeChannelManager.instance.handleMethodCall(
        'clearCache',
        null,
      );

      expect(response, containsPair('success', true));
      expect(cache.isInMemoryCache(filePath), isFalse);
      expect(await cache.isInDiskCache(filePath), isFalse);
      await preferences.reload();
      expect(preferences.getString('app_ui_render_mode'), 'native');
      expect(preferences.getString('app_theme_mode'), 'dark');
    },
    skip: testBundleId.isEmpty,
  );
}
