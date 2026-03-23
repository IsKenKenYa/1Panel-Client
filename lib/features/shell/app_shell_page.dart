import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/apps/apps_page.dart';
import 'package:onepanelapp_app/features/files/files_page.dart';
import 'package:onepanelapp_app/features/server/server_list_page.dart';
import 'package:onepanelapp_app/features/shell/controllers/current_server_controller.dart';
import 'package:onepanelapp_app/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanelapp_app/features/shell/controllers/recent_modules_controller.dart';
import 'package:onepanelapp_app/features/shell/models/client_module.dart';
import 'package:onepanelapp_app/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanelapp_app/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanelapp_app/features/workbench/workbench_page.dart';
import 'package:onepanelapp_app/features/containers/containers_page.dart';
import 'package:onepanelapp_app/features/security/security_verification_page.dart';
import 'package:onepanelapp_app/pages/settings/settings_page.dart';
import 'package:onepanelapp_app/widgets/navigation/app_bottom_navigation_bar.dart';

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
  late ClientModule _selectedModule;

  @override
  void initState() {
    super.initState();
    _selectedModule = clientModuleFromId(widget.initialModuleId) ?? _moduleFromIndex(widget.initialIndex);
  }

  ClientModule _moduleFromIndex(int index) {
    switch (index.clamp(0, 4)) {
      case 0:
        return ClientModule.servers;
      case 1:
        return ClientModule.workbench;
      case 2:
        return ClientModule.files;
      case 3:
        return ClientModule.containers;
      case 4:
        return ClientModule.settings;
      default:
        return ClientModule.servers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CurrentServerController, PinnedModulesController>(
      builder: (context, currentServer, pinnedModules, _) {
        final slots = <ClientModule>[
          ClientModule.servers,
          ClientModule.workbench,
          pinnedModules.primaryPin,
          pinnedModules.secondaryPin,
          ClientModule.settings,
        ];
        if (_selectedModule.pinnable && !slots.contains(_selectedModule)) {
          slots[2] = _selectedModule;
        }
        final activeModule = slots.contains(_selectedModule)
            ? _selectedModule
            : ClientModule.workbench;
        final selectedModule = (!currentServer.hasServer && activeModule.requiresServer)
            ? ClientModule.servers
            : activeModule;
        final selectedIndex = slots.indexOf(selectedModule).clamp(0, slots.length - 1);

        final pages = [
          const ServerListPage(),
          KeyedSubtree(
            key: ValueKey('workbench:${currentServer.currentServerId ?? 'none'}'),
            child: WorkbenchPage(onOpenModule: _handleModuleOpen),
          ),
          _buildSlotPage(slots[2], currentServer.currentServerId),
          _buildSlotPage(slots[3], currentServer.currentServerId),
          const SettingsPage(),
        ];

        final items = [
          for (final module in slots)
            AppNavigationBarItem(
              icon: module.icon,
              selectedIcon: module.selectedIcon,
              label: module.label(context.l10n),
              enabled: !module.requiresServer || currentServer.hasServer,
            ),
        ];

        final content = IndexedStack(
          index: selectedIndex,
          children: pages,
        );

        final width = MediaQuery.sizeOf(context).width;
        if (width >= 1024) {
          return Scaffold(
            body: Row(
              children: [
                _SidebarNavigation(
                  modules: slots,
                  selectedModule: selectedModule,
                  hasServer: currentServer.hasServer,
                  onSelect: _handleModuleOpen,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        if (width >= 600) {
          return Scaffold(
            body: Row(
              children: [
                _RailNavigation(
                  modules: slots,
                  selectedModule: selectedModule,
                  hasServer: currentServer.hasServer,
                  onSelect: _handleModuleOpen,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: AppBottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) => _handleModuleOpen(slots[index]),
            items: items,
          ),
        );
      },
    );
  }

  Widget _buildSlotPage(ClientModule module, String? serverId) {
    switch (module) {
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
          return NoServerSelectedState(moduleName: context.l10n.containerManagement);
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
      case ClientModule.workbench:
        return KeyedSubtree(
          key: ValueKey('workbench:${serverId ?? 'none'}'),
          child: WorkbenchPage(onOpenModule: _handleModuleOpen),
        );
      case ClientModule.servers:
        return const ServerListPage();
      case ClientModule.settings:
        return const SettingsPage();
      case ClientModule.verification:
        return const SecurityVerificationPage();
    }
  }

  Future<void> _handleModuleOpen(ClientModule module) async {
    final currentServer = context.read<CurrentServerController>();
    final recentModules = context.read<RecentModulesController>();
    final navigator = Navigator.of(context);

    if (module == ClientModule.verification) {
      if (!mounted) return;
      await recentModules.track(module);
      await navigator.push(
        MaterialPageRoute(builder: (_) => const SecurityVerificationPage()),
      );
      return;
    }

    if (module.requiresServer && !currentServer.hasServer) {
      await ServerSwitcherAction.showServerPicker(context);
      return;
    }

    if (!mounted) return;
    setState(() {
      _selectedModule = module;
    });
    await recentModules.track(module);
  }
}

class _RailNavigation extends StatelessWidget {
  const _RailNavigation({
    required this.modules,
    required this.selectedModule,
    required this.hasServer,
    required this.onSelect,
  });

  final List<ClientModule> modules;
  final ClientModule selectedModule;
  final bool hasServer;
  final ValueChanged<ClientModule> onSelect;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = modules.indexOf(selectedModule).clamp(0, modules.length - 1);
    final disabledColor = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.42);

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => onSelect(modules[index]),
      labelType: NavigationRailLabelType.all,
      destinations: [
        for (final module in modules)
          NavigationRailDestination(
            icon: Icon(
              module.icon,
              color: !module.requiresServer || hasServer ? null : disabledColor,
            ),
            selectedIcon: Icon(
              module.selectedIcon,
              color: !module.requiresServer || hasServer ? null : disabledColor,
            ),
            label: Text(module.label(context.l10n)),
          ),
      ],
    );
  }
}

class _SidebarNavigation extends StatelessWidget {
  const _SidebarNavigation({
    required this.modules,
    required this.selectedModule,
    required this.hasServer,
    required this.onSelect,
  });

  final List<ClientModule> modules;
  final ClientModule selectedModule;
  final bool hasServer;
  final ValueChanged<ClientModule> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 264,
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.appName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          for (final module in modules)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: Icon(module.icon),
                title: Text(module.label(context.l10n)),
                selected: module == selectedModule,
                enabled: !module.requiresServer || hasServer,
                onTap: () => onSelect(module),
              ),
            ),
        ],
      ),
    );
  }
}
