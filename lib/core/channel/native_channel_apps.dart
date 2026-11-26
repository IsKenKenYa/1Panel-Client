import 'dart:convert';

import '../../data/models/app_models.dart';
import '../../features/apps/app_service.dart';
import '../network/api_client_manager.dart';

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
      case 'getHarmonyAppIcon':
        final response = await service.getAppIcon(args['appKey'] as String);
        final type = response.headers.value('content-type')?.split(';').first;
        final bytes = response.data;
        if (type == null || !type.startsWith('image/') || bytes == null || bytes.isEmpty) {
          return null;
        }
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
