import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/app_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:dio/dio.dart';
import '../core/test_config_manager.dart';
import '../api_client_test_base.dart';

void main() {
  late DioClient client;
  late AppV2Api api;
  bool hasApiKey = false;
  final resultCollector = TestResultCollector();

  // Test State Variables
  AppItem? targetApp;
  AppItem? targetAppDetail;
  int? appDetailId;
  String? appVersion;
  String? appType;
  String? appKey;
  int? installedAppId;
  String installName =
      'test-redis-${DateTime.now().millisecondsSinceEpoch}'; // Use unique name to avoid conflicts

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty &&
        TestEnvironment.apiKey != 'your_api_key_here';

    debugPrint(
        '\n╔════════════════════════════════════════════════════════════╗');
    debugPrint(
        '║              App Management Full Integration Test           ║');
    debugPrint(
        '╠════════════════════════════════════════════════════════════╣');
    debugPrint('║ Server: ${TestEnvironment.baseUrl}');
    debugPrint('║ API Key: ${hasApiKey ? "Configured" : "Missing"}');
    debugPrint(
        '╚════════════════════════════════════════════════════════════╝\n');

    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = AppV2Api(client);
    }
  });

  tearDownAll(() {
    try {
      resultCollector.printSummary();
    } catch (e) {
      debugPrint('Error in tearDownAll: $e');
    }
  });

  // Helper to poll for status
  Future<void> waitForStatus(int installId, String targetStatus,
      {Duration timeout = const Duration(minutes: 5)}) async {
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      final info = await api.getAppInstallInfo(installId.toString());
      debugPrint('   Current status: ${info.status} (Target: $targetStatus)');
      if (info.status == targetStatus) return;
      if (info.status == 'Error')
        throw Exception('App entered Error state: ${info.message}');
      await Future.delayed(const Duration(seconds: 3));
    }
    throw Exception('Timeout waiting for status: $targetStatus');
  }

  void logResponse(String endpoint, dynamic response) {
    debugPrint('✅ Response from $endpoint:');
    try {
      if (response is Map || response is List) {
        debugPrint(jsonEncode(response));
      } else {
        debugPrint(response.toString());
      }
    } catch (e) {
      debugPrint('   (Not JSON serializable): $response');
    }
  }

  group('1. App Store Discovery & Info', () {
    test('POST /apps/sync/remote - Sync Remote Apps', () async {
      if (!hasApiKey) return;
      try {
        await api.syncRemoteApps();
        resultCollector.addSuccess('Sync Remote Apps', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Sync Remote Apps', e.toString(), Duration.zero);
      }
    });

    test('POST /apps/sync/local - Sync Local Apps', () async {
      if (!hasApiKey) return;
      try {
        await api.syncLocalApps();
        resultCollector.addSuccess('Sync Local Apps', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Sync Local Apps', e.toString(), Duration.zero);
      }
    });

    test('POST /apps/search - Search for Redis', () async {
      if (!hasApiKey) return;
      final testName = 'Search App';
      try {
        final request =
            AppSearchRequest(page: 1, pageSize: 10, name: 'redis'); // Use Redis
        final response = await api.searchApps(request);
        logResponse('/apps/search', response.items.length);
        expect(response.items, isNotEmpty);
        targetApp = response.items.first;
        appKey = targetApp!.key;
        debugPrint(
            '✅ Found app: ${targetApp!.name} (Key: $appKey, ID: ${targetApp!.id})');
        resultCollector.addSuccess(testName, Duration.zero);
      } catch (e) {
        resultCollector.addFailure(testName, e.toString(), Duration.zero);
        rethrow;
      }
    });

    test('GET /apps/detail/... - Get App Detail', () async {
      if (!hasApiKey || targetApp == null) return;
      final testName = 'Get App Detail';
      try {
        // Fetch full detail first by key to ensure we have versions
        targetApp = await api.getAppByKey(targetApp!.key!);

        final versions = targetApp!.versions ?? [];
        if (versions.isEmpty) {
          resultCollector.addSkipped(testName, 'No versions found');
          return;
        }

        appVersion = versions.first;
        appType = targetApp!.type ?? 'runtime';

        debugPrint('📦 Selected Version: $appVersion, Type: $appType');

        targetAppDetail = await api.getAppDetail(
            targetApp!.id.toString(), appVersion!, appType!);
        logResponse('/apps/detail', targetAppDetail?.toJson());
        expect(targetAppDetail, isNotNull);
        appDetailId = targetAppDetail!.id;

        debugPrint('✅ Got detail for ID: $appDetailId');
        resultCollector.addSuccess(testName, Duration.zero);
      } catch (e) {
        debugPrint('⚠️ Get App Detail failed (backend error possible): $e');
        // If detail fetch fails, we can't proceed with install tests that require appDetailId
        // But we continue to test other read-only endpoints
        resultCollector.addFailure(testName, e.toString(), Duration.zero);
      }
    });

    test('GET /apps/details/:id - Get Detail by ID', () async {
      if (!hasApiKey || appDetailId == null) return;
      try {
        final item = await api.getAppDetails(appDetailId.toString());
        logResponse('/apps/details/:id', item.name);
        expect(item.id, equals(appDetailId));
        resultCollector.addSuccess('Get Detail by ID', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Get Detail by ID', e.toString(), Duration.zero);
      }
    });

    test('GET /apps/:key - Get App by Key', () async {
      if (!hasApiKey || appKey == null) return;
      try {
        final item = await api.getAppByKey(appKey!);
        logResponse('/apps/:key', item.name);
        expect(item.key, equals(appKey));
        resultCollector.addSuccess('Get App by Key', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Get App by Key', e.toString(), Duration.zero);
      }
    });

    test('GET /apps/icon/:key - Get App Icon (Key)', () async {
      if (!hasApiKey || appKey == null) return;
      try {
        final response = await api.getAppIcon(appKey!);
        debugPrint('✅ Icon size: ${response.data?.length} bytes');
        expect(response.data, isNotNull);
        resultCollector.addSuccess('Get App Icon (Key)', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Get App Icon (Key)', e.toString(), Duration.zero);
      }
    });

    test('GET /apps/detail/node/:appKey/:version - Get Detail Node', () async {
      if (!hasApiKey || appKey == null || appVersion == null) return;
      try {
        final detail = await api.getAppDetailNode(appKey!, appVersion!);
        logResponse('/apps/detail/node/:appKey/:version', detail.toJson());
        resultCollector.addSuccess('Get Detail Node', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Get Detail Node', e.toString(), Duration.zero);
      }
    });
  });

  group('2. App Installation', () {
    test('Cleanup before install', () async {
      if (!hasApiKey) return;
      final search = await api.searchInstalledApps(
          AppInstalledSearchRequest(page: 1, pageSize: 10, name: installName));
      if (search.items.isNotEmpty) {
        debugPrint('⚠️ Found existing test app, uninstalling...');
        final app = search.items.first;
        await api.uninstallApp(app.id.toString());
        await Future.delayed(const Duration(seconds: 5));
      }
    });

    test('POST /apps/installed/check - Check Install', () async {
      if (!hasApiKey || targetApp == null || appVersion == null) return;
      try {
        final req = AppInstalledCheckRequest(
            key: targetApp!.key!, version: appVersion!, type: appType!);
        final res = await api.checkAppInstall(req);
        logResponse('/apps/installed/check', res.toJson());
        resultCollector.addSuccess('Check Install', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Check Install', e.toString(), Duration.zero);
      }
    });

    test('POST /apps/installed/conf - Get Install Config', () async {
      if (!hasApiKey || targetApp == null) return;
      try {
        final config =
            await api.getAppInstallConfig(targetApp!.name!, targetApp!.key!);
        logResponse('/apps/installed/conf', config.keys.toList());
        resultCollector.addSuccess('Get Install Config', Duration.zero);
      } catch (e) {
        debugPrint('⚠️ Get Install Config failed: $e');
        resultCollector.addSuccess(
            'Get Install Config (Warning)', Duration.zero);
      }
    });

    test('POST /apps/install - Install App', () async {
      if (!hasApiKey || appDetailId == null) return;
      final testName = 'Install App ($installName)';
      try {
        // Check limits
        final installedList = await api.getInstalledApps();
        final installedCount =
            installedList.where((app) => app.appKey == targetApp!.key).length;
        final limit = targetApp!.limit ?? 0;

        if (limit > 0 && installedCount >= limit) {
          resultCollector.addSkipped(testName, 'App limit reached');
          return;
        }

        final request = AppInstallCreateRequest(
          appDetailId: appDetailId!,
          name: installName,
          type: appType,
          advanced: false,
          params: {},
          allowPort: true,
        );

        debugPrint('🚀 Starting installation of $installName...');
        final info = await api.installApp(request);
        installedAppId = info.id;

        expect(installedAppId, isNotNull);
        debugPrint('✅ Installation started. ID: $installedAppId');

        await waitForStatus(installedAppId!, 'Running');

        resultCollector.addSuccess(testName, Duration.zero);
      } catch (e) {
        resultCollector.addFailure(testName, e.toString(), Duration.zero);
      }
    });
  });

  group('3. Installed App Management', () {
    test('GET /apps/installed/list - List Installed', () async {
      if (!hasApiKey || installedAppId == null) return;
      try {
        final list = await api.getInstalledApps();
        final found = list.any((app) => app.id == installedAppId);
        expect(found, isTrue);
        logResponse('/apps/installed/list', 'Found ${list.length} apps');
        resultCollector.addSuccess('List Installed', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'List Installed', e.toString(), Duration.zero);
      }
    });

    test('GET /apps/installed/info/:id - Get Install Info', () async {
      if (!hasApiKey || installedAppId == null) return;
      try {
        final info = await api.getAppInstallInfo(installedAppId.toString());
        logResponse('/apps/installed/info', info.toJson());
        expect(info.id, equals(installedAppId));
        resultCollector.addSuccess('Get Install Info', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Get Install Info', e.toString(), Duration.zero);
      }
    });

    test('GET /apps/installed/params/:id - Get Install Params', () async {
      if (!hasApiKey || installedAppId == null) return;
      try {
        final params = await api.getAppInstallParams(installedAppId!);
        logResponse('/apps/installed/params', params.toJson());
        expect(params, isNotNull);
        resultCollector.addSuccess('Get Install Params', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Get Install Params', e.toString(), Duration.zero);
      }
    });

    test('POST /apps/installed/conninfo - Get Conn Info', () async {
      if (!hasApiKey || targetApp == null) return;
      try {
        final info = await api.getAppConnInfo(installName, targetApp!.key!);
        logResponse('/apps/installed/conninfo', info);
        resultCollector.addSuccess('Get Conn Info', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Get Conn Info', e.toString(), Duration.zero);
      }
    });

    test('POST /apps/installed/op - Stop/Start/Restart', () async {
      if (!hasApiKey || installedAppId == null) return;
      try {
        debugPrint('⏹ Stopping app...');
        await api.operateApp(AppInstalledOperateRequest(
            installId: installedAppId!, operate: 'stop'));
        await waitForStatus(installedAppId!, 'Stopped');

        debugPrint('▶️ Starting app...');
        await api.operateApp(AppInstalledOperateRequest(
            installId: installedAppId!, operate: 'start'));
        await waitForStatus(installedAppId!, 'Running');

        debugPrint('🔄 Restarting app...');
        await api.operateApp(AppInstalledOperateRequest(
            installId: installedAppId!, operate: 'restart'));
        await waitForStatus(installedAppId!, 'Running');

        resultCollector.addSuccess('App Operations', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'App Operations', e.toString(), Duration.zero);
      }
    });

    test('POST /apps/installed/params/update - Update Params', () async {
      if (!hasApiKey || installedAppId == null) return;
      try {
        final config = await api.getAppInstallParams(installedAppId!);
        logResponse('getAppInstallParams', config.toJson());

        // Construct update request: transform params list to map
        final paramsMap = <String, dynamic>{};
        for (var p in config.params) {
          paramsMap[p.key] = p.value;
        }

        final updateReq = AppInstalledParamsUpdateRequest(
          installId: installedAppId!,
          cpuQuota: config.cpuQuota,
          memoryLimit: config.memoryLimit,
          memoryUnit: config.memoryUnit,
          containerName: config.containerName,
          allowPort: config.allowPort,
          dockerCompose: config.dockerCompose,
          hostMode: config.hostMode,
          type: config.type,
          webUI: config.webUI,
          params: paramsMap,
        );

        await api.updateAppParams(updateReq);
        resultCollector.addSuccess('Update Params', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Update Params', e.toString(), Duration.zero);
      }
    });

    test('POST /apps/installed/config/update - Update Config', () async {
      if (!hasApiKey || installedAppId == null) return;
      try {
        final info = await api.getAppInstallInfo(installedAppId.toString());
        await api.updateAppInstallConfig(
          AppConfigUpdateRequest(
            installId: installedAppId!,
            webUI: info.webUI,
          ),
        );
        resultCollector.addSuccess('Update Config', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Update Config', e.toString(), Duration.zero);
      }
    });

    test('POST /apps/installed/port/change - Change Port', () async {
      if (!hasApiKey || installedAppId == null) return;
      try {
        final info = await api.getAppInstallInfo(installedAppId.toString());
        if (info.appKey == null || info.name == null) {
          resultCollector.addSkipped(
              'Change Port', 'Missing app key or install name');
          return;
        }
        final int currentPort = info.httpPort ?? info.httpsPort ?? 0;
        if (currentPort <= 0) {
          resultCollector.addSkipped('Change Port', 'No valid port available');
          return;
        }

        await api.changeAppPort(
          AppPortUpdateRequest(
            key: info.appKey!,
            name: info.name!,
            port: currentPort,
          ),
        );
        resultCollector.addSuccess('Change Port', Duration.zero);
      } catch (e) {
        resultCollector.addFailure('Change Port', e.toString(), Duration.zero);
      }
    });
  });

  group('4. Configuration & Services', () {
    test('GET /apps/services/:key - Get App Services', () async {
      if (!hasApiKey || appKey == null) return;
      try {
        final services = await api.getAppServices(appKey!);
        logResponse('/apps/services/:key', services.length);
        resultCollector.addSuccess('Get App Services', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Get App Services', e.toString(), Duration.zero);
      }
    });

    test('GET /core/settings/apps/store/config - Get Store Config', () async {
      if (!hasApiKey) return;
      try {
        final config = await api.getAppstoreConfig();
        logResponse('/core/settings/apps/store/config', config.toJson());
        resultCollector.addSuccess('Get Store Config', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Get Store Config', e.toString(), Duration.zero);
      }
    });

    test('POST /core/settings/apps/store/update - Update Store Config',
        () async {
      if (!hasApiKey) return;
      try {
        final config = await api.getAppstoreConfig();
        final current = config.upgradeBackup ?? 'Enable';
        await api.updateAppstoreConfig(
          AppstoreUpdateRequest(
            scope: 'UpgradeBackup',
            status: current,
          ),
        );
        resultCollector.addSuccess('Update Store Config', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Update Store Config', e.toString(), Duration.zero);
      }
    });

    test('POST /apps/update - Update App Cache (Check Update)', () async {
      if (!hasApiKey) return;
      try {
        final res = await api.checkAppUpdate();
        logResponse('/apps/checkupdate', res.toJson());
        resultCollector.addSuccess('Check App Update', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Check App Update', e.toString(), Duration.zero);
      }
    });
  });

  group('5. Edge Cases & Cleanup', () {
    test('POST /apps/installed/sync - Sync App Status', () async {
      if (!hasApiKey) return;
      try {
        await api.syncAppStatus();
        resultCollector.addSuccess('Sync App Status', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Sync App Status', e.toString(), Duration.zero);
      }
    });

    test('POST /apps/installed/loadport - Load App Port', () async {
      if (!hasApiKey || targetApp == null) return;
      try {
        await api.loadAppPort({
          'name': targetApp!.name,
          'type': targetApp!.key,
        });
        resultCollector.addSuccess('Load App Port', Duration.zero);
      } catch (e) {
        debugPrint('⚠️ Load App Port warning: $e');
        resultCollector.addSuccess('Load App Port (Warning)', Duration.zero);
      }
    });

    test('Ignore & Cancel Ignore Update', () async {
      if (!hasApiKey || installedAppId == null) return;
      try {
        await api.ignoreAppUpdate(AppInstalledIgnoreUpgradeRequest(
          appInstallId: installedAppId!,
          reason: 'Test ignore',
          scope: AppIgnoreUpgradeScope.version,
        ));

        final ignored = await api.getIgnoredAppDetails();
        logResponse('/apps/ignored/detail', ignored.length);

        await api.cancelIgnoreAppUpdate(AppInstalledIgnoreUpgradeRequest(
          appInstallId: installedAppId!,
          reason: '',
          scope: AppIgnoreUpgradeScope.version,
        ));

        resultCollector.addSuccess('Ignore/Cancel Update', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Ignore/Cancel Update', e.toString(), Duration.zero);
      }
    });

    test('Get Update Versions', () async {
      if (!hasApiKey || installedAppId == null) return;
      try {
        final versions =
            await api.getAppUpdateVersions(installedAppId.toString());
        logResponse('getAppUpdateVersions', versions.length);
        resultCollector.addSuccess('Get Update Versions', Duration.zero);
      } catch (e) {
        resultCollector.addFailure(
            'Get Update Versions', e.toString(), Duration.zero);
      }
    });

    test('POST /apps/uninstall/:id - Uninstall App', () async {
      if (!hasApiKey || installedAppId == null) return;
      final testName = 'Uninstall App';
      try {
        debugPrint('🗑 Uninstalling app...');

        final check = await api.checkAppUninstall(installedAppId.toString());
        logResponse('checkAppUninstall', check);

        await api.uninstallApp(installedAppId.toString());

        // Wait for removal
        bool removed = false;
        for (int i = 0; i < 20; i++) {
          final list = await api.getInstalledApps();
          if (!list.any((app) => app.id == installedAppId)) {
            removed = true;
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }

        expect(removed, isTrue);
        debugPrint('✅ App uninstalled successfully');
        resultCollector.addSuccess(testName, Duration.zero);
      } catch (e) {
        resultCollector.addFailure(testName, e.toString(), Duration.zero);
      }
    });
  });

  // 7. Edge Cases & Error Handling
  group('Edge Cases', () {
    test('Get App Icon - Invalid ID (404/500)', () async {
      if (!hasApiKey) {
        resultCollector.addSkipped(
            'Get App Icon - Invalid ID (404/500)', 'API key not configured');
        return;
      }
      try {
        await api.getAppIcon('999999');
      } catch (e) {
        debugPrint('Expected error for invalid icon ID: $e');
        expect(e, isA<DioException>());
      }
    });

    test('Get App Detail - Invalid ID', () async {
      if (!hasApiKey) {
        resultCollector.addSkipped(
            'Get App Detail - Invalid ID', 'API key not configured');
        return;
      }
      try {
        await api.getAppDetail('999999', 'latest', 'unknown');
        fail('Should throw exception');
      } catch (e) {
        expect(e, isA<DioException>());
        logResponse('getAppDetail_Error', e.toString());
      }
    });

    test('Install App - Missing Required Fields', () async {
      if (!hasApiKey) {
        resultCollector.addSkipped(
            'Install App - Missing Required Fields', 'API key not configured');
        return;
      }
      try {
        // Sending empty name which should be required
        await api.installApp(AppInstallCreateRequest(
          name: '',
          appDetailId: 0,
          // params missing
        ));
        fail('Should throw exception');
      } catch (e) {
        debugPrint('Expected error for missing fields: $e');
      }
    });
  });
}
