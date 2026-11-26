import 'dart:convert';
import 'dart:typed_data';

import '../../data/models/app_models.dart';
import '../../features/apps/app_service.dart';
import '../network/api_client_manager.dart';
import '../services/cache/app_icon_cache.dart';
import '../services/logger/logger_service.dart';

class NativeChannelApps {
  static Future<dynamic> dispatch(String method, dynamic arguments) async {
    final args = arguments == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(arguments as Map);
    final service = AppService();
    switch (method) {
      case 'installHarmonyApp':
        final request = AppInstallCreateRequest(
          appDetailId: args['appDetailId'] as int,
          name: args['name'] as String,
          type: args['type'] as String?,
          params: Map<String, dynamic>.from(args['params'] as Map),
          taskID: DateTime.now().millisecondsSinceEpoch.toString(),
          advanced: args['advanced'] as bool?,
          containerName: args['containerName'] as String?,
          cpuQuota: (args['cpuQuota'] as num?)?.toDouble(),
          memoryLimit: (args['memoryLimit'] as num?)?.toDouble(),
          memoryUnit: args['memoryUnit'] as String?,
          hostMode: args['hostMode'] as bool?,
          allowPort: args['allowPort'] as bool?,
          pullImage: args['pullImage'] as bool?,
          editCompose: args['editCompose'] as bool?,
          dockerCompose: args['dockerCompose'] as String?,
        );
        final info = await service.installApp(request);
        return {'success': true, 'appId': info.id};
      case 'getHarmonyAppIcons':
        final keys = args['appKeys'] as List? ?? const <dynamic>[];
        final icons = <String, String>{};
        // 逐项串行取回，命中磁盘缓存时不再请求面板；失败的键不出现在结果里，
        // 由原生侧保持默认图标。
        for (final key in keys.whereType<String>()) {
          if (key.isEmpty) continue;
          final cached = await AppIconCache.read(key);
          if (cached != null) {
            icons[key] = cached;
            continue;
          }
          try {
            final response = await service.getAppIcon(key);
            final type = response.headers.value('content-type')?.split(';').first;
            final bytes = response.data;
            if (type == null || !type.startsWith('image/') || bytes == null || bytes.isEmpty) {
              continue;
            }
            await AppIconCache.write(key, Uint8List.fromList(bytes));
            icons[key] = 'data:$type;base64,${base64Encode(bytes)}';
          } catch (error) {
            appLogger.wWithPackage('app-icon', '取回应用图标失败 $key: $error');
          }
        }
        return icons;
      case 'getHarmonyAppIcon':
        final appKey = args['appKey'] as String? ?? '';
        if (appKey.isEmpty) return null;
        final cached = await AppIconCache.read(appKey);
        if (cached != null) return cached;
        final response = await service.getAppIcon(appKey);
        final type = response.headers.value('content-type')?.split(';').first;
        final bytes = response.data;
        if (type == null || !type.startsWith('image/') || bytes == null || bytes.isEmpty) {
          return null;
        }
        await AppIconCache.write(appKey, Uint8List.fromList(bytes));
        return 'data:$type;base64,${base64Encode(bytes)}';
      case 'upgradeHarmonyApp':
        await service.operateInstalledApp(AppInstalledOperateRequest(
          installId: args['installId'] as int,
          detailId: args['detailId'] as int,
          operate: 'upgrade',
          backup: args['backup'] as bool?,
          pullImage: args['pullImage'] as bool?,
          deleteImage: args['deleteImage'] as bool?,
          taskID: DateTime.now().millisecondsSinceEpoch.toString(),
        ));
        break;
      case 'uninstallHarmonyApp':
        await service.operateInstalledApp(AppInstalledOperateRequest(
          installId: args['installId'] as int,
          operate: 'delete',
          deleteDB: args['deleteDB'] as bool?,
          deleteImage: args['deleteImage'] as bool?,
          deleteBackup: args['deleteBackup'] as bool?,
          taskID: DateTime.now().millisecondsSinceEpoch.toString(),
        ));
        break;
      case 'syncInstalledApps':
        await service.syncInstalledApps();
        break;
      case 'syncRemoteApps':
        await service.syncRemoteApps();
        break;
      case 'syncLocalApps':
        await service.syncLocalApps();
        break;
      case 'getIgnoredAppDetails':
        return (await service.getIgnoredAppDetails())
            .map((app) => app.toJson())
            .toList();
      case 'ignoreAppUpdate':
        await service.ignoreAppVersion(
          appId: args['appId'] as int,
          scope: args['scope'] as String,
          detailId: args['detailId'] as int?,
        );
        break;
      case 'cancelIgnoreAppUpdate':
        await service.cancelIgnoreAppUpdate(AppInstalledIgnoreUpgradeRequest(
          appInstallId: (args['appInstallId'] as num).toInt(),
          reason: args['reason'] as String? ?? '',
          scope: args['scope'] as String? ?? AppIgnoreUpgradeScope.version,
        ));
        break;
      case 'getAppServices':
        return (await service.getAppServices(args['key'] as String))
            .map((entry) => entry.toJson())
            .toList();
      case 'loadAppDatabaseFormats':
        final databaseApi = await ApiClientManager.instance.getDatabaseApi();
        return (await databaseApi.loadFormatCollations(args['database'] as String)).data;
      case 'loadAppWebsiteDir':
        final settingApi = await ApiClientManager.instance.getSettingApi();
        return (await settingApi.getWebsiteDir()).data;
      case 'getAppConnInfo':
        return service.getAppConnInfo(
          args['name'] as String,
          args['key'] as String,
        );
      case 'getAppUpdateVersions':
        return (await service.getAppUpdateVersions(args['installId'].toString()))
            .map((entry) => entry.toJson())
            .toList();
      case 'checkAppUninstall':
        return service.checkAppUninstall(args['installId'].toString());
      case 'updateAppParams':
        await service.updateAppParams(AppInstalledParamsUpdateRequest(
          installId: (args['installId'] as num).toInt(),
          params: Map<String, dynamic>.from(args['params'] as Map),
          advanced: args['advanced'] as bool?,
          allowPort: args['allowPort'] as bool?,
          containerName: args['containerName'] as String?,
          cpuQuota: (args['cpuQuota'] as num?)?.toDouble(),
          memoryLimit: (args['memoryLimit'] as num?)?.toDouble(),
          memoryUnit: args['memoryUnit'] as String?,
          dockerCompose: args['dockerCompose'] as String?,
          editCompose: args['editCompose'] as bool?,
          gpuConfig: args['gpuConfig'] as bool?,
          hostMode: args['hostMode'] as bool?,
          pullImage: args['pullImage'] as bool?,
          restartPolicy: args['restartPolicy'] as String?,
          specifyIP: args['specifyIP'] as String?,
          type: args['type'] as String?,
          webUI: args['webUI'] as String?,
        ));
        break;
      case 'changeAppPort':
        await service.changeAppPort(AppPortUpdateRequest(
          key: args['key'] as String,
          name: args['name'] as String,
          port: (args['port'] as num).toInt(),
        ));
        break;
      case 'updateAppInstallConfig':
        await service.updateAppInstallConfig(AppConfigUpdateRequest(
          installId: (args['installId'] as num).toInt(),
          webUI: args['webUI'] as String?,
        ));
        break;
      default:
        throw ArgumentError.value(method, 'method');
    }
    return {'success': true};
  }
}
