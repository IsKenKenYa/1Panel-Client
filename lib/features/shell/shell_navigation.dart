import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/shell_content_host.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/shell_fade_through_route.dart';

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
    case AppRoutes.fileShare:
    case AppRoutes.wgetManager:
    case AppRoutes.fileHistory:
    case AppRoutes.filePermission:
    case AppRoutes.recycleBinStatus:
      return const ShellRouteTarget(
        module: ClientModule.files,
        embedRouteInShell: true,
      );
    case AppRoutes.containers:
      return const ShellRouteTarget(
        module: ClientModule.containers,
        embedRouteInShell: false,
      );
    case '/container-create':
    case AppRoutes.containerDetail:
    case AppRoutes.containerInspect:
    case AppRoutes.containerFiles:
    case AppRoutes.containerMaintenance:
    case AppRoutes.dockerConfig:
    case AppRoutes.imageOperations:
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
    case AppRoutes.websiteTemplates:
    case AppRoutes.websiteTemplateForm:
    case AppRoutes.websiteTemplateOutputs:
    case AppRoutes.websiteTemplateOutputCreate:
    case AppRoutes.websiteHttps:
    case AppRoutes.websiteRedirect:
    case AppRoutes.websiteCors:
    case AppRoutes.websiteLeech:
    case AppRoutes.websiteLog:
    case AppRoutes.websiteAuthBasic:
    case AppRoutes.websiteResource:
    case AppRoutes.websiteLoadBalancer:
    case AppRoutes.securityGatewayCenter:
      return const ShellRouteTarget(
        module: ClientModule.websites,
        embedRouteInShell: true,
      );
    case AppRoutes.ai:
      return const ShellRouteTarget(
        module: ClientModule.ai,
        embedRouteInShell: false,
      );
    case AppRoutes.aiAccounts:
    case AppRoutes.aiOllamaModels:
    case AppRoutes.aiAgents:
    case AppRoutes.aiGpuHistory:
    case AppRoutes.mcpServerDetail:
    case AppRoutes.aiAgentPlugins:
      return const ShellRouteTarget(
        module: ClientModule.ai,
        embedRouteInShell: true,
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
    case AppRoutes.databaseMongodb:
    case AppRoutes.databaseMysqlVariables:
    case AppRoutes.databasePgPrivileges:
    case AppRoutes.databaseRedisPersistence:
    case AppRoutes.databaseSlowLog:
    case AppRoutes.databaseRemoteConfig:
    case AppRoutes.firewall:
    case AppRoutes.firewallRules:
    case AppRoutes.firewallIps:
    case AppRoutes.firewallPorts:
    case AppRoutes.firewallRuleForm:
    case AppRoutes.firewallV2:
    case AppRoutes.firewallV2Rules:
    case AppRoutes.firewallV2Forward:
    case AppRoutes.firewallV2Docker:
    case AppRoutes.firewallV2Settings:
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

/// Returns the [NavigatorState] of the [ShellContentHost] that wraps
/// `context`, or `null` when no host is mounted (e.g. during the first
/// frame, on a platform that does not use the desktop/tablet shell, or
/// when the caller lives outside any [ShellContentHost] such as a
/// top-level sidebar item that just wants to swap modules).
///
/// The lookup walks up the widget tree from the caller's [BuildContext]
/// to find the nearest [ShellContentHost] state. This avoids the
/// previous single-static-[GlobalKey] approach which — when the outer
/// `DesktopContentHost` mounted *all* module hosts via `IndexedStack`
/// at the same time — collided on key uniqueness and silently dropped
/// the inner `Navigator` of the previously-inactive module, which
/// manifested as "page content lost after opening several modules".
NavigatorState? findShellContentNavigator(BuildContext context) {
  // Walk the ancestor chain manually so the caller's own element is
  // also considered (findAncestorStateOfType skips the current
  // element, which matters when the caller IS a ShellContentHost
  // element — e.g. unit tests that grab `tester.element(...)`).
  final ShellContentHostState? direct = (context.widget is ShellContentHost)
      ? (context as StatefulElement).state as ShellContentHostState?
      : null;
  if (direct != null) {
    return direct.innerNavigator;
  }
  return context.findAncestorStateOfType<ShellContentHostState>()?.innerNavigator;
}

Future<void> openRouteRespectingShell(
  BuildContext context,
  String route, {
  Object? arguments,
}) {
  final target = shellRouteTargetForRoute(route);
  if (target != null && PlatformUtils.isDesktop(context)) {
    // When the route is a sub-page of a module (e.g. container detail
    // inside the containers module) push it into the shell's inner
    // navigator so only the content area animates; the surrounding
    // NavigationRail / AppBar stays stable.
    if (target.embedRouteInShell) {
      final innerNavigator = findShellContentNavigator(context);
      if (innerNavigator != null) {
        return innerNavigator.push(
          _buildShellSubPageRoute(context, route, arguments),
        );
      }
      // Fall back to the legacy behaviour when the inner navigator
      // has not been mounted yet (e.g. mid-build, or shell not yet
      // visible).
      return Navigator.of(context).pushReplacementNamed(
        AppRoutes.home,
        arguments: _buildShellHomeArguments(
          target: target,
          route: route,
          arguments: arguments,
        ),
      );
    }

    return Navigator.of(context).pushReplacementNamed(
      AppRoutes.home,
      arguments: <String, dynamic>{
        'module': target.module.storageId,
      },
    );
  }

  // Mobile uses traditional push navigation; the shell is not involved.
  return Navigator.of(context).pushNamed(route, arguments: arguments);
}

Route<T> _buildShellSubPageRoute<T>(
  BuildContext context,
  String route,
  Object? arguments,
) {
  return ShellFadeThroughPageRoute<T>(
    settings: RouteSettings(name: route, arguments: arguments),
    builder: (context) {
      // `generateEmbeddedRoute` always resolves via the route's
      // `defaultBuilder` (skipping the desktop platform override
      // that would otherwise re-host the page inside a fresh shell)
      // and returns a `PageRoute` whose builder produces the actual
      // page widget. We extract that widget and re-mount it inside
      // our own fade-through transition so the inner navigator
      // controls the animation instead of the inner route.
      final embedded = AppRouter.generateEmbeddedRoute(
        RouteSettings(name: route, arguments: arguments),
      );
      if (embedded is PageRoute<T>) {
        return embedded.buildPage(
          context,
          const AlwaysStoppedAnimation<double>(1.0),
          const AlwaysStoppedAnimation<double>(1.0),
        );
      }
      return const SizedBox.shrink();
    },
  );
}

Map<String, dynamic> _buildShellHomeArguments({
  required ShellRouteTarget target,
  required String route,
  Object? arguments,
}) {
  final shellArguments = <String, dynamic>{
    'module': target.module.storageId,
    'route': route,
  };
  if (arguments != null) {
    shellArguments['routeArgs'] = arguments;
  }
  return shellArguments;
}
