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
import 'package:onepanelapp_app/features/containers/tabs/repos_tab.dart';
import 'package:onepanelapp_app/features/containers/tabs/templates_tab.dart';
import 'package:onepanelapp_app/features/containers/widgets/containers_error_widget.dart';
import 'package:onepanelapp_app/features/containers/widgets/containers_loading_widget.dart';
import 'package:onepanelapp_app/features/orchestration/compose_page.dart';
import 'package:onepanelapp_app/features/orchestration/image_page.dart';
import 'package:onepanelapp_app/features/orchestration/network_page.dart';
import 'package:onepanelapp_app/features/orchestration/volume_page.dart';
import 'package:onepanelapp_app/features/shell/controllers/current_server_controller.dart';
import 'package:onepanelapp_app/features/shell/controllers/module_subnav_controller.dart';
import 'package:onepanelapp_app/features/shell/widgets/module_subnav.dart';
import 'package:onepanelapp_app/features/shell/widgets/server_aware_page_scaffold.dart';

class ContainersPage extends StatefulWidget {
  const ContainersPage({super.key});

  @override
  State<ContainersPage> createState() => _ContainersPageState();
}

class _ContainersPageState extends State<ContainersPage> {
  static const _defaultSectionOrder = [
    'containers',
    'images',
    'networks',
    'volumes',
    'compose',
    'repositories',
    'templates',
    'config',
  ];

  late final ModuleSubnavController _subnavController;
  String _selectedSection = 'containers';
  String? _lastServerId;

  @override
  void initState() {
    super.initState();
    _subnavController = ModuleSubnavController(
      storageKey: 'container_module_subnav',
      defaultOrder: _defaultSectionOrder,
    )..load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ContainersProvider>().loadAll();
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
    final currentServerId = context.select<CurrentServerController, String?>(
      (controller) => controller.currentServerId,
    );
    if (currentServerId != _lastServerId) {
      _lastServerId = currentServerId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && currentServerId != null) {
          context.read<ContainersProvider>().loadAll();
        }
      });
    }

    return AnimatedBuilder(
      animation: _subnavController,
      builder: (context, _) {
        final subnavItems = _buildSubnavItems(l10n);
        if (!subnavItems.any((item) => item.id == _selectedSection)) {
          _selectedSection = 'containers';
        }

        return ServerAwarePageScaffold(
          title: l10n.containerManagement,
          onServerChanged: () => context.read<ContainersProvider>().loadAll(),
          actions: _buildAppBarActions(context, l10n),
          floatingActionButton: _buildFloatingActionButton(context, l10n),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ContainerInlineSummaryCard(),
                    const SizedBox(height: 12),
                    ModuleSubnav(
                      controller: _subnavController,
                      items: subnavItems,
                      selectedId: _selectedSection,
                      onSelected: (value) {
                        setState(() {
                          _selectedSection = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildSectionContent(context)),
            ],
          ),
        );
      },
    );
  }

  List<ModuleSubnavItem> _buildSubnavItems(dynamic l10n) {
    return [
      ModuleSubnavItem(
        id: 'containers',
        label: l10n.containerTabContainers,
        icon: Icons.inventory_2_outlined,
      ),
      ModuleSubnavItem(
        id: 'images',
        label: l10n.containerTabImages,
        icon: Icons.image_outlined,
      ),
      ModuleSubnavItem(
        id: 'networks',
        label: l10n.containerTabNetworks,
        icon: Icons.hub_outlined,
      ),
      ModuleSubnavItem(
        id: 'volumes',
        label: l10n.containerTabVolumes,
        icon: Icons.storage_outlined,
      ),
      ModuleSubnavItem(
        id: 'compose',
        label: l10n.containerTabOrchestration,
        icon: Icons.dashboard_customize_outlined,
      ),
      ModuleSubnavItem(
        id: 'repositories',
        label: l10n.containerTabRepositories,
        icon: Icons.store_outlined,
      ),
      ModuleSubnavItem(
        id: 'templates',
        label: l10n.containerTabTemplates,
        icon: Icons.description_outlined,
      ),
      ModuleSubnavItem(
        id: 'config',
        label: l10n.containerTabConfig,
        icon: Icons.tune_outlined,
      ),
    ];
  }

  Widget _buildSectionContent(BuildContext context) {
    switch (_selectedSection) {
      case 'containers':
        return Consumer<ContainersProvider>(
          builder: (context, provider, child) {
            final data = provider.data;
            if (provider.containersState.error != null && data.containers.isEmpty) {
              return ContainersErrorView(
                error: provider.containersState.error!,
                onRetry: provider.loadContainers,
              );
            }
            if (provider.containersState.isLoading && data.containers.isEmpty) {
              return const ContainersLoadingView();
            }
            return ContainersTab(
              containers: data.containers,
              stats: data.containerStats,
              isLoading: provider.containersState.isLoading,
              showStatsHeader: false,
              onRefresh: provider.refresh,
              onStart: provider.startContainer,
              onStop: provider.stopContainer,
              onRestart: provider.restartContainer,
              onDelete: (id) => ContainersPageContainerMaintenanceDialogs
                  .showDeleteContainerDialog(context, id),
              onRename: (name) => ContainersPageContainerEditDialogs
                  .showRenameContainerDialog(context, name),
              onUpgrade: (container) => ContainersPageContainerImageDialogs
                  .showUpgradeContainerDialog(context, container),
              onCommit: (container) => ContainersPageContainerImageDialogs
                  .showCommitContainerDialog(context, container),
              onEdit: (container) => ContainersPageContainerEditDialogs
                  .showEditContainerDialog(context, container),
              onCleanLog: (name) => ContainersPageContainerEditDialogs
                  .showCleanLogDialog(context, name),
            );
          },
        );
      case 'compose':
        return const ComposePage();
      case 'images':
        return const ImagePage();
      case 'networks':
        return const NetworkPage();
      case 'volumes':
        return const VolumePage();
      case 'repositories':
        return const ReposTab();
      case 'templates':
        return const TemplatesTab();
      case 'config':
        return const ConfigTab();
      default:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _buildAppBarActions(BuildContext context, dynamic l10n) {
    switch (_selectedSection) {
      case 'containers':
        return [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () =>
                ContainersPageContainerMaintenanceDialogs.showPruneDialog(context),
            tooltip: l10n.containerActionPrune,
          ),
        ];
      case 'images':
        return [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => ContainersPageImageDialogs.showSearchImageDialog(context),
            tooltip: l10n.orchestrationImageSearch,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.commonMore,
            onSelected: (value) {
              if (value == 'build') {
                ContainersPageImageDialogs.showBuildImageDialog(context);
              } else if (value == 'load') {
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
        ];
      default:
        return const [];
    }
  }

  Widget? _buildFloatingActionButton(BuildContext context, dynamic l10n) {
    switch (_selectedSection) {
      case 'containers':
        return FloatingActionButton.extended(
          onPressed: () async {
            final created = await Navigator.pushNamed(context, '/container-create');
            if (created == true && context.mounted) {
              await context.read<ContainersProvider>().loadContainers();
            }
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.containerCreate),
        );
      case 'compose':
        return FloatingActionButton.extended(
          onPressed: () => ContainersPageCreateDialogs.showCreateComposeDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateProject),
        );
      case 'images':
        return FloatingActionButton.extended(
          onPressed: () => ContainersPageImageDialogs.showPullDialog(context),
          icon: const Icon(Icons.download),
          label: Text(l10n.orchestrationPullImage),
        );
      case 'networks':
        return FloatingActionButton.extended(
          onPressed: () => ContainersPageCreateDialogs.showCreateNetworkDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateNetwork),
        );
      case 'volumes':
        return FloatingActionButton.extended(
          onPressed: () => ContainersPageCreateDialogs.showCreateVolumeDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateVolume),
        );
      case 'repositories':
        return FloatingActionButton.extended(
          onPressed: () => ContainersPageCreateDialogs.showCreateRepoDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateRepo),
        );
      case 'templates':
        return FloatingActionButton.extended(
          onPressed: () => ContainersPageCreateDialogs.showCreateTemplateDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateTemplate),
        );
      default:
        return null;
    }
  }
}

class _ContainerInlineSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<ContainersProvider>(
      builder: (context, provider, _) {
        final stats = provider.data.containerStats;
        final status = provider.data.status;
        final scheme = Theme.of(context).colorScheme;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.containerStatsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _SummaryMetric(icon: Icons.inventory_2_outlined, label: l10n.containerStatsTotal, value: stats.total.toString(), color: scheme.primary)),
                    Expanded(child: _SummaryMetric(icon: Icons.play_circle_outline, label: l10n.containerStatsRunning, value: stats.running.toString(), color: scheme.tertiary)),
                    Expanded(child: _SummaryMetric(icon: Icons.stop_circle_outlined, label: l10n.containerStatsStopped, value: stats.stopped.toString(), color: scheme.secondary)),
                  ],
                ),
                if (status != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(label: '${l10n.containerStatsImages}: ${status.imageCount}'),
                      _StatusChip(label: '${l10n.containerStatsNetworks}: ${status.networkCount}'),
                      _StatusChip(label: '${l10n.containerStatsVolumes}: ${status.volumeCount}'),
                      _StatusChip(label: '${l10n.containerStatsRepos}: ${status.repoCount}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
