import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/website_models.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import '../providers/websites_provider.dart';
import 'website_detail_page.dart';
import 'website_create_flow_page.dart';

class WebsitesPage extends StatefulWidget {
  const WebsitesPage({super.key});

  @override
  State<WebsitesPage> createState() => _WebsitesPageState();
}

class _WebsitesPageState extends State<WebsitesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WebsitesProvider>().loadWebsites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.websitesPageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<WebsitesProvider>().refresh(),
            tooltip: l10n.commonRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/openresty'),
            tooltip: l10n.openrestyPageTitle,
          ),
        ],
      ),
      body: Consumer<WebsitesProvider>(
        builder: (context, provider, _) {
          final data = provider.data;

          if (data.isLoading && data.websites.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (data.error != null && data.websites.isEmpty) {
            return _ErrorView(
              error: data.error!,
              onRetry: provider.loadWebsites,
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatsCard(stats: data.stats),
                const SizedBox(height: 12),
                if (data.websites.isEmpty)
                  _EmptyView(
                    title: l10n.websitesEmptyTitle,
                    subtitle: l10n.websitesEmptySubtitle,
                  )
                else
                  ...data.websites.map(
                    (w) => _WebsiteTile(
                      website: w,
                      onTap: () => _openDetail(context, w),
                      onAction: (action) => _handleAction(context, provider, w, action),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WebsiteCreateFlowPage()),
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.commonCreate),
      ),
    );
  }

  void _openDetail(BuildContext context, WebsiteInfo website) {
    final id = website.id;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebsiteDetailPage(websiteId: id),
      ),
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
      SnackBar(content: Text(ok ? l10n.websitesOperateSuccess : l10n.websitesOperateFailed)),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WebsiteInfo website,
    WebsitesProvider provider,
  ) async {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        title: Text(l10n.websitesDeleteTitle),
        content: Text(l10n.websitesDeleteMessage(website.displayDomain ?? l10n.websitesUnknownDomain)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.deleteWebsite(website.id ?? 0);
              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.websitesDeleteSuccess)),
                );
              }
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

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

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
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.commonLoadFailedTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.websitesLoadFailedMessage(error),
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

class _StatsCard extends StatelessWidget {
  final WebsiteStats stats;

  const _StatsCard({required this.stats});

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
            Text(l10n.websitesStatsTitle, style: Theme.of(context).textTheme.titleMedium),
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
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyView({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
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
      ),
    );
  }
}

enum _WebsiteAction { start, stop, restart, delete }

class _WebsiteTile extends StatelessWidget {
  final WebsiteInfo website;
  final VoidCallback onTap;
  final void Function(_WebsiteAction action) onAction;

  const _WebsiteTile({
    required this.website,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final isRunning = website.status?.toLowerCase() == 'running';
    final statusText = isRunning ? l10n.websitesStatusRunning : l10n.websitesStatusStopped;
    final statusColor = isRunning ? colorScheme.tertiary : colorScheme.secondary;

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(website.displayDomain ?? l10n.websitesUnknownDomain),
        subtitle: Text('${l10n.websitesStatusLabel}: $statusText'),
        leading: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        trailing: PopupMenuButton<_WebsiteAction>(
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
