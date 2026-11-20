import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanel_client/features/shell/module_page_factory.dart';
import 'package:onepanel_client/ui/routing/ui_target.dart';

class TabletShellPage extends StatefulWidget {
  const TabletShellPage({
    super.key,
    this.initialIndex = 0,
    this.initialModuleId,
    required this.tabletKind,
  });

  final int initialIndex;
  final String? initialModuleId;
  final TabletKind tabletKind;

  @override
  State<TabletShellPage> createState() => _TabletShellPageState();
}

class _TabletShellPageState extends State<TabletShellPage> {
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

  List<ClientModule> _tabletSlots(PinnedModulesController pinnedModules) {
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
        final spec = AdaptiveLayoutSpec.of(context);
        final railTheme = Theme.of(context);
        final modules = _tabletSlots(pinnedModules);
        final selectedModule =
            (!currentServer.hasServer && _selectedModule.requiresServer)
                ? ClientModule.servers
                : _selectedModule;

        final selectedIndex = modules.contains(selectedModule)
            ? modules.indexOf(selectedModule)
            : 0;

        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                right: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    widget.tabletKind == TabletKind.ipad ? 20 : 16,
                    8,
                    16,
                  ),
                  // 可固定模块增加后导航项数量会超出竖屏高度。NavigationRail
                  // 内部依赖有界高度与 Expanded 布局，放进滚动视图会与无界
                  // 高度冲突，因此超阈值时只显示图标，收起文字标签。
                  child: NavigationRail(
                    extended: false,
                    minWidth: widget.tabletKind == TabletKind.ipad ? 88 : 96,
                    minExtendedWidth:
                        widget.tabletKind == TabletKind.ipad ? 220 : 236,
                    groupAlignment: -0.92,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) {
                      final module = modules[index];
                      if (!currentServer.hasServer && module.requiresServer) {
                        ServerSwitcherAction.showServerPicker(context);
                        return;
                      }
                      setState(() {
                        _selectedModule = module;
                      });
                    },
                    labelType: modules.length > 8
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    useIndicator: true,
                    indicatorColor: railTheme.colorScheme.primaryContainer,
                    destinations: [
                      for (final module in modules)
                        NavigationRailDestination(
                          icon: Icon(
                            module.icon,
                            color: !module.requiresServer ||
                                    currentServer.hasServer
                                ? null
                                : railTheme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.42),
                          ),
                          selectedIcon: Icon(
                            module.selectedIcon,
                            color: !module.requiresServer ||
                                    currentServer.hasServer
                                ? null
                                : railTheme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.42),
                          ),
                          label: Text(module.label(context.l10n)),
                        ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                // The outer Scaffold strips the top MediaQuery padding from
                // its body; re-apply it so nested module Scaffolds (AppBar)
                // do not overlap the system status bar.
                child: SafeArea(
                  bottom: false,
                  child: AdaptiveWidthContainer(
                    maxWidth: spec.contentMaxWidth,
                    child: buildShellModulePage(
                      context,
                      module: selectedModule,
                      serverId: currentServer.currentServerId,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
