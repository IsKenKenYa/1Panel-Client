import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/features/shell/app_shell_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/server_route_observer.dart';
import 'package:onepanel_client/features/shell/widgets/desktop_module_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_content_host.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_sidebar.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_top_tool_area.dart';
import 'package:onepanel_client/ui/routing/ui_target.dart';

/// Desktop shell entry for platforms that use Flutter-managed UI (Linux/Web).
///
/// This is the "true desktop shell": sidebar + top tool area + content.
class DesktopShellPage extends StatefulWidget {
  const DesktopShellPage({
    super.key,
    this.initialIndex = 0,
    this.initialModuleId,
    this.initialEmbeddedRouteName,
    this.initialEmbeddedRouteArguments,
    this.useWebNavigation = false,
  });

  final int initialIndex;
  final String? initialModuleId;
  final String? initialEmbeddedRouteName;
  final Object? initialEmbeddedRouteArguments;
  final bool useWebNavigation;

  @override
  State<DesktopShellPage> createState() => _DesktopShellPageState();
}

class _DesktopShellPageState extends State<DesktopShellPage> {
  final _contentKey = GlobalKey<DesktopContentHostState>();
  late ClientModule _selectedModule;
  late final _embeddedRoute = ShellEmbeddedRoute(
    widget.initialEmbeddedRouteName, widget.initialEmbeddedRouteArguments,
  );

  @override
  void initState() {
    super.initState();
    _selectedModule =
        initialShellModule(widget.initialIndex, widget.initialModuleId);
  }

  void _selectModule(ClientModule module) {
    setState(() {
      _selectedModule = module;
      _embeddedRoute.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Consumer2<CurrentServerController, PinnedModulesController>(
      builder: (context, currentServer, pinnedModules, _) {
        final scheme = Theme.of(context).colorScheme;
        final panelType = currentServer.currentServer?.panelType;
        final modules = shellModulesForPanel(panelType, pinnedModules.pins);
        final selectedModule =
            _selectedModule.forServer(currentServer.currentServer);
        final revision = currentServer.currentServer?.revision;
        _embeddedRoute.updateConnection(currentServer.currentServerId, revision);
        ServerRouteObserver.setActiveModule(context,
            module: selectedModule,
            needsServer: selectedModule.requiresServer ||
                routeNeedsServerConnection(_embeddedRoute.name));
        final moduleContent = DesktopContentHost(
          key: _contentKey,
          module: selectedModule,
          serverId: currentServer.currentServerId,
          serverRevision: revision,
          panelType: panelType,
          embeddedRoute: _embeddedRoute.name,
          embeddedRouteArguments: _embeddedRoute.arguments,
        );
        final spec = AdaptiveLayoutSpec.of(context);
        if (widget.useWebNavigation && !spec.isDesktop) {
          return AppShellPage(
            selectedModule: selectedModule,
            onSelectModule: _selectModule,
            body: moduleContent,
            tabletKind: spec.isTablet ? TabletKind.webTablet : TabletKind.none,
          );
        }
        final placement = DesktopNavigationPlacement.of(context);
        final useDrawer = placement == DesktopNavigationPlacement.drawer;
        final sidebar = DesktopSidebar(
          extended: placement != DesktopNavigationPlacement.rail,
          modules: modules,
          selectedModule: selectedModule,
          hasServer: currentServer.hasServer,
          onSelect: (module) =>
              ServerSwitcherAction.openModule(context, module, _selectModule),
        );
        return Scaffold(
          backgroundColor: scheme.surface,
          drawer: useDrawer ? Drawer(child: sidebar) : null,
          body: Column(
            children: [
              DesktopTopToolArea(
                showMenuButton: useDrawer,
                selectedModule: selectedModule,
                onOpenSettings: () => _selectModule(ClientModule.settings),
              ),
              Expanded(
                child: Row(
                  children: [
                    if (!useDrawer) sidebar,
                    Expanded(
                      child: ColoredBox(
                        color: scheme.surface,
                        child: moduleContent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    return DesktopModuleNavigation(
      onOpenModuleRoot: (module) {
        _contentKey.currentState?.openModuleRoot(module);
        _selectModule(module);
      },
      child: content,
    );
  }
}
