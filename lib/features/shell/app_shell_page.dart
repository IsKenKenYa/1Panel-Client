import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/apps/apps_page.dart';
import 'package:onepanel_client/features/containers/containers_page.dart';
import 'package:onepanel_client/features/files/files_page.dart';
import 'package:onepanel_client/features/security/security_verification_page.dart';
import 'package:onepanel_client/features/server/server_list_page.dart';
import 'package:onepanel_client/features/websites/websites_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/widgets/adaptive_shell_navigation_widget.dart';
import 'package:onepanel_client/features/shell/widgets/mobile_more_modules_drawer.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanel_client/features/shell/widgets/shell_drawer_scope.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanel_client/pages/settings/settings_page.dart';
import 'package:onepanel_client/widgets/navigation/app_bottom_navigation_bar.dart';

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
            _buildCurrentPage(selectedModule, currentServer.currentServerId);

        if (width >= 1024) {
          return Scaffold(
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
          );
        }

        if (width >= 600) {
          return Scaffold(
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
          );
        }

        final items = [
          for (final module in modules)
            AppNavigationBarItem(
              icon: module.icon,
              selectedIcon: module.selectedIcon,
              label: module.label(context.l10n),
              enabled: !module.requiresServer || currentServer.hasServer,
            ),
        ];

        return Scaffold(
          key: _mobileScaffoldKey,
          drawerEnableOpenDragGesture: true,
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
          body: ShellDrawerScope(
            openDrawer: () => _mobileScaffoldKey.currentState?.openDrawer(),
            child: body,
          ),
          bottomNavigationBar: AppBottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) =>
                _handleModuleSelection(modules[index], currentServer.hasServer),
            items: items,
          ),
        );
      },
    );
  }

  Widget _buildCurrentPage(ClientModule module, String? serverId) {
    switch (module) {
      case ClientModule.servers:
        return const ServerListPage();
      case ClientModule.files:
        if (serverId == null) {
          return NoServerSelectedState(moduleName: context.l10n.navFiles);
        }
        return KeyedSubtree(
          key: ValueKey('files:$serverId'),
          child: const FilesPage(),
        );
      case ClientModule.containers:
        if (serverId == null) {
          return NoServerSelectedState(
              moduleName: context.l10n.containerManagement);
        }
        return KeyedSubtree(
          key: ValueKey('containers:$serverId'),
          child: const ContainersPage(),
        );
      case ClientModule.apps:
        if (serverId == null) {
          return NoServerSelectedState(moduleName: context.l10n.appsPageTitle);
        }
        return KeyedSubtree(
          key: ValueKey('apps:$serverId'),
          child: const AppsPage(),
        );
      case ClientModule.websites:
        if (serverId == null) {
          return NoServerSelectedState(
              moduleName: context.l10n.websitesPageTitle);
        }
        return KeyedSubtree(
          key: ValueKey('websites:$serverId'),
          child: const WebsitesPage(),
        );
      case ClientModule.verification:
        if (serverId == null) {
          return NoServerSelectedState(
              moduleName: context.l10n.serverActionSecurity);
        }
        return KeyedSubtree(
          key: ValueKey('verification:$serverId'),
          child: const SecurityVerificationPage(),
        );
      case ClientModule.settings:
        return const SettingsPage();
    }
  }

  void _handleModuleOpen(ClientModule module) {
    if (!mounted) return;
    setState(() {
      _selectedModule = module;
    });
  }

  Future<void> _handleModuleSelection(
      ClientModule module, bool hasServer) async {
    if (!hasServer && module.requiresServer) {
      await ServerSwitcherAction.showServerPicker(context);
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

    if (!mounted) return;

    final Widget? page = switch (module) {
      ClientModule.apps => const AppsPage(),
      ClientModule.websites => const WebsitesPage(),
      ClientModule.verification => const SecurityVerificationPage(),
      _ => null,
    };

    if (page == null) {
      _handleModuleOpen(module);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}
