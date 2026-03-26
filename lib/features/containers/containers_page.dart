import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/config/app_router.dart';
import 'package:onepanelapp_app/data/models/container_models.dart' hide Container, ContainerStats;
import 'package:onepanelapp_app/features/containers/widgets/container_card.dart';
import '../../shared/widgets/app_card.dart';
import '../../widgets/main_layout.dart';
import 'containers_provider.dart';
import 'package:onepanelapp_app/features/orchestration/compose_page.dart';
import 'package:onepanelapp_app/features/orchestration/image_page.dart';
import 'package:onepanelapp_app/features/orchestration/network_page.dart';
import 'package:onepanelapp_app/features/orchestration/volume_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return MainLayout(
      currentIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('容器管理'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: 搜索容器
              },
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // TODO: 筛选容器
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: '概览'),
              Tab(text: '容器'),
              Tab(text: '编排'),
              Tab(text: '镜像'),
              Tab(text: '网络'),
              Tab(text: '存储卷'),
              Tab(text: '仓库'),
              Tab(text: '编排模板'),
              Tab(text: '配置'),
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
            const _PlaceholderTab(title: '概览', icon: Icons.dashboard),
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
            const _PlaceholderTab(title: '仓库', icon: Icons.store),
            // 编排模板
            const _PlaceholderTab(title: '编排模板', icon: Icons.description),
            // 配置
            const _PlaceholderTab(title: '配置', icon: Icons.settings),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/container-create');
          },
          icon: const Icon(Icons.add),
          label: const Text('创建容器'),
        ),
      ),
    );
  }

  void _showDeleteContainerDialog(
    BuildContext context,
    String containerId,
    ContainersProvider provider,
  ) {
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        title: const Text('删除容器'),
        content: const Text('确定要删除这个容器吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.deleteContainer(containerId);
              if (!parentContext.mounted) return;
              if (success) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('容器已删除')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 占位标签页
class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderTab({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            '$title 功能开发中',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 加载中视图
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('加载中...'),
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
              '加载失败',
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
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 容器标签页
class _ContainersTab extends StatefulWidget {
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
  State<_ContainersTab> createState() => _ContainersTabState();
}

class _ContainersTabState extends State<_ContainersTab> {
  bool _statsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 容器统计卡片 (可折叠)
            Card(
              margin: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: _statsExpanded,
                  onExpansionChanged: (v) =>
                      setState(() => _statsExpanded = v),
                  leading: Icon(Icons.bar_chart,
                      color: colorScheme.primary),
                  title: Row(
                    children: [
                      Text('容器统计'),
                      const SizedBox(width: 12),
                      _StatsBadge(
                          value: widget.stats.total.toString(),
                          color: colorScheme.primary),
                      const SizedBox(width: 6),
                      _StatsBadge(
                          value: '▶ ${widget.stats.running}',
                          color: Colors.green),
                      const SizedBox(width: 6),
                      _StatsBadge(
                          value: '■ ${widget.stats.stopped}',
                          color: Colors.orange),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            title: '总数',
                            value: widget.stats.total.toString(),
                            color: colorScheme.primary,
                            icon: Icons.inventory_2,
                          ),
                          _StatItem(
                            title: '运行中',
                            value: widget.stats.running.toString(),
                            color: Colors.green,
                            icon: Icons.play_circle,
                          ),
                          _StatItem(
                            title: '已停止',
                            value: widget.stats.stopped.toString(),
                            color: Colors.orange,
                            icon: Icons.stop_circle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 容器列表
            if (widget.containers.isEmpty && !widget.isLoading)
              const _EmptyView(
                icon: Icons.inventory_2_outlined,
                title: '暂无容器',
                subtitle: '点击右下角按钮创建容器',
              )
            else
              ...widget.containers.map((container) {
                final containerInfo = container as ContainerInfo;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ContainerCard(
                    container: containerInfo,
                    onStart: () => widget.onStart(containerInfo.name),
                    onStop: () => widget.onStop(containerInfo.name),
                    onRestart: () => widget.onRestart(containerInfo.name),
                    onDelete: () => widget.onDelete(containerInfo.name),
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

/// 统计徽章（用于折叠时的摘要显示）
class _StatsBadge extends StatelessWidget {
  final String value;
  final Color color;

  const _StatsBadge({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: TextStyle(
            fontSize: 12, color: color, fontWeight: FontWeight.w600),
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
