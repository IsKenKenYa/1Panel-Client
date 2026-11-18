import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/security/app_lock_controller.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/module_page_factory.dart';
import 'package:onepanel_client/features/shell/module_registry.dart';
import 'package:onepanel_client/features/shell/widgets/adaptive_shell_navigation_widget.dart';
import 'package:onepanel_client/features/shell/widgets/channel_watermark_badge_widget.dart';
import 'package:onepanel_client/features/shell/widgets/mobile_more_modules_drawer.dart';
import 'package:onepanel_client/features/shell/widgets/shell_drawer_scope.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanel_client/widgets/navigation/app_bottom_navigation_bar.dart';

import '../../core/utils/snackbar_utils.dart';
import '../../core/theme/ui_render_policy.dart';
class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    this.initialIndex = 0,
    this.initialModuleId,
  });

  final int initialIndex;
  final String? initialModuleId;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  final GlobalKey<ScaffoldState> _mobileScaffoldKey =
      GlobalKey<ScaffoldState>();
  late ClientModule _selectedModule;

  @override
  void initState() {
    super.initState();
    _selectedModule = clientModuleFromId(widget.initialModuleId) ??
        _moduleFromIndex(widget.initialIndex);
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

  List<ClientModule> _mobileSlots(PinnedModulesController pinnedModules) {
    return <ClientModule>[
      ClientModule.servers,
      pinnedModules.primaryPin,
      pinnedModules.secondaryPin,
      ClientModule.settings,
    ];
  }

  List<ClientModule> _wideSlots(PinnedModulesController pinnedModules) {
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
        final width = MediaQuery.sizeOf(context).width;
        final isCompact = width < 600;
        final modules =
            isCompact ? _mobileSlots(pinnedModules) : _wideSlots(pinnedModules);
        final moreModules = isCompact
            ? kPinnableClientModules
                .where((module) => !modules.contains(module))
                .toList(growable: false)
            : const <ClientModule>[];
        final selectedModule =
            (!currentServer.hasServer && _selectedModule.requiresServer)
                ? ClientModule.servers
                : _selectedModule;
        final selectedIndex = modules.contains(selectedModule)
            ? modules.indexOf(selectedModule)
            : 0;

        final body =
            buildShellModulePage(
          context,
          module: selectedModule,
          serverId: currentServer.currentServerId,
        );

        if (width >= 1024) {
          return _wrapWithChannelWatermark(
            Scaffold(
              body: Row(
                children: [
                  ShellSidebarNavigation(
                    modules: modules,
                    selectedModule: selectedModule,
                    hasServer: currentServer.hasServer,
                    onSelect: (module) =>
                        _handleModuleSelection(module, currentServer.hasServer),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              ),
            ),
          );
        }

        if (width >= 600) {
          return _wrapWithChannelWatermark(
            Scaffold(
              body: Row(
                children: [
                  ShellRailNavigation(
                    modules: modules,
                    selectedModule: selectedModule,
                    hasServer: currentServer.hasServer,
                    onSelect: (module) =>
                        _handleModuleSelection(module, currentServer.hasServer),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              ),
            ),
          );
        }

        final l10n = context.l10n;
        final items = [
          for (final module in modules)
            AppNavigationBarItem(
              icon: module.icon,
              selectedIcon: module.selectedIcon,
              label: module.label(l10n),
              glassLabel: switch (module) {
                ClientModule.containers => l10n.serverModuleContainers,
                ClientModule.apps => l10n.serverModuleApps,
                _ => null,
              },
              enabled: !module.requiresServer || currentServer.hasServer,
            ),
        ];

        return _wrapWithChannelWatermark(
          Scaffold(
            key: _mobileScaffoldKey,
            drawerEnableOpenDragGesture: true,
            // 玻璃底栏需要内容从栏下穿透可采样，否则玻璃后面是纯色背景，
            // 视觉上与实色无异（液态玻璃模式的前提条件）。
            extendBody: UIRenderPolicy.liquidGlassEnabled,
            drawer: MobileMoreModulesDrawer(
              modules: moreModules,
              pinnedModules: pinnedModules.pins,
              selectedModule: selectedModule,
              hasServer: currentServer.hasServer,
              onClose: () => Navigator.of(context).maybePop(),
              onManageServers: () {
                Navigator.of(context).maybePop();
                _handleModuleSelection(
                    ClientModule.servers, currentServer.hasServer);
              },
              onModuleTap: (module) {
                Navigator.of(context).maybePop();
                _openStandaloneModule(module, currentServer.hasServer);
              },
            ),
            body: Builder(
              // 悬浮胶囊模式下向 body 注入底栏让位：extendBody 后 body 延伸
              // 到胶囊后方，末项遮挡由页面 ListView 消费 MediaQuery.padding
              // 解决（固定 padding 的列表由下方 removePadding 方案兜底）。
              builder: (context) {
                if (!UIRenderPolicy.liquidGlassEnabled) {
                  return ShellDrawerScope(
                    openDrawer: () =>
                        _mobileScaffoldKey.currentState?.openDrawer(),
                    child: body,
                  );
                }
                // 胶囊占高：NavigationBar 80 + 下留白 10 + 左右留边 0。
                const floatHeight = 90.0;
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: MediaQuery.of(context).padding.copyWith(
                          bottom: MediaQuery.of(context).padding.bottom +
                              floatHeight,
                        ),
                    viewPadding: MediaQuery.of(context).viewPadding.copyWith(
                          bottom: MediaQuery.of(context).viewPadding.bottom +
                              floatHeight,
                        ),
                  ),
                  child: ShellDrawerScope(
                    openDrawer: () =>
                        _mobileScaffoldKey.currentState?.openDrawer(),
                    child: body,
                  ),
                );
              },
            ),
            bottomNavigationBar: AppBottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) => _handleModuleSelection(
                modules[index],
                currentServer.hasServer,
              ),
              items: items,
            ),
          ),
        );
      },
    );
  }

  Widget _wrapWithChannelWatermark(Widget child) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        const ChannelWatermarkBadgeWidget(),
      ],
    );
  }

  void _handleModuleOpen(ClientModule module) {
    if (!mounted) return;
    setState(() {
      _selectedModule = module;
    });
  }

  Future<bool> _ensureModuleUnlocked(ClientModule module) async {
    final appLockController = context.read<AppLockController?>();
    if (appLockController == null) {
      return true;
    }
    if (!appLockController.shouldRequireUnlockForModuleId(module.storageId)) {
      return true;
    }

    final success = await appLockController.authenticateForUnlock(
      reason:
          context.l10n.appLockUnlockReasonModule(module.label(context.l10n)),
    );
    if (!mounted) {
      return false;
    }
    if (!success) {
      SnackBarUtils.showSuccess(context, 
            appLockController.lastError ?? context.l10n.appLockAuthFailed,
          );
    }
    return success;
  }

  Future<void> _handleModuleSelection(
      ClientModule module, bool hasServer) async {
    // If no server is selected and the module needs one, prompt the user
    // to pick a server first rather than showing an empty/broken page.
    if (!hasServer && module.requiresServer) {
      await ServerSwitcherAction.showServerPicker(context);
      return;
    }
    if (!await _ensureModuleUnlocked(module)) {
      return;
    }
    _handleModuleOpen(module);
  }

  Future<void> _openStandaloneModule(
      ClientModule module, bool hasServer) async {
    if (!hasServer && module.requiresServer) {
      await ServerSwitcherAction.showServerPicker(context);
      return;
    }
    if (!await _ensureModuleUnlocked(module)) {
      return;
    }

    if (!mounted) return;

    final Widget? page = ModuleRegistry.buildStandalonePage(module, context);

    if (page == null) {
      _handleModuleOpen(module);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}
