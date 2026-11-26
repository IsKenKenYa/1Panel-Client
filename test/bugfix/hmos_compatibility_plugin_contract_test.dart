import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HMOS compatibility plugins expose expected channel names', () async {
    final shared = await _read(
      'ohos/entry/src/main/ets/plugins/OhosSharedPreferencesPlugin.ets',
    );
    final packageInfo = await _read(
      'ohos/entry/src/main/ets/plugins/OhosPackageInfoPlugin.ets',
    );
    final pathProvider = await _read(
      'ohos/entry/src/main/ets/plugins/OhosPathProviderPlugin.ets',
    );
    final secureStorage = await _read(
      'ohos/entry/src/main/ets/plugins/OhosSecureStoragePlugin.ets',
    );
    final secureStore = await _read(
      'ohos/entry/src/main/ets/plugins/OhosHuksSecureStore.ets',
    );
    final localAuth = await _read(
      'ohos/entry/src/main/ets/plugins/OhosLocalAuthPlugin.ets',
    );
    final platformBridge = await _read(
      'ohos/entry/src/main/ets/plugins/OhosPlatformPlugin.ets',
    );

    expect(shared,
        contains("const CHANNEL = 'plugins.flutter.io/shared_preferences';"));
    expect(packageInfo,
        contains("const CHANNEL = 'dev.fluttercommunity.plus/package_info';"));
    expect(pathProvider,
        contains("const CHANNEL = 'plugins.flutter.io/path_provider';"));
    expect(
        secureStorage,
        contains(
            "const CHANNEL = 'plugins.it_nomads.com/flutter_secure_storage';"));
    expect(secureStorage,
        contains("const CUSTOM_CHANNEL = 'onepanel/secure_storage';"));
    expect(
        secureStore,
        contains(
            "const MASTER_KEY_ALIAS = 'onepanel_secure_storage_master_key';"));
    expect(localAuth,
        contains("const CHANNEL = 'plugins.flutter.io/local_auth';"));
    expect(
        platformBridge, contains("const CHANNEL = 'onepanel/ohos_platform';"));
  });

  test('HMOS compatibility plugins cover startup-critical method contracts',
      () async {
    final shared = await _read(
      'ohos/entry/src/main/ets/plugins/OhosSharedPreferencesPlugin.ets',
    );
    final packageInfo = await _read(
      'ohos/entry/src/main/ets/plugins/OhosPackageInfoPlugin.ets',
    );
    final pathProvider = await _read(
      'ohos/entry/src/main/ets/plugins/OhosPathProviderPlugin.ets',
    );
    final secureStorage = await _read(
      'ohos/entry/src/main/ets/plugins/OhosSecureStoragePlugin.ets',
    );
    final secureStore = await _read(
      'ohos/entry/src/main/ets/plugins/OhosHuksSecureStore.ets',
    );
    final localAuth = await _read(
      'ohos/entry/src/main/ets/plugins/OhosLocalAuthPlugin.ets',
    );
    final platformBridge = await _read(
      'ohos/entry/src/main/ets/plugins/OhosPlatformPlugin.ets',
    );

    expect(shared, contains("case 'getAll'"));
    expect(shared, contains("case 'setString'"));
    expect(shared, contains("case 'clearWithParameters'"));
    expect(shared, contains('result.success(true);'));

    expect(packageInfo, contains("if (call.method !== 'getAll')"));
    expect(packageInfo, contains('result.success({'));

    expect(pathProvider, contains("case 'getTemporaryDirectory'"));
    expect(pathProvider, contains("case 'getApplicationDocumentsDirectory'"));
    expect(pathProvider, contains("case 'getApplicationCacheDirectory'"));

    expect(secureStorage, contains("case 'ping'"));
    expect(secureStorage, contains("case 'containsKey'"));
    expect(secureStorage, contains("case 'readAll'"));
    expect(secureStorage, contains("case 'write'"));
    expect(secureStorage, contains("case 'deleteAll'"));
    expect(secureStorage, contains('result.success(true);'));
    expect(secureStore, contains("import huks from '@ohos.security.huks';"));
    expect(
        secureStore, contains('await huks.generateKeyItem(MASTER_KEY_ALIAS'));
    expect(secureStore, contains('await huks.deleteKeyItem(MASTER_KEY_ALIAS'));
    expect(secureStore, contains("JSON.stringify(payload)"));

    expect(localAuth, contains("case 'authenticate'"));
    expect(localAuth, contains("case 'getAvailableBiometrics'"));
    expect(localAuth, contains("case 'isDeviceSupported'"));
    expect(localAuth, contains("case 'stopAuthentication'"));
    expect(localAuth, contains('userAuth.getAvailableStatus('));
    expect(localAuth, contains('result.success(this.getBiometrics());'));
    expect(localAuth, contains('userAuth.getUserAuthInstance('));
    expect(localAuth, contains('userAuth.UserAuthResultCode.SUCCESS'));

    expect(platformBridge, contains("case 'getRuntimeInfo'"));
    expect(platformBridge, contains("case 'saveBytes'"));
    expect(platformBridge, contains('context.filesDir'));
    expect(platformBridge, contains('/exports'));
    expect(platformBridge, contains('fs.writeSync'));
  });
}

Future<String> _read(String path) async {
  final file = File(path);
  expect(await file.exists(), isTrue, reason: 'Missing file: $path');
  return file.readAsString();
}
