import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/channel/windows/windows_capability_whitelist.dart';
import 'package:onepanel_client/core/channel/windows/windows_shell_bridge.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
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
  final WindowsShellBridge _windowsShellBridge = WindowsShellBridge();
  WindowsCapabilitySnapshot _capabilitySnapshot =
      WindowsCapabilitySnapshot.fallback;
  bool _alwaysOnTop = false;
  String _systemBackdropMode = 'unknown';
  String? _embeddedRouteName;
  Object? _embeddedRouteArguments;

  @override
  void initState() {
    super.initState();
    _selectedModule = clientModuleFromId(widget.initialModuleId) ??
        _moduleFromIndex(widget.initialIndex);
    _embeddedRouteName = widget.initialEmbeddedRouteName;
    _embeddedRouteArguments = widget.initialEmbeddedRouteArguments;
    _loadBridgeCapabilities();
  }

  Future<void> _loadBridgeCapabilities() async {
    final snapshot = await _windowsShellBridge.getCapabilities();
    final state = await _windowsShellBridge.getWindowState();
    if (!mounted) {
      return;
    }
    setState(() {
      _capabilitySnapshot = snapshot;
      _alwaysOnTop = state.isAlwaysOnTop;
      _systemBackdropMode = state.systemBackdropMode;
    });
    appLogger.iWithPackage(
      'ui.desktop.windows.shell',
      'Windows bridge capability snapshot loaded: nativeHost=${snapshot.nativeHostAvailable}, windowCommands=${snapshot.supportsWindowCommands}, alwaysOnTop=${snapshot.supportsAlwaysOnTop}, systemBackdrop=${snapshot.supportsSystemBackdrop}, backdropMode=${state.systemBackdropMode}',
    );
  }

  Future<void> _executeWindowCommand(
    WindowsWindowCommand command, {
    bool? enabled,
  }) async {
    final ok = await _windowsShellBridge.performWindowCommand(
      command,
      enabled: enabled,
    );
    if (!ok) {
      appLogger.wWithPackage(
        'ui.desktop.windows.shell',
        'Windows bridge command failed: ${WindowsCapabilityWhitelist.commandName(command)}',
      );
    }
  }

  Future<void> _switchSystemBackdrop(WindowsSystemBackdropMode mode) async {
    final ok = await _windowsShellBridge.setSystemBackdrop(mode);
    if (!ok) {
      appLogger.wWithPackage(
        'ui.desktop.windows.shell',
        'Windows bridge backdrop switch failed: ${WindowsCapabilityWhitelist.systemBackdropModeName(mode)}',
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _systemBackdropMode =
          WindowsCapabilityWhitelist.systemBackdropModeName(mode);
    });
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
              // Custom Titlebar Placeholder for Windows (Will be integrated with window_manager in Task 3)
              Container(
                height: 32,
                width: double.infinity,
                color: scheme.surface,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Text(
                      context.l10n.appName,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 14,
                      color: scheme.outlineVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedModule.label(context.l10n),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    if (hasEmbeddedRoute) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.route_outlined,
                                size: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _embeddedRouteName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      tooltip: context.l10n.commonRefresh,
                      visualDensity: VisualDensity.compact,
                      iconSize: 16,
                      onPressed: _loadBridgeCapabilities,
                      icon: const Icon(Icons.refresh),
                    ),
                    if (_capabilitySnapshot.supportsSystemBackdrop)
                      PopupMenuButton<WindowsSystemBackdropMode>(
                        tooltip: 'System backdrop',
                        iconSize: 16,
                        onSelected: _switchSystemBackdrop,
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: WindowsSystemBackdropMode.mica,
                            child: Text('Mica'),
                          ),
                          PopupMenuItem(
                            value: WindowsSystemBackdropMode.acrylic,
                            child: Text('Acrylic'),
                          ),
                          PopupMenuItem(
                            value: WindowsSystemBackdropMode.none,
                            child: Text('None'),
                          ),
                          PopupMenuItem(
                            value: WindowsSystemBackdropMode.auto,
                            child: Text('Auto'),
                          ),
                          PopupMenuItem(
                            value: WindowsSystemBackdropMode.tabbed,
                            child: Text('Tabbed'),
                          ),
                        ],
                        icon: const Icon(Icons.blur_on_outlined),
                      ),
                    if (_capabilitySnapshot.supportsSystemBackdrop)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          _systemBackdropMode,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    if (_capabilitySnapshot.supportsAlwaysOnTop)
                      IconButton(
                        tooltip: 'Always on top',
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: () async {
                          final nextValue = !_alwaysOnTop;
                          await _executeWindowCommand(
                            WindowsWindowCommand.setAlwaysOnTop,
                            enabled: nextValue,
                          );
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _alwaysOnTop = nextValue;
                          });
                        },
                        icon: Icon(
                          _alwaysOnTop
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                        ),
                      ),
                    if (_capabilitySnapshot.supportsWindowCommands) ...[
                      IconButton(
                        tooltip: 'Minimize',
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: () {
                          _executeWindowCommand(WindowsWindowCommand.minimize);
                        },
                        icon: const Icon(Icons.minimize),
                      ),
                      IconButton(
                        tooltip: 'Maximize',
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: () {
                          _executeWindowCommand(WindowsWindowCommand.maximize);
                        },
                        icon: const Icon(Icons.crop_square),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: () {
                          _executeWindowCommand(WindowsWindowCommand.close);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ],
                ),
              ),
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
