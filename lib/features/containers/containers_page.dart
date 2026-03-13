import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/containers/containers_page_container_edit_dialogs.dart';
import 'package:onepanelapp_app/features/containers/containers_page_container_image_dialogs.dart';
import 'package:onepanelapp_app/features/containers/containers_page_container_maintenance_dialogs.dart';
import 'package:onepanelapp_app/features/containers/containers_page_create_dialogs.dart';
import 'package:onepanelapp_app/features/containers/containers_page_image_dialogs.dart';
import 'package:onepanelapp_app/features/containers/containers_provider.dart';
import 'package:onepanelapp_app/features/containers/tabs/config_tab.dart';
import 'package:onepanelapp_app/features/containers/tabs/containers_tab.dart';
import 'package:onepanelapp_app/features/containers/tabs/overview_tab.dart';
import 'package:onepanelapp_app/features/containers/tabs/repos_tab.dart';
import 'package:onepanelapp_app/features/containers/tabs/templates_tab.dart';
import 'package:onepanelapp_app/features/containers/widgets/containers_error_widget.dart';
import 'package:onepanelapp_app/features/containers/widgets/containers_loading_widget.dart';
import 'package:onepanelapp_app/features/orchestration/compose_page.dart';
import 'package:onepanelapp_app/features/orchestration/image_page.dart';
import 'package:onepanelapp_app/features/orchestration/network_page.dart';
import 'package:onepanelapp_app/features/orchestration/volume_page.dart';
import 'package:onepanelapp_app/widgets/main_layout.dart';

class ContainersPage extends StatefulWidget {
  const ContainersPage({super.key});

  @override
  State<ContainersPage> createState() => _ContainersPageState();
}

class _ContainersPageState extends State<ContainersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContainersProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return MainLayout(
      currentIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.containerManagement),
          actions: _buildAppBarActions(context, l10n),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(text: l10n.containerTabOverview),
              Tab(text: l10n.containerTabContainers),
              Tab(text: l10n.containerTabOrchestration),
              Tab(text: l10n.containerTabImages),
              Tab(text: l10n.containerTabNetworks),
              Tab(text: l10n.containerTabVolumes),
              Tab(text: l10n.containerTabRepositories),
              Tab(text: l10n.containerTabTemplates),
              Tab(text: l10n.containerTabConfig),
            ],
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const OverviewTab(),
            Consumer<ContainersProvider>(
              builder: (context, provider, child) {
                final data = provider.data;
                if (data.error != null) {
                  return ContainersErrorView(
                    error: data.error!,
                    onRetry: () => provider.loadAll(),
                  );
                }
                if (data.isLoading && data.containers.isEmpty) {
                  return const ContainersLoadingView();
                }
                return ContainersTab(
                  containers: data.containers,
                  stats: data.containerStats,
                  isLoading: data.isLoading,
                  onRefresh: () => provider.refresh(),
                  onStart: (id) => provider.startContainer(id),
                  onStop: (id) => provider.stopContainer(id),
                  onRestart: (id) => provider.restartContainer(id),
                  onDelete: (id) =>
                      ContainersPageContainerMaintenanceDialogs
                          .showDeleteContainerDialog(
                    context,
                    id,
                  ),
                  onRename: (name) =>
                      ContainersPageContainerEditDialogs
                          .showRenameContainerDialog(
                    context,
                    name,
                  ),
                  onUpgrade: (container) =>
                      ContainersPageContainerImageDialogs
                          .showUpgradeContainerDialog(
                    context,
                    container,
                  ),
                  onCommit: (container) =>
                      ContainersPageContainerImageDialogs
                          .showCommitContainerDialog(
                    context,
                    container,
                  ),
                  onEdit: (container) =>
                      ContainersPageContainerEditDialogs.showEditContainerDialog(
                    context,
                    container,
                  ),
                  onCleanLog: (name) =>
                      ContainersPageContainerEditDialogs.showCleanLogDialog(
                    context,
                    name,
                  ),
                );
              },
            ),
            const ComposePage(),
            const ImagePage(),
            const NetworkPage(),
            const VolumePage(),
            const ReposTab(),
            const TemplatesTab(),
            const ConfigTab(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(context, l10n),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, dynamic l10n) {
    final actions = <Widget>[];
    if (_tabController.index == 1) {
      actions.addAll([
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
          tooltip: l10n.containerSearch,
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {},
          tooltip: l10n.containerFilter,
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: () =>
              ContainersPageContainerMaintenanceDialogs.showPruneDialog(context),
          tooltip: l10n.containerActionPrune,
        ),
      ]);
    }

    if (_tabController.index == 3) {
      actions.addAll([
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () =>
              ContainersPageImageDialogs.showSearchImageDialog(context),
          tooltip: l10n.orchestrationImageSearch,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: l10n.commonMore,
          onSelected: (value) {
            if (value == 'build') {
              ContainersPageImageDialogs.showBuildImageDialog(context);
            }
            if (value == 'load') {
              ContainersPageImageDialogs.showLoadImageDialog(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'build',
              child: Text(l10n.orchestrationImageBuild),
            ),
            PopupMenuItem(
              value: 'load',
              child: Text(l10n.orchestrationImageLoad),
            ),
          ],
        ),
      ]);
    }
    return actions;
  }

  Widget? _buildFloatingActionButton(BuildContext context, dynamic l10n) {
    switch (_tabController.index) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/container-create');
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.containerCreate),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateComposeDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateProject),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: () => ContainersPageImageDialogs.showPullDialog(context),
          icon: const Icon(Icons.download),
          label: Text(l10n.orchestrationPullImage),
        );
      case 4:
        return FloatingActionButton.extended(
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateNetworkDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateNetwork),
        );
      case 5:
        return FloatingActionButton.extended(
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateVolumeDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateVolume),
        );
      case 6:
        return FloatingActionButton.extended(
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateRepoDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateRepo),
        );
      case 7:
        return FloatingActionButton.extended(
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateTemplateDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateTemplate),
        );
      default:
        return null;
    }
  }
}
