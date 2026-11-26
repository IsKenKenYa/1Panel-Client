import 'package:flutter/services.dart';

import '../../core/config/api_config.dart';
import '../../features/monitoring/monitoring_service.dart';
import '../../features/backups/services/backup_account_service.dart';
import '../../features/settings/panel_ssl/services/panel_ssl_service.dart';
import '../../features/settings/settings_service.dart';
import '../../shared/security_gateway/utils/security_gateway_utils.dart';

class NativeChannelHarmonyPanel {
  static Future<dynamic> dispatch(String method, dynamic arguments) async {
    final args = arguments == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(arguments as Map);
    final server = await ApiConfigManager.getCurrentConfig();
    if (server == null) throw StateError('No current server');
    final service = SettingsService.forServer(server);
    switch (method) {
      case 'getHarmonyPanelSettings':
        return (await service.getSystemSettings())?.toJson()
          ?..remove('apiKey')
          ..remove('proxyPasswd');
      case 'getHarmonyPanelProxy':
        final settings = await service.getSystemSettings();
        if (settings == null) throw const FormatException('Missing panel settings');
        return {
          'proxyUrl': settings.proxyUrl,
          'proxyPort': settings.proxyPort,
          'proxyType': settings.proxyType,
          'proxyUser': settings.proxyUser,
          'proxyPasswd': settings.proxyPasswd,
          'proxyPasswdKeep': settings.proxyPasswdKeep,
        };
      case 'updateHarmonyPanelSetting':
        await service.updateSystemSetting(args['key'] as String, args['value'] as String);
        return null;
      case 'getHarmonyPanelMenus':
        return service.getDefaultMenus();
      case 'updateHarmonyPanelMenus':
        await service.updateMenuSettings((args['menus'] as List).cast<String>());
        return null;
      case 'getHarmonyPanelMemo':
        return service.getDashboardMemo();
      case 'updateHarmonyPanelMemo':
        await service.updateDashboardMemo(args['content'] as String);
        return null;
      case 'getHarmonyPanelInterfaces':
        return service.getNetworkInterfaces();
      case 'getHarmonyPanelAppStore':
        return service.getAppStoreConfig();
      case 'updateHarmonyPanelAppStore':
        await service.updateAppStoreConfig(args['storeUrl'] as String?);
        return null;
      case 'updateHarmonyPanelProxy':
        await service.saveProxySettings(
          proxyUrl: args['proxyUrl'] as String?,
          proxyPort: args['proxyPort'] as int?,
          proxyType: args['proxyType'] as String?,
          proxyUser: args['proxyUser'] as String?,
          proxyPasswd: args['proxyPasswd'] as String?,
          proxyPasswdKeep: args['proxyPasswdKeep'] as String?,
        );
        return null;
      case 'getHarmonyPanelTerminal':
        return (await service.getTerminalSettings())?.toJson();
      case 'updateHarmonyPanelTerminal':
        await service.updateTerminalSettings(
          lineTheme: args['lineTheme'] as String?,
          fontSize: args['fontSize'] as String?,
          fontFamily: args['fontFamily'] as String?,
          backgroundColor: args['backgroundColor'] as String?,
          foregroundColor: args['foregroundColor'] as String?,
          cursorStyle: args['cursorStyle'] as String?,
          cursorBlink: args['cursorBlink'] as String?,
          scrollSensitivity: args['scrollSensitivity'] as String?,
          scrollback: args['scrollback'] as String?,
          lineHeight: args['lineHeight'] as String?,
          letterSpacing: args['letterSpacing'] as String?,
        );
        return null;
      case 'getHarmonyPanelConnection':
        return (await service.getSSHConnection()).toJson();
      case 'saveHarmonyPanelConnection':
      case 'testHarmonyPanelConnection':
        if (method == 'testHarmonyPanelConnection') {
          return service.checkSSHConnection(
            addr: args['addr'] as String,
            port: args['port'] as int,
            user: args['user'] as String,
            authMode: args['authMode'] as String,
            password: args['password'] as String?,
            privateKey: args['privateKey'] as String?,
            passPhrase: args['passPhrase'] as String?,
          );
        }
        await service.saveSSHConnection(
          addr: args['addr'] as String,
          port: args['port'] as int,
          user: args['user'] as String,
          authMode: args['authMode'] as String,
          password: args['password'] as String?,
          privateKey: args['privateKey'] as String?,
          passPhrase: args['passPhrase'] as String?,
        );
        return null;
      case 'setHarmonyPanelDefaultConnection':
        await service.updateDefaultSSHConnection(
          visible: args['visible'] as bool,
          withReset: args['withReset'] as bool? ?? false,
        );
        return null;
      case 'getHarmonyPanelUpgrade':
        await service.getUpgradeInfo();
        return {
          'version': (await service.getSystemSettings())?.systemVersion,
          'releases': await service.getUpgradeReleases(),
        };
      case 'getHarmonyPanelReleaseNotes':
        return service.getReleaseNotes(args['version'] as String);
      case 'upgradeHarmonyPanel':
        await service.upgrade(version: args['version'] as String);
        return null;
      case 'getHarmonyPanelSnapshots':
        final snapshots = await service.searchSnapshots();
        return snapshots?['items'] as List<dynamic>?;
      case 'getHarmonyPanelBackupAccounts':
        return service.getBackupAccountOptions();
      case 'getHarmonyPanelSnapshotFiles':
        return BackupAccountService().listFiles(args['backupAccountID'] as int);
      case 'createHarmonyPanelSnapshot':
        await service.createSnapshot(
          description: args['description'] as String?,
          sourceAccountIDs: args['sourceAccountIDs'] as String,
          downloadAccountID: args['downloadAccountID'] as int,
        );
        return null;
      case 'importHarmonyPanelSnapshot':
        await service.importSnapshot(
          backupAccountID: args['backupAccountID'] as int,
          names: (args['names'] as List).cast<String>(),
          description: args['description'] as String?,
        );
        return null;
      case 'deleteHarmonyPanelSnapshots':
        await service.deleteSnapshot((args['ids'] as List).cast<int>());
        return null;
      case 'recoverHarmonyPanelSnapshot':
        await service.recoverSnapshot(args['id'] as int);
        return null;
      case 'rollbackHarmonyPanelSnapshot':
        await service.rollbackSnapshot(args['id'] as int);
        return null;
      case 'describeHarmonyPanelSnapshot':
        await service.updateSnapshotDescription(args['id'] as int, args['description'] as String);
        return null;
      case 'getHarmonyPanelSsl':
        final info = await PanelSslService.forServer(server).getSslInfo();
        final expiration = info['timeout'] as String?;
        return {
          'present': info.isNotEmpty,
          'domain': info['domain'],
          'timeout': expiration,
          'rootPath': info['rootPath'],
          'health': resolveCertificateHealthStatus(expiration).name,
          'daysRemaining': daysUntilExpiration(expiration),
        };
      case 'pasteHarmonyPanelSslKey':
        return (await Clipboard.getData(Clipboard.kTextPlain))?.text;
      case 'copyHarmonyPanelSslSummary':
        await Clipboard.setData(ClipboardData(text: args['summary'] as String));
        return null;
      case 'uploadHarmonyPanelSsl':
        await PanelSslService.forServer(server).updateSsl(
          cert: args['cert'] as String,
          key: args['key'] as String,
        );
        return null;
      case 'downloadHarmonyPanelSsl':
        final result = await PanelSslService.forServer(server).downloadSsl();
        return {
          'displayName': result.file.displayName,
          'privateFallbackUsed': result.file.privateFallbackUsed,
          'cancelled': result.file.isCancelled,
          'size': result.size,
        };
      case 'getHarmonyPanelMonitor':
        final monitor = MonitoringService.forServer(server, requireSettings: true);
        final settings = await monitor.getSetting();
        return {
          'serverName': server.name,
          'interval': settings?.interval,
          'retention': settings?.retention,
          'enabled': settings?.enabled,
          'defaultIO': settings?.defaultIO,
          'defaultNetwork': settings?.defaultNetwork,
          'ioOptions': await monitor.getIOOptions(),
          'networkOptions': await monitor.getNetworkOptions(),
        };
      case 'updateHarmonyPanelMonitor':
        final updated = await MonitoringService.forServer(server, requireSettings: true).updateSetting(
          interval: args['interval'] as int?,
          retention: args['retention'] as int?,
          enabled: args['enabled'] as bool?,
          defaultIO: args['defaultIO'] as String?,
          defaultNetwork: args['defaultNetwork'] as String?,
        );
        if (!updated) throw StateError('Monitor settings were not saved');
        return null;
      case 'cleanHarmonyPanelMonitor':
        if (!await MonitoringService.forServer(server, requireSettings: true).cleanData()) {
          throw StateError('Monitoring data could not be cleared');
        }
        return null;
      default:
        throw ArgumentError.value(method, 'method');
    }
  }
}
