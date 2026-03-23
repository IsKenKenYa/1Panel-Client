import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/shell/controllers/module_subnav_controller.dart';
import 'package:onepanelapp_app/features/shell/controllers/current_server_controller.dart';
import 'package:onepanelapp_app/features/shell/widgets/module_subnav.dart';
import 'package:onepanelapp_app/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanelapp_app/features/shell/widgets/server_switcher_action.dart';
import 'widgets/app_store_view.dart';
import 'widgets/installed_apps_view.dart';

class AppsPage extends StatefulWidget {
  final int initialTabIndex;

  const AppsPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  late final ModuleSubnavController _subnavController;
  late String _selectedSection;

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
  void dispose() {
    _subnavController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<CurrentServerController>(
      builder: (context, currentServer, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.appsPageTitle),
            actions: const [ServerSwitcherAction()],
          ),
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
