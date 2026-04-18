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
  });

  final int initialIndex;
  final String? initialModuleId;

  @override
  State<WindowsShellContentPage> createState() =>
      _WindowsShellContentPageState();
}

class _WindowsShellContentPageState extends State<WindowsShellContentPage> {
  late ClientModule _selectedModule;
  final WindowsShellBridge _windowsShellBridge = const WindowsShellBridge();
  WindowsCapabilitySnapshot _capabilitySnapshot =
      WindowsCapabilitySnapshot.fallback;
  bool _alwaysOnTop = false;

  @override
  void initState() {
    super.initState();
    _selectedModule = clientModuleFromId(widget.initialModuleId) ??
        _moduleFromIndex(widget.initialIndex);
    _loadBridgeCapabilities();
  }

  Future<void> _loadBridgeCapabilities() async {
    final snapshot = await _windowsShellBridge.getCapabilities();
    if (!mounted) {
      return;
    }
    setState(() {
      _capabilitySnapshot = snapshot;
    });
    appLogger.iWithPackage(
      'ui.desktop.windows.shell',
      'Windows bridge capability snapshot loaded: nativeHost=${snapshot.nativeHostAvailable}, windowCommands=${snapshot.supportsWindowCommands}, alwaysOnTop=${snapshot.supportsAlwaysOnTop}',
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
                    const Spacer(),
                    if (_capabilitySnapshot.supportsAlwaysOnTop)
                      IconButton(
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
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: () {
                          _executeWindowCommand(WindowsWindowCommand.minimize);
                        },
                        icon: const Icon(Icons.minimize),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: () {
                          _executeWindowCommand(WindowsWindowCommand.maximize);
                        },
                        icon: const Icon(Icons.crop_square),
                      ),
                      IconButton(
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
                              });
                            },
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
