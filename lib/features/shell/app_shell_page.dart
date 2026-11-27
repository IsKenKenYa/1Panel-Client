import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/features/security/app_lock_controller.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/module_page_factory.dart';
import 'package:onepanel_client/features/shell/module_registry.dart';
import 'package:onepanel_client/features/shell/server_route_observer.dart';
import 'package:onepanel_client/features/shell/widgets/adaptive_shell_navigation_widget.dart';
import 'package:onepanel_client/features/shell/widgets/channel_watermark_badge_widget.dart';
import 'package:onepanel_client/features/shell/widgets/mobile_more_modules_drawer.dart';
import 'package:onepanel_client/features/shell/widgets/shell_drawer_scope.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanel_client/widgets/navigation/app_bottom_navigation_bar.dart';
import 'package:onepanel_client/ui/routing/ui_target.dart';
import 'package:onepanel_client/ui/tablet/app/tablet_shell_page.dart';

import '../../core/utils/snackbar_utils.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/theme/ui_render_policy.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    this.initialIndex = 0,
    this.initialModuleId,
    this.tabletKind = TabletKind.none,
    this.selectedModule,
    this.onSelectModule,
    this.body,
  }) : assert((selectedModule == null) == (onSelectModule == null));

  final int initialIndex;
  final String? initialModuleId;
  final TabletKind tabletKind;
  final ClientModule? selectedModule;
  final ValueChanged<ClientModule>? onSelectModule;
  final Widget? body;

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
    _selectedModule =
        initialShellModule(widget.initialIndex, widget.initialModuleId);
  }

  @override
  Widget build(BuildContext context) {
    // 渲染模式切换后需要立刻换掉铬件，因此在这里订阅设置。
    // 控制器尚未载入时退回策略值，保持与启动期一致。
    final settings = context.watch<AppSettingsController?>();
    final glass = settings == null || !settings.loaded
        ? UIRenderPolicy.liquidGlassEnabled
        : UIRenderPolicy.glassEnabledFor(settings.uiRenderMode);
    return Consumer2<CurrentServerController, PinnedModulesController>(
      builder: (context, currentServer, pinnedModules, _) {
        final spec = AdaptiveLayoutSpec.of(context);
        final isCompact = spec.isPhone;
        final panelType = currentServer.currentServer?.panelType;
        final selectedModule = (widget.selectedModule ?? _selectedModule)
            .forServer(currentServer.currentServer);
        if (widget.body == null) {
          ServerRouteObserver.setActiveModule(context,
              module: selectedModule,
              needsServer: selectedModule.requiresServer);
        }
        final modules = shellModulesForPanel(
          panelType,
          pinnedModules.pins,
          compact: isCompact,
          activeModule: selectedModule,
        );
        final moreModules = isCompact
            ? kPinnableClientModules
                .where((module) =>
                    module.supportsPanel(panelType) && !modules.contains(module))
                .toList(growable: false)
            : const <ClientModule>[];
        final selectedIndex = modules.contains(selectedModule)
            ? modules.indexOf(selectedModule)
            : 0;

        final body = widget.body ??
            buildShellModulePage(
              context,
              module: selectedModule,
              serverId: currentServer.currentServerId,
              serverRevision: currentServer.currentServer?.revision,
            );

        if (!isCompact && widget.tabletKind != TabletKind.none) {
          return TabletShellPage(
            tabletKind: widget.tabletKind,
            modules: modules,
            selectedIndex: selectedIndex,
            hasServer: currentServer.hasServer,
            onSelect: _handleModuleSelection,
            body: body,
          );
        }
        if (spec.width >= PlatformUtils.tabletWidthBreakpoint) {
          return _wrapWithChannelWatermark(
            Scaffold(
              body: Row(
                children: [
                  ShellSidebarNavigation(
                    modules: modules,
                    selectedModule: selectedModule,
                    hasServer: currentServer.hasServer,
                    onSelect: _handleModuleSelection,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: AdaptiveLayoutViewport(child: body)),
                ],
              ),
            ),
          );
        }

        if (!isCompact) {
          return _wrapWithChannelWatermark(
            Scaffold(
              body: Row(
                children: [
                  ShellRailNavigation(
                    modules: modules,
                    selectedModule: selectedModule,
                    hasServer: currentServer.hasServer,
                    onSelect: _handleModuleSelection,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: AdaptiveLayoutViewport(child: body)),
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
            extendBody: glass,
            drawer: moreModules.isEmpty ? null : MobileMoreModulesDrawer(
              modules: moreModules,
              pinnedModules: pinnedModules.pins,
              selectedModule: selectedModule,
              hasServer: currentServer.hasServer,
              onClose: () => Navigator.of(context).maybePop(),
              onManageServers: () {
                Navigator.of(context).maybePop();
                _handleModuleSelection(ClientModule.servers);
              },
              onModuleTap: (module) {
                Navigator.of(context).maybePop();
                ServerSwitcherAction.openModule(
                  context, module, _openStandaloneModule,
                );
              },
            ),
            body: Builder(
              builder: (_) {
                final chrome = AppBottomNavigationBar.glassBarExtentOf(
                  context,
                  glass: glass,
                );
                final media = MediaQuery.of(context);
                final content = SafeArea(
                  top: false,
                  bottom: false,
                  child: moreModules.isEmpty
                      ? body
                      : ShellDrawerScope(
                          openDrawer: () =>
                              _mobileScaffoldKey.currentState?.openDrawer(),
                          child: body,
                        ),
                );
                if (chrome <= 0) {
                  return content;
                }
                // extendBody 让内容延伸到玻璃栏下方。Flutter 的 Scaffold 用
                // minInsets（padding）与 minViewPadding（viewPadding）定位
                // FAB。栏高本身已包含系统安全区，两者都直接取栏高：
                // FabFloatOffsetY 的 safeMargin 是
                // minViewPadding.bottom - 栏高 + 16，取同一值才得到 16dp 间距；
                // 若在 viewPadding 上再叠安全区，FAB 会多抬一个安全区的高度。
                return MediaQuery(
                  data: media.copyWith(
                    padding: media.padding.copyWith(bottom: chrome),
                    viewPadding: media.viewPadding.copyWith(bottom: chrome),
                  ),
                  child: content,
                );
              },
            ),
            bottomNavigationBar: AppBottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) => _handleModuleSelection(modules[index]),
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
    final onSelect = widget.onSelectModule;
    if (onSelect != null) {
      onSelect(module);
      return;
    }
    setState(() {
      _selectedModule = module;
    });
  }

  Future<bool> _ensureModuleUnlocked(ClientModule module) async {
    final appLockController = context.read<AppLockController?>();
    if (appLockController == null) {
      return true;
    }
    if (!appLockController.isLoaded) {
      await appLockController.load();
      if (!mounted) return false;
      if (!appLockController.isLoaded) {
        SnackBarUtils.showError(context, appLockController.lastError ?? context.l10n.appLockAuthFailed);
        return false;
      }
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
      SnackBarUtils.showError(context,
            appLockController.lastError ?? context.l10n.appLockAuthFailed,
          );
    }
    return success;
  }

  Future<void> _handleModuleSelection(ClientModule module) {
    return ServerSwitcherAction.openModule(context, module, (module) async {
      if (await _ensureModuleUnlocked(module)) _handleModuleOpen(module);
    });
  }

  Future<void> _openStandaloneModule(ClientModule module) async {
    if (!await _ensureModuleUnlocked(module)) {
      return;
    }

    if (!mounted) return;

    final route = ModuleRegistry.registrationFor(module)?.standaloneRoute;
    if (route == null) {
      _handleModuleOpen(module);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: route),
        builder: (routeContext) {
          final server =
              routeContext.watch<CurrentServerController>().currentServer;
          if (!module.supportsPanel(server?.panelType)) {
            return buildShellModulePage(routeContext,
                module: ClientModule.servers, serverId: server?.id);
          }
          return ModuleRegistry.buildStandalonePage(module, routeContext)!;
        },
      ),
    );
  }
}
