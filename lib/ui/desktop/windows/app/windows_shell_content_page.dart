import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/server_route_observer.dart';
import 'package:onepanel_client/features/shell/widgets/desktop_module_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_content_host.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_sidebar.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_top_tool_area.dart';

/// Flutter-side content area for Windows Fluent / WinUI native shell.
///
/// Phase 2: Windows specific navigation shell (Custom Titlebar integration + Sidebar)
class WindowsShellContentPage extends StatefulWidget {
  const WindowsShellContentPage({
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
  State<WindowsShellContentPage> createState() =>
      _WindowsShellContentPageState();
}

class _WindowsShellContentPageState extends State<WindowsShellContentPage> {
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
        final hasEmbeddedRoute =
            _embeddedRoute.name?.isNotEmpty ?? false;
        void openModule(ClientModule module) {
          ServerSwitcherAction.openModule(context, module, _selectModule);
        }

        final placement = DesktopNavigationPlacement.of(context);
        final useDrawer = placement == DesktopNavigationPlacement.drawer;
        final sidebar = DesktopSidebar(
          width: 280,
          extended: placement != DesktopNavigationPlacement.rail,
          backgroundColor: scheme.surfaceContainerLow,
          modules: modules,
          selectedModule: selectedModule,
          hasServer: currentServer.hasServer,
          onSelect: openModule,
        );

        final child = Scaffold(
          backgroundColor: scheme.surface,
          drawer: useDrawer ? Drawer(child: sidebar) : null,
          body: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (!useDrawer) sidebar,
                    Expanded(
                      child: Column(
                        children: [
                          DesktopTopToolArea(
                            showMenuButton: useDrawer,
                            selectedModule: selectedModule,
                            backgroundColor: scheme.surface,
                            onOpenSettings: () =>
                                _selectModule(ClientModule.settings),
                          ),
                          if (hasEmbeddedRoute)
                            Container(
                              height: 36,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                border: Border(
                                  bottom:
                                      BorderSide(color: scheme.outlineVariant),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.web_stories_outlined,
                                    size: 16,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _embeddedRoute.name!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Return to module root',
                                    visualDensity: VisualDensity.compact,
                                    iconSize: 16,
                                    onPressed: () {
                                      setState(() {
                                        _embeddedRoute.clear();
                                      });
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
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
                                  embeddedRouteArguments:
                                      _embeddedRoute.arguments,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        return DesktopModuleShortcuts(
          modifier: LogicalKeyboardKey.control,
          modules: modules,
          onSelect: openModule,
          child: child,
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
