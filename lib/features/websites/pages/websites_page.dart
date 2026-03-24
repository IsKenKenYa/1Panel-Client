import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/config/app_router.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/website_models.dart';
import 'package:onepanelapp_app/features/shell/controllers/current_server_controller.dart';
import 'package:onepanelapp_app/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanelapp_app/features/websites/providers/websites_provider.dart';
import 'package:onepanelapp_app/features/websites/widgets/website_async_state_view.dart';

class WebsitesPage extends StatelessWidget {
  const WebsitesPage({
    super.key,
    this.provider,
  });

  final WebsitesProvider? provider;

  @override
  Widget build(BuildContext context) {
    if (provider != null) {
      return ChangeNotifierProvider<WebsitesProvider>.value(
        value: provider!,
        child: const _WebsitesPageView(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => WebsitesProvider(),
      child: const _WebsitesPageView(),
    );
  }
}

class _WebsitesPageView extends StatefulWidget {
  const _WebsitesPageView();

  @override
  State<_WebsitesPageView> createState() => _WebsitesPageViewState();
}

class _WebsitesPageViewState extends State<_WebsitesPageView> {
  String? _activeServerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WebsitesProvider>().loadWebsites();
    });
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WebsitesProvider>().onServerChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ServerAwarePageScaffold(
      title: l10n.websitesPageTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<WebsitesProvider>().refresh(),
          tooltip: l10n.commonRefresh,
        ),
        IconButton(
          icon: const Icon(Icons.tune_outlined),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.openrestyCenter),
          tooltip: l10n.openrestyPageTitle,
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.websiteCreate),
        icon: const Icon(Icons.add),
        label: Text(l10n.commonCreate),
      ),
      body: Consumer<WebsitesProvider>(
        builder: (context, provider, _) {
          final data = provider.data;
          if (data.isLoading && data.websites.isEmpty) {
            return const WebsiteAsyncStateView(isLoading: true);
          }

          if (data.error != null && data.websites.isEmpty) {
            return WebsiteAsyncStateView(
              error: l10n.websitesLoadFailedMessage(data.error!),
              onRetry: provider.loadWebsites,
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: data.websites.isEmpty ? 2 : data.websites.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _StatsCard(stats: data.stats);
                }
                if (data.websites.isEmpty) {
                  return _EmptyView(
                    title: l10n.websitesEmptyTitle,
                    subtitle: l10n.websitesEmptySubtitle,
                  );
                }
                final website = data.websites[index - 1];
                return _WebsiteTile(
                  website: website,
                  onTap: () => _openDetail(context, website),
                  onAction: (action) =>
                      _handleAction(context, provider, website, action),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, WebsiteInfo website) {
    final id = website.id;
    if (id == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.websiteDetail,
      arguments: {
        'websiteId': id,
      },
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WebsitesProvider provider,
    WebsiteInfo website,
    _WebsiteAction action,
  ) async {
    final l10n = context.l10n;
    final id = website.id;
    if (id == null) return;

    if (action == _WebsiteAction.delete) {
      await _showDeleteDialog(context, website, provider);
      return;
    }

    bool ok;
    switch (action) {
      case _WebsiteAction.start:
        ok = await provider.startWebsite(id);
        break;
      case _WebsiteAction.stop:
        ok = await provider.stopWebsite(id);
        break;
      case _WebsiteAction.restart:
        ok = await provider.restartWebsite(id);
        break;
      case _WebsiteAction.delete:
        ok = false;
        break;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              ok ? l10n.websitesOperateSuccess : l10n.websitesOperateFailed)),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WebsiteInfo website,
    WebsitesProvider provider,
  ) async {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        title: Text(l10n.websitesDeleteTitle),
        content: Text(
          l10n.websitesDeleteMessage(
            website.displayDomain ?? l10n.websitesUnknownDomain,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.deleteWebsite(website.id ?? 0);
              if (!context.mounted || !success) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.websitesDeleteSuccess)),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final WebsiteStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.websitesStatsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  title: l10n.websitesStatsTotal,
                  value: stats.total.toString(),
                  color: colorScheme.primary,
                  icon: Icons.language,
                ),
                _StatItem(
                  title: l10n.websitesStatsRunning,
                  value: stats.running.toString(),
                  color: colorScheme.tertiary,
                  icon: Icons.play_circle,
                ),
                _StatItem(
                  title: l10n.websitesStatsStopped,
                  value: stats.stopped.toString(),
                  color: colorScheme.secondary,
                  icon: Icons.stop_circle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.language_outlined, size: 64, color: colorScheme.outline),
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
    );
  }
}

enum _WebsiteAction { start, stop, restart, delete }

class _WebsiteTile extends StatelessWidget {
  const _WebsiteTile({
    required this.website,
    required this.onTap,
    required this.onAction,
  });

  final WebsiteInfo website;
  final VoidCallback onTap;
  final void Function(_WebsiteAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final isRunning = website.status?.toLowerCase() == 'running';
    final statusText =
        isRunning ? l10n.websitesStatusRunning : l10n.websitesStatusStopped;
    final statusColor =
        isRunning ? colorScheme.tertiary : colorScheme.secondary;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        title: Text(website.displayDomain ?? l10n.websitesUnknownDomain),
        subtitle: Text(
          '${l10n.websitesStatusLabel}: $statusText'
          '${website.type?.isNotEmpty == true ? ' · ${website.type}' : ''}',
        ),
        trailing: PopupMenuButton<_WebsiteAction>(
          tooltip: l10n.commonMore,
          onSelected: onAction,
          itemBuilder: (_) => [
            if (!isRunning)
              PopupMenuItem(
                value: _WebsiteAction.start,
                child: Text(l10n.websitesActionStart),
              ),
            if (isRunning)
              PopupMenuItem(
                value: _WebsiteAction.stop,
                child: Text(l10n.websitesActionStop),
              ),
            if (isRunning)
              PopupMenuItem(
                value: _WebsiteAction.restart,
                child: Text(l10n.websitesActionRestart),
              ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: _WebsiteAction.delete,
              child: Text(
                l10n.websitesActionDelete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
