import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/l10n_x.dart';
import '../../shared/widgets/app_card.dart';
import '../shell/widgets/server_aware_page_scaffold.dart';
import 'websites_provider.dart';

class WebsitesPage extends StatefulWidget {
  const WebsitesPage({super.key});

  @override
  State<WebsitesPage> createState() => _WebsitesPageState();
}

class _WebsitesPageState extends State<WebsitesPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时获取数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WebsitesProvider>().loadWebsites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ServerAwarePageScaffold(
      title: l10n.serverModuleWebsites,
      body: Consumer<WebsitesProvider>(
        builder: (context, provider, child) {
          final data = provider.data;

          if (data.error != null) {
            return _ErrorView(
              error: data.error!,
              onRetry: () => provider.loadWebsites(),
            );
          }

          if (data.isLoading && data.websites.isEmpty) {
            return const _LoadingView();
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsCard(stats: data.stats),
                  const SizedBox(height: 16),
                  if (data.websites.isEmpty && !data.isLoading)
                    const _EmptyView(
                      icon: Icons.language_outlined,
                      title: '暂无网站',
                      subtitle: '点击右下角按钮创建网站',
                    )
                  else
                    ...data.websites.map((website) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WebsiteCard(
                          website: website,
                          onStart: () => provider.startWebsite(website.id ?? 0),
                          onStop: () => provider.stopWebsite(website.id ?? 0),
                          onRestart: () => provider.restartWebsite(website.id ?? 0),
                          onDelete: () => _showDeleteDialog(context, website, provider),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<WebsitesProvider>().refresh(),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/website-create'),
        icon: const Icon(Icons.add),
        label: const Text('创建网站'),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    dynamic website,
    WebsitesProvider provider,
  ) {
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        title: const Text('删除网站'),
        content: Text('确定要删除 ${website.primaryDomain ?? '此网站'} 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.deleteWebsite(website.id ?? 0);
              if (!parentContext.mounted) return;
              if (success) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('网站已删除')),
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

/// 统计卡片
class _StatsCard extends StatelessWidget {
  final WebsiteStats stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AppCard(
      title: '网站统计',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            title: '总数',
            value: stats.total.toString(),
            color: colorScheme.primary,
            icon: Icons.language,
          ),
          _StatItem(
            title: '运行中',
            value: stats.running.toString(),
            color: Colors.green,
            icon: Icons.play_circle,
          ),
          _StatItem(
            title: '已停止',
            value: stats.stopped.toString(),
            color: Colors.orange,
            icon: Icons.stop_circle,
          ),
        ],
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

/// 网站卡片
class _WebsiteCard extends StatelessWidget {
  final dynamic website;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;
  final VoidCallback onDelete;

  const _WebsiteCard({
    required this.website,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRunning = website.status?.toLowerCase() == 'running';
    final statusColor = isRunning ? Colors.green : Colors.orange;
    
    return AppCard(
      title: website.primaryDomain ?? '未命名网站',
      subtitle: Text(_getWebsiteType(website.type)),
      trailing: _StatusChip(
        status: isRunning ? '运行中' : '已停止',
        color: statusColor,
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/website-detail',
          arguments: {'websiteId': website.id},
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (website.alias != null && website.alias.isNotEmpty)
            Text(
              '别名: ${website.alias}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isRunning) ...[
                _ActionButton(
                  icon: Icons.stop,
                  label: '停止',
                  color: Colors.orange,
                  onTap: onStop,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.restart_alt,
                  label: '重启',
                  color: colorScheme.primary,
                  onTap: onRestart,
                ),
              ] else ...[
                _ActionButton(
                  icon: Icons.play_arrow,
                  label: '启动',
                  color: Colors.green,
                  onTap: onStart,
                ),
              ],
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.delete_outline,
                label: '删除',
                color: Colors.red,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getWebsiteType(String? type) {
    switch (type?.toLowerCase()) {
      case 'static':
        return '静态网站';
      case 'php':
        return 'PHP网站';
      case 'reverse_proxy':
        return '反向代理';
      case 'java':
        return 'Java网站';
      case 'nodejs':
        return 'Node.js网站';
      case 'python':
        return 'Python网站';
      case 'go':
        return 'Go网站';
      case 'dotnet':
        return '.NET网站';
      default:
        return '未知类型';
    }
  }
}

/// 状态标签
class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusChip({
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 操作按钮
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
