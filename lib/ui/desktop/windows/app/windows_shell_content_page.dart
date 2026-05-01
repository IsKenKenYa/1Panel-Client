import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
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
  late ClientModule _selectedModule;
  String? _embeddedRouteName;
  Object? _embeddedRouteArguments;

  @override
  void initState() {
    super.initState();
    _selectedModule = clientModuleFromId(widget.initialModuleId) ??
        _moduleFromIndex(widget.initialIndex);
    _embeddedRouteName = widget.initialEmbeddedRouteName;
    _embeddedRouteArguments = widget.initialEmbeddedRouteArguments;
  }

  ClientModule _moduleFromIndex(int index) {
    switch (index.clamp(0, 3)) {
      case 0:
        return ClientModule.servers;
      case 1:
        return ClientModule.files;
      case 2:
        return ClientModule.containers;
      case 3:
        return ClientModule.settings;
      default:
        return ClientModule.servers;
    }
  }

  List<ClientModule> _desktopModules(PinnedModulesController pinnedModules) {
    final slots = <ClientModule>[
      ClientModule.servers,
      pinnedModules.primaryPin,
      pinnedModules.secondaryPin,
    ];

    for (final module in kPinnableClientModules) {
      if (!slots.contains(module)) {
        slots.add(module);
      }
    }

    slots.add(ClientModule.settings);
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CurrentServerController, PinnedModulesController>(
      builder: (context, currentServer, pinnedModules, _) {
        final scheme = Theme.of(context).colorScheme;
        final modules = _desktopModules(pinnedModules);
        final selectedModule =
            (!currentServer.hasServer && _selectedModule.requiresServer)
                ? ClientModule.servers
                : _selectedModule;
        final hasEmbeddedRoute =
            _embeddedRouteName != null && _embeddedRouteName!.isNotEmpty;

        final child = Scaffold(
          backgroundColor: scheme.surface,
          body: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Windows style Sidebar
                    DesktopSidebar(
                      width: 280,
                      backgroundColor: scheme.surfaceContainerLow,
                      modules: modules,
                      selectedModule: selectedModule,
                      hasServer: currentServer.hasServer,
                      onSelect: (module) {
                        if (!currentServer.hasServer && module.requiresServer) {
                          ServerSwitcherAction.showServerPicker(context);
                          return;
                        }
                        setState(() {
                          _selectedModule = module;
                          _embeddedRouteName = null;
                          _embeddedRouteArguments = null;
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          DesktopTopToolArea(
                            selectedModule: selectedModule,
                            backgroundColor: scheme.surface,
                            onOpenSettings: () {
                              setState(() {
                                _selectedModule = ClientModule.settings;
                                _embeddedRouteName = null;
                                _embeddedRouteArguments = null;
                              });
                            },
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
                                      _embeddedRouteName!,
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
                                        _embeddedRouteName = null;
                                        _embeddedRouteArguments = null;
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
                                  module: selectedModule,
                                  serverId: currentServer.currentServerId,
                                  embeddedRoute: _embeddedRouteName,
                                  embeddedRouteArguments:
                                      _embeddedRouteArguments,
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

        return CallbackShortcuts(
          bindings: {
            for (int i = 0; i < modules.length && i < 9; i++)
              LogicalKeySet(
                  LogicalKeyboardKey.control, LogicalKeyboardKey(49 + i)): () {
                final module = modules[i];
                if (!currentServer.hasServer && module.requiresServer) {
                  ServerSwitcherAction.showServerPicker(context);
                  return;
                }
                setState(() {
                  _selectedModule = module;
                  _embeddedRouteName = null;
                  _embeddedRouteArguments = null;
                });
              },
          },
          child: Focus(
            autofocus: true,
            child: child,
          ),
        );
      },
    );
  }
}
