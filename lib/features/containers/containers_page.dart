import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/config/app_router.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/container_models.dart' hide Container, ContainerStats;
import 'package:onepanelapp_app/features/containers/tabs/overview_tab.dart';
import 'package:onepanelapp_app/features/containers/tabs/repos_tab.dart';
import 'package:onepanelapp_app/features/containers/tabs/templates_tab.dart';
import 'package:onepanelapp_app/features/containers/tabs/config_tab.dart';
import 'package:onepanelapp_app/features/containers/widgets/container_card.dart';
import 'package:onepanelapp_app/features/orchestration/compose_page.dart';
import 'package:onepanelapp_app/features/orchestration/image_page.dart';
import 'package:onepanelapp_app/features/orchestration/network_page.dart';
import 'package:onepanelapp_app/features/orchestration/volume_page.dart';
import 'package:onepanelapp_app/features/orchestration/providers/image_provider.dart';
import 'package:onepanelapp_app/features/containers/containers_provider.dart';
import 'package:onepanelapp_app/features/orchestration/providers/compose_provider.dart';
import 'package:onepanelapp_app/features/orchestration/providers/network_provider.dart';
import 'package:onepanelapp_app/features/orchestration/providers/volume_provider.dart';
import 'package:onepanelapp_app/features/containers/dialogs/compose_create_dialog.dart';
import 'package:onepanelapp_app/features/containers/dialogs/network_create_dialog.dart';
import 'package:onepanelapp_app/features/containers/dialogs/volume_create_dialog.dart';
import 'package:onepanelapp_app/features/containers/dialogs/repo_create_dialog.dart';
import 'package:onepanelapp_app/features/containers/dialogs/template_create_dialog.dart';
import 'package:onepanelapp_app/widgets/main_layout.dart';
import 'package:onepanelapp_app/shared/widgets/app_card.dart';

class ContainersPage extends StatefulWidget {
  const ContainersPage({super.key});

  @override
  State<ContainersPage> createState() => _ContainersPageState();
}

class _ContainersPageState extends State<ContainersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
    // 页面加载时获取数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContainersProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showPullDialog(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.orchestrationPullImage),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.orchestrationPullImageHint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      final provider = context.read<DockerImageProvider>();
      
      String image = result;
      String? tag;
      if (result.contains(':')) {
        final parts = result.split(':');
        image = parts[0];
        tag = parts.sublist(1).join(':');
      }
      
      final success = await provider.pullImage(image, tag: tag);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? l10n.orchestrationPullSuccess 
              : l10n.orchestrationPullFailed),
          ),
        );
      }
    }
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
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: 搜索容器
              },
              tooltip: l10n.containerSearch,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // TODO: 筛选容器
              },
              tooltip: l10n.containerFilter,
            ),
          ],
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
            // 概览
            const OverviewTab(),
            // 容器标签页 (保留原有实现)
            Consumer<ContainersProvider>(
              builder: (context, provider, child) {
                final data = provider.data;
                if (data.error != null) {
                  return _ErrorView(
                    error: data.error!,
                    onRetry: () => provider.loadAll(),
                  );
                }
                if (data.isLoading && data.containers.isEmpty) {
                  return const _LoadingView();
                }
                return _ContainersTab(
                  containers: data.containers,
                  stats: data.containerStats,
                  isLoading: data.isLoading,
                  onRefresh: () => provider.refresh(),
                  onStart: (id) => provider.startContainer(id),
                  onStop: (id) => provider.stopContainer(id),
                  onRestart: (id) => provider.restartContainer(id),
                  onDelete: (id) => _showDeleteContainerDialog(context, id, provider),
                );
              },
            ),
            // 编排
            const ComposePage(),
            // 镜像
            const ImagePage(),
            // 网络
            const NetworkPage(),
            // 存储卷
            const VolumePage(),
            // 仓库
            const ReposTab(),
            // 编排模板
            const TemplatesTab(),
            // 配置
            const ConfigTab(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(context, l10n),
      ),
    );
  }

  Future<void> _showCreateComposeDialog(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showDialog<ContainerComposeCreate>(
      context: context,
      builder: (context) => const ComposeCreateDialog(),
    );

    if (result != null && context.mounted) {
      final provider = context.read<ComposeProvider>();
      final success = await provider.createCompose(result);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.containerOperateSuccess)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.containerOperateFailed(provider.error ?? 'Unknown error'))),
          );
        }
      }
    }
  }

  Future<void> _showCreateNetworkDialog(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const NetworkCreateDialog(),
    );

    if (result != null && context.mounted) {
      final provider = context.read<NetworkProvider>();
      final request = NetworkCreate(
        name: result['name'],
        driver: result['driver'],
        subnet: result['subnet'],
        gateway: result['gateway'],
        ipv4: true, // Defaulting to true as per dialog
      );
      final success = await provider.createNetwork(request);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.containerOperateSuccess)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.containerOperateFailed(provider.error ?? 'Unknown error'))),
          );
        }
      }
    }
  }

  Future<void> _showCreateVolumeDialog(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const VolumeCreateDialog(),
    );

    if (result != null && context.mounted) {
      final provider = context.read<VolumeProvider>();
      final request = VolumeCreate(
        name: result['name'],
        driver: result['driver'],
      );
      final success = await provider.createVolume(request);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.containerOperateSuccess)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.containerOperateFailed(provider.error ?? 'Unknown error'))),
          );
        }
      }
    }
  }

  Future<void> _showCreateRepoDialog(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const RepoCreateDialog(),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.containerOperateSuccess)),
      );
    }
  }

  Future<void> _showCreateTemplateDialog(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const TemplateCreateDialog(),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.containerOperateSuccess)),
      );
    }
  }

  Widget? _buildFloatingActionButton(BuildContext context, dynamic l10n) {
    switch (_tabController.index) {
      case 1: // Containers
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/container-create');
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.containerCreate),
        );
      case 2: // Orchestration
        return FloatingActionButton.extended(
          onPressed: () => _showCreateComposeDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateProject),
        );
      case 3: // Images
        return FloatingActionButton.extended(
          onPressed: () => _showPullDialog(context),
          icon: const Icon(Icons.download),
          label: Text(l10n.orchestrationPullImage),
        );
      case 4: // Networks
        return FloatingActionButton.extended(
          onPressed: () => _showCreateNetworkDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateNetwork),
        );
      case 5: // Volumes
        return FloatingActionButton.extended(
          onPressed: () => _showCreateVolumeDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateVolume),
        );
      case 6: // Repositories
        return FloatingActionButton.extended(
          onPressed: () => _showCreateRepoDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateRepo),
        );
      case 7: // Templates
        return FloatingActionButton.extended(
          onPressed: () => _showCreateTemplateDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateTemplate),
        );
      default:
        return null;
    }
  }

  void _showDeleteContainerDialog(
    BuildContext context,
    String containerId,
    ContainersProvider provider,
  ) {
    final parentContext = context;
    final l10n = context.l10n;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        title: Text(l10n.commonDelete),
        content: Text(l10n.containerDeleteConfirm(containerId)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.deleteContainer(containerId);
              if (!parentContext.mounted) return;
              if (success) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text(l10n.containerOperateSuccess)),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }
}

// _PlaceholderTab class removed as it is no longer used
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.commonLoading),
        ],
      ),
    );
  }
}

/// 错误视图
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.commonLoadFailedTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

/// 容器标签页
class _ContainersTab extends StatelessWidget {
  final List<dynamic> containers;
  final ContainerStats stats;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Future<bool> Function(String) onStart;
  final Future<bool> Function(String) onStop;
  final Future<bool> Function(String) onRestart;
  final void Function(String) onDelete;

  const _ContainersTab({
    required this.containers,
    required this.stats,
    required this.isLoading,
    required this.onRefresh,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 容器统计卡片
            _StatsCard(
              title: l10n.containerStatsTitle,
              stats: [
                _StatItem(
                  title: l10n.containerStatsTotal,
                  value: stats.total.toString(),
                  color: colorScheme.primary,
                  icon: Icons.inventory_2,
                ),
                _StatItem(
                  title: l10n.containerStatsRunning,
                  value: stats.running.toString(),
                  color: Colors.green,
                  icon: Icons.play_circle,
                ),
                _StatItem(
                  title: l10n.containerStatsStopped,
                  value: stats.stopped.toString(),
                  color: Colors.orange,
                  icon: Icons.stop_circle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 容器列表
            if (containers.isEmpty && !isLoading)
              _EmptyView(
                icon: Icons.inventory_2_outlined,
                title: l10n.containerEmptyTitle,
                subtitle: l10n.containerEmptyDesc,
              )
            else
              ...containers.map((container) {
                final containerInfo = container as ContainerInfo;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ContainerCard(
                    container: containerInfo,
                    onStart: () => onStart(containerInfo.name),
                    onStop: () => onStop(containerInfo.name),
                    onRestart: () => onRestart(containerInfo.name),
                    onDelete: () => onDelete(containerInfo.name),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.containerDetail,
                        arguments: containerInfo,
                      );
                    },
                    onLogs: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.containerDetail,
                        arguments: containerInfo,
                      );
                    },
                    onTerminal: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.containerDetail,
                        arguments: containerInfo,
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// 统计卡片
class _StatsCard extends StatelessWidget {
  final String title;
  final List<_StatItem> stats;

  const _StatsCard({
    required this.title,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: title,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats,
      ),
    );
  }
}

/// 统计项
class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 空状态视图
class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.outline,
              ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}