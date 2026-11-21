import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/utils/intents.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/server_route_observer.dart';
import 'package:onepanel_client/features/shell/widgets/desktop_module_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_content_host.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_sidebar.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_top_tool_area.dart';

/// Flutter-side content area for macOS native shell.
///
/// Phase 2: Building macOS-specific navigation shell in Flutter (Sidebar + Top Toolbar)
class MacosShellContentPage extends StatefulWidget {
  const MacosShellContentPage({
    super.key,
    this.initialIndex = 0,
    this.initialModuleId,
    this.initialEmbeddedRouteName,
    this.initialEmbeddedRouteArguments,
  });

  final int initialIndex;
  final String? initialModuleId;
  final String? initialEmbeddedRouteName;
  final Object? initialEmbeddedRouteArguments;

  @override
  State<MacosShellContentPage> createState() => _MacosShellContentPageState();
}

class _MacosShellContentPageState extends State<MacosShellContentPage> {
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

  void _openModuleRoot(ClientModule module) {
    _contentKey.currentState?.openModuleRoot(module);
    _selectModule(module);
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
        final inputKind = PlatformUtils.inputDeviceKinds(context);
        final placement = DesktopNavigationPlacement.of(context);
        final useDrawer = placement == DesktopNavigationPlacement.drawer;
        final sidebar = DesktopSidebar(
          width: 250,
          extended: placement != DesktopNavigationPlacement.rail,
          backgroundColor: scheme.surfaceContainerLow,
          modules: modules,
          selectedModule: selectedModule,
          hasServer: currentServer.hasServer,
          onSelect: (module) =>
              ServerSwitcherAction.openModule(context, module, _selectModule),
        );

        final child = Scaffold(
          backgroundColor: scheme.surface,
          drawer: useDrawer ? Drawer(child: sidebar) : null,
          floatingActionButton: inputKind == InputDeviceKind.touch
              ? Builder(
                  builder: (context) => FloatingActionButton(
                    heroTag: 'macos_touch_sidebar_toggle_fab',
                    key: const Key('macos-touch-sidebar-toggle'),
                    tooltip:
                        MaterialLocalizations.of(context).openAppDrawerTooltip,
                    onPressed: Scaffold.of(context).openDrawer,
                    child: const Icon(Icons.menu),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!useDrawer) sidebar,
              Expanded(
                child: Column(
                  children: [
                    // macOS style Top Toolbar
                    DesktopTopToolArea(
                      showMenuButton:
                          useDrawer && inputKind == InputDeviceKind.pointer,
                      selectedModule: selectedModule,
                      backgroundColor: scheme.surface,
                      onOpenSettings: () => _selectModule(ClientModule.settings),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                        ),
                        child: Container(
                          color: scheme.surface,
                          child: DesktopContentHost(
                            key: _contentKey,
                            module: selectedModule,
                            serverId: currentServer.currentServerId,
                            serverRevision: revision,
                            panelType: panelType,
                            embeddedRoute: _embeddedRoute.name,
                            embeddedRouteArguments: _embeddedRoute.arguments,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        return DesktopModuleShortcuts(
          modifier: LogicalKeyboardKey.meta,
          modules: modules,
          onSelect: (module) => ServerSwitcherAction.openModule(
            context, module, _selectModule,
          ),
          child: child,
        );
      },
    );
    return DesktopModuleNavigation(
      onOpenModuleRoot: _openModuleRoot,
      child: Actions(
        actions: {
          OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
            onInvoke: (_) => _openModuleRoot(ClientModule.settings),
          ),
        },
        child: content,
      ),
    );
  }
}
