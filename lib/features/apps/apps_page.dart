import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/apps/app_service.dart';
import 'package:onepanelapp_app/features/apps/providers/app_store_provider.dart';
import 'package:onepanelapp_app/features/apps/providers/installed_apps_provider.dart';
import 'package:onepanelapp_app/features/shell/controllers/module_subnav_controller.dart';
import 'package:onepanelapp_app/features/shell/controllers/current_server_controller.dart';
import 'package:onepanelapp_app/features/shell/widgets/module_subnav.dart';
import 'package:onepanelapp_app/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanelapp_app/features/shell/widgets/server_aware_page_scaffold.dart';
import 'widgets/app_store_view.dart';
import 'widgets/installed_apps_view.dart';

class AppsPage extends StatelessWidget {
  final int initialTabIndex;

  const AppsPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              InstalledAppsProvider(appService: context.read<AppService>()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AppStoreProvider(appService: context.read<AppService>()),
        ),
      ],
      child: _AppsPageView(initialTabIndex: initialTabIndex),
    );
  }
}

class _AppsPageView extends StatefulWidget {
  const _AppsPageView({required this.initialTabIndex});

  final int initialTabIndex;

  @override
  State<_AppsPageView> createState() => _AppsPageViewState();
}

class _AppsPageViewState extends State<_AppsPageView> {
  late final ModuleSubnavController _subnavController;
  late String _selectedSection;
  String? _activeServerId;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialTabIndex == 0 ? 'installed' : 'store';
    _subnavController = ModuleSubnavController(
      storageKey: 'apps_module_subnav',
      defaultOrder: const ['installed', 'store'],
      maxVisibleItems: 2,
    )..load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final serverId =
        Provider.of<CurrentServerController>(context).currentServerId;
    if (_activeServerId == null) {
      _activeServerId = serverId;
      return;
    }
    if (serverId == null || serverId == _activeServerId) {
      return;
    }
    _activeServerId = serverId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final installedProvider = context.read<InstalledAppsProvider>();
      final storeProvider = context.read<AppStoreProvider>();
      await Future.wait([
        installedProvider.onServerChanged(),
        storeProvider.onServerChanged(),
      ]);
    });
  }

  @override
  void dispose() {
    _subnavController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<CurrentServerController>(
      builder: (context, currentServer, _) {
        return ServerAwarePageScaffold(
          title: l10n.appsPageTitle,
          body: currentServer.hasServer
              ? AnimatedBuilder(
                  animation: _subnavController,
                  builder: (context, _) {
                    final subnavItems = [
                      ModuleSubnavItem(
                        id: 'installed',
                        label: l10n.appStoreInstalled,
                        icon: Icons.download_done_outlined,
                      ),
                      ModuleSubnavItem(
                        id: 'store',
                        label: l10n.appStoreTitle,
                        icon: Icons.storefront_outlined,
                      ),
                    ];

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: ModuleSubnav(
                            controller: _subnavController,
                            items: subnavItems,
                            selectedId: _selectedSection,
                            onSelected: (value) {
                              setState(() {
                                _selectedSection = value;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: KeyedSubtree(
                            key: ValueKey(_selectedSection),
                            child: _selectedSection == 'installed'
                                ? const InstalledAppsView()
                                : const AppStoreView(),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : NoServerSelectedState(moduleName: l10n.appsPageTitle),
        );
      },
    );
  }
}
