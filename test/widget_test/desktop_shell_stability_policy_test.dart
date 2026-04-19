import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop theme surfaces are not transparent', () async {
    final source = await File(
      'lib/core/theme/app_theme.dart',
    ).readAsString();

    expect(
      source.contains('scaffoldBackgroundColor: scheme.surface'),
      isTrue,
    );
    expect(source.contains('backgroundColor: scheme.surface'), isTrue);
    expect(
      source.contains('Colors.transparent'),
      isFalse,
      reason: 'desktop host surfaces must not be transparent',
    );
  });

  test('desktop native shells honor initialModuleId route arguments', () async {
    final uiRouteHost = await File(
      'lib/ui/routing/ui_route_host.dart',
    ).readAsString();
    final desktopShell = await File(
      'lib/ui/desktop/common/app/desktop_shell_page.dart',
    ).readAsString();
    final macosShell = await File(
      'lib/ui/desktop/macos/app/macos_shell_content_page.dart',
    ).readAsString();
    final windowsShell = await File(
      'lib/ui/desktop/windows/app/windows_shell_content_page.dart',
    ).readAsString();

    expect(uiRouteHost.contains('initialModuleId: initialModuleId'), isTrue);
    expect(macosShell.contains('this.initialModuleId,'), isTrue);
    expect(windowsShell.contains('this.initialModuleId,'), isTrue);
    expect(desktopShell.contains('this.initialModuleId,'), isTrue);
    expect(macosShell.contains('clientModuleFromId(widget.initialModuleId)'),
        isTrue);
    expect(
      windowsShell.contains('clientModuleFromId(widget.initialModuleId)'),
      isTrue,
    );
    expect(macosShell.contains('this.initialEmbeddedRouteName,'), isTrue);
    expect(desktopShell.contains('this.initialEmbeddedRouteName,'), isTrue);
  });

  test('desktop shell routes shell modules back into the shell host', () async {
    final shellNavigation = await File(
      'lib/features/shell/shell_navigation.dart',
    ).readAsString();
    final serverDetail = await File(
      'lib/features/server/server_detail_page.dart',
    ).readAsString();
    final serverSwitcher = await File(
      'lib/features/shell/widgets/server_switcher_action.dart',
    ).readAsString();
    final noServerSelected = await File(
      'lib/features/shell/widgets/no_server_selected_state.dart',
    ).readAsString();
    final operationsCenter = await File(
      'lib/features/operations_center/pages/operations_center_page.dart',
    ).readAsString();
    final toolboxCenter = await File(
      'lib/features/toolbox/pages/toolbox_center_page.dart',
    ).readAsString();
    final appDrawer = await File(
      'lib/widgets/navigation/app_drawer.dart',
    ).readAsString();
    final quickActions = await File(
      'lib/features/dashboard/widgets/quick_actions_card.dart',
    ).readAsString();
    final settingsPage = await File(
      'lib/pages/settings/settings_page.dart',
    ).readAsString();
    final systemSettings = await File(
      'lib/features/settings/system_settings_page.dart',
    ).readAsString();
    final legalCenter = await File(
      'lib/features/settings/legal_center_page.dart',
    ).readAsString();
    final websiteList = await File(
      'lib/features/websites/pages/website_list_page_body.dart',
    ).readAsString();
    final installedAppsView = await File(
      'lib/features/apps/widgets/installed_apps_view.dart',
    ).readAsString();
    final databasesPage = await File(
      'lib/features/databases/databases_page.dart',
    ).readAsString();
    final runtimesPage = await File(
      'lib/features/runtimes/pages/runtimes_center_page.dart',
    ).readAsString();
    final containersActions = await File(
      'lib/features/containers/containers_page/containers_page_actions_part.dart',
    ).readAsString();
    final firewallRulesTab = await File(
      'lib/features/firewall/firewall_rules_tab.dart',
    ).readAsString();
    final firewallIpTab = await File(
      'lib/features/firewall/firewall_ip_tab.dart',
    ).readAsString();
    final firewallPortTab = await File(
      'lib/features/firewall/firewall_port_tab.dart',
    ).readAsString();
    final appRouter = await File(
      'lib/config/app_router.dart',
    ).readAsString();
    final uiRouteHost = await File(
      'lib/ui/routing/ui_route_host.dart',
    ).readAsString();
    final macosShell = await File(
      'lib/ui/desktop/macos/app/macos_shell_content_page.dart',
    ).readAsString();
    final desktopShell = await File(
      'lib/ui/desktop/common/app/desktop_shell_page.dart',
    ).readAsString();
    final windowsShell = await File(
      'lib/ui/desktop/windows/app/windows_shell_content_page.dart',
    ).readAsString();
    final desktopContentHost = await File(
      'lib/ui/desktop/common/widgets/desktop_content_host.dart',
    ).readAsString();

    expect(shellNavigation.contains('pushReplacementNamed('), isTrue);
    expect(shellNavigation.contains("'module': target.module.storageId"),
        isTrue);
    expect(shellNavigation.contains("shellArguments['route'] = route;"),
        isTrue);
    expect(shellNavigation.contains('embedRouteInShell: true'), isTrue);
    expect(serverDetail.contains('openRouteRespectingShell(context, route);'),
        isTrue);
    expect(serverSwitcher.contains('openRouteRespectingShell('), isTrue);
    expect(
      noServerSelected.contains(
        'openRouteRespectingShell(context, AppRoutes.server)',
      ),
      isTrue,
    );
    expect(operationsCenter.contains('openRouteRespectingShell(context, entry.route)'),
        isTrue);
    expect(toolboxCenter.contains('openRouteRespectingShell(context, AppRoutes.toolboxClam)'),
        isTrue);
    expect(appDrawer.contains('openRouteRespectingShell(context, AppRoutes.server)'),
        isTrue);
    expect(
      quickActions.contains('openRouteRespectingShell(context, AppRoutes.backups)'),
      isTrue,
    );
    expect(
      settingsPage.contains('openRouteRespectingShell(context, AppRoutes.server)'),
      isTrue,
    );
    expect(
      systemSettings.contains('openRouteRespectingShell(context, AppRoutes.menuSettings)'),
      isTrue,
    );
    expect(
      legalCenter.contains('openRouteRespectingShell('),
      isTrue,
    );
    expect(
      websiteList.contains('openRouteRespectingShell(context, AppRoutes.openrestyCenter)'),
      isTrue,
    );
    expect(
      websiteList.contains('openRouteRespectingShell(context, AppRoutes.websiteCreate)'),
      isTrue,
    );
    expect(
      installedAppsView.contains('openRouteRespectingShell(context, AppRoutes.appStore)'),
      isTrue,
    );
    expect(
      databasesPage.contains('openRouteRespectingShell('),
      isTrue,
    );
    expect(
      runtimesPage.contains('openRouteRespectingShell('),
      isTrue,
    );
    expect(
      containersActions.contains("openRouteRespectingShell(context, '/container-create')"),
      isTrue,
    );
    expect(
      firewallRulesTab.contains('openRouteRespectingShell('),
      isTrue,
    );
    expect(
      firewallRulesTab.contains('PlatformUtils.isDesktop(context)'),
      isTrue,
    );
    expect(
      firewallRulesTab.contains('await Navigator.pushNamed('),
      isTrue,
    );
    expect(
      firewallIpTab.contains('openRouteRespectingShell('),
      isTrue,
    );
    expect(
      firewallIpTab.contains('PlatformUtils.isDesktop(context)'),
      isTrue,
    );
    expect(
      firewallIpTab.contains('await Navigator.pushNamed('),
      isTrue,
    );
    expect(
      firewallPortTab.contains('openRouteRespectingShell('),
      isTrue,
    );
    expect(
      firewallPortTab.contains('PlatformUtils.isDesktop(context)'),
      isTrue,
    );
    expect(
      firewallPortTab.contains('await Navigator.pushNamed('),
      isTrue,
    );
    expect(appRouter.contains('RouteRegistry.registerAll('), isTrue);
    expect(appRouter.contains('UiTargetResolver.resolve(context)'), isTrue);
    expect(uiRouteHost.contains('initialEmbeddedRouteName:'), isTrue);
    expect(macosShell.contains('embeddedRoute: _embeddedRouteName,'), isTrue);
    expect(desktopShell.contains('embeddedRoute: _embeddedRouteName,'), isTrue);
    expect(windowsShell.contains('this.initialEmbeddedRouteName,'), isTrue);
    expect(desktopContentHost.contains('DesktopRoutedModuleHost('), isTrue);
  });

  test('high-risk desktop item builders use snapshot wrapper variables',
      () async {
    final filesItem = await File(
      'lib/features/files/files_page/files_page_item_part.dart',
    ).readAsString();
    final websitesList = await File(
      'lib/features/websites/pages/website_list_page_body.dart',
    ).readAsString();

    expect(filesItem.contains('final selectableContent = content;'), isTrue);
    expect(filesItem.contains('final draggableContent = content;'), isTrue);
    expect(filesItem.contains('child: selectableContent,'), isTrue);
    expect(filesItem.contains('child: draggableContent,'), isTrue);

    expect(
        websitesList.contains('final desktopCardContent = content;'), isTrue);
    expect(websitesList.contains('child: desktopCardContent,'), isTrue);
  });
}
