import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';

class ShellRouteTarget {
  const ShellRouteTarget({
    required this.module,
    required this.embedRouteInShell,
  });

  final ClientModule module;
  final bool embedRouteInShell;
}

ClientModule? shellModuleForRoute(String route) {
  return shellRouteTargetForRoute(route)?.module;
}

ShellRouteTarget? shellRouteTargetForRoute(String route) {
  switch (route) {
    case AppRoutes.server:
    case AppRoutes.serverSelection:
      return const ShellRouteTarget(
        module: ClientModule.servers,
        embedRouteInShell: false,
      );
    case AppRoutes.serverConfig:
    case AppRoutes.serverDetail:
      return const ShellRouteTarget(
        module: ClientModule.servers,
        embedRouteInShell: true,
      );
    case AppRoutes.files:
      return const ShellRouteTarget(
        module: ClientModule.files,
        embedRouteInShell: false,
      );
    case AppRoutes.containers:
      return const ShellRouteTarget(
        module: ClientModule.containers,
        embedRouteInShell: false,
      );
    case '/container-create':
    case AppRoutes.containerDetail:
    case AppRoutes.orchestration:
      return const ShellRouteTarget(
        module: ClientModule.containers,
        embedRouteInShell: true,
      );
    case AppRoutes.apps:
      return const ShellRouteTarget(
        module: ClientModule.apps,
        embedRouteInShell: false,
      );
    case AppRoutes.appStore:
    case AppRoutes.appDetail:
    case AppRoutes.installedAppDetail:
      return const ShellRouteTarget(
        module: ClientModule.apps,
        embedRouteInShell: true,
      );
    case AppRoutes.websites:
      return const ShellRouteTarget(
        module: ClientModule.websites,
        embedRouteInShell: false,
      );
    case AppRoutes.websiteCreate:
    case AppRoutes.websiteEdit:
    case AppRoutes.websiteDetail:
    case AppRoutes.websiteConfigCenter:
    case AppRoutes.websiteRoutingRules:
    case AppRoutes.websiteSecurityAccess:
    case AppRoutes.websiteDomains:
    case AppRoutes.websiteSiteSsl:
    case AppRoutes.websiteSslCenter:
    case AppRoutes.websiteCertificateDetail:
      return const ShellRouteTarget(
        module: ClientModule.websites,
        embedRouteInShell: true,
      );
    case AppRoutes.ai:
      return const ShellRouteTarget(
        module: ClientModule.ai,
        embedRouteInShell: false,
      );
    case AppRoutes.securityVerification:
      return const ShellRouteTarget(
        module: ClientModule.verification,
        embedRouteInShell: false,
      );
    case AppRoutes.settings:
      return const ShellRouteTarget(
        module: ClientModule.settings,
        embedRouteInShell: false,
      );
    case AppRoutes.settingsLanguage:
    case AppRoutes.settingsFeedbackCenter:
    case AppRoutes.settingsLegalCenter:
    case AppRoutes.settingsMainlandSdkDisclosure:
    case AppRoutes.systemSettings:
    case AppRoutes.menuSettings:
    case AppRoutes.panelSsl:
      return const ShellRouteTarget(
        module: ClientModule.settings,
        embedRouteInShell: true,
      );

    case AppRoutes.dashboard:
    case AppRoutes.databases:
    case AppRoutes.databaseDetail:
    case AppRoutes.databaseForm:
    case AppRoutes.databaseRemote:
    case AppRoutes.databaseRedisConfig:
    case AppRoutes.databaseBackups:
    case AppRoutes.databaseUsers:
    case AppRoutes.firewall:
    case AppRoutes.firewallRules:
    case AppRoutes.firewallIps:
    case AppRoutes.firewallPorts:
    case AppRoutes.firewallRuleForm:
    case AppRoutes.terminal:
    case AppRoutes.monitoring:
    case AppRoutes.operations:
    case AppRoutes.groupCenter:
    case AppRoutes.toolbox:
    case AppRoutes.toolboxDevice:
    case AppRoutes.toolboxDisk:
    case AppRoutes.toolboxClam:
    case AppRoutes.toolboxFail2ban:
    case AppRoutes.toolboxFtp:
    case AppRoutes.toolboxHostTool:
    case AppRoutes.commands:
    case AppRoutes.commandForm:
    case AppRoutes.hostAssets:
    case AppRoutes.hostAssetForm:
    case AppRoutes.ssh:
    case AppRoutes.sshCerts:
    case AppRoutes.sshLogs:
    case AppRoutes.sshSessions:
    case AppRoutes.processes:
    case AppRoutes.processDetail:
    case AppRoutes.cronjobs:
    case AppRoutes.cronjobForm:
    case AppRoutes.cronjobRecords:
    case AppRoutes.scripts:
    case AppRoutes.backups:
    case AppRoutes.backupAccountForm:
    case AppRoutes.backupRecords:
    case AppRoutes.backupRecover:
    case AppRoutes.logs:
    case AppRoutes.systemLogViewer:
    case AppRoutes.taskLogDetail:
    case AppRoutes.runtimes:
    case AppRoutes.runtimeDetail:
    case AppRoutes.runtimeForm:
    case AppRoutes.phpExtensions:
    case AppRoutes.phpConfig:
    case AppRoutes.phpSupervisor:
    case AppRoutes.nodeModules:
    case AppRoutes.nodeScripts:
    case AppRoutes.openrestyCenter:
    case AppRoutes.openrestySourceEditor:
      return const ShellRouteTarget(
        module: ClientModule.servers,
        embedRouteInShell: true,
      );
  }
  return null;
}

Future<void> openRouteRespectingShell(
  BuildContext context,
  String route, {
  Object? arguments,
}) {
  final target = shellRouteTargetForRoute(route);
  if (target != null && PlatformUtils.isDesktop(context)) {
    final shellArguments = <String, dynamic>{
      'module': target.module.storageId,
    };
    if (target.embedRouteInShell) {
      shellArguments['route'] = route;
      if (arguments != null) {
        shellArguments['routeArgs'] = arguments;
      }
    }

    return Navigator.of(context).pushReplacementNamed(
      AppRoutes.home,
      arguments: shellArguments,
    );
  }

  return Navigator.of(context).pushNamed(route, arguments: arguments);
}
