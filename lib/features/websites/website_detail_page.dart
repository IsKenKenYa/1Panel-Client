import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/v2/website_v2.dart';
import '../../core/network/api_client_manager.dart';
import '../../data/models/website_models.dart';
import 'website_config_page.dart';
import 'website_domain_page.dart';
import 'website_ssl_page.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import '../openresty/openresty_page.dart';

class WebsiteDetailPage extends StatelessWidget {
  final int websiteId;

  const WebsiteDetailPage({super.key, required this.websiteId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteDetailProvider(websiteId: websiteId)..loadDetail(),
      child: const _WebsiteDetailBody(),
    );
  }
}

class WebsiteDetailProvider extends ChangeNotifier {
  final int websiteId;
  WebsiteV2Api? _api;

  bool isLoading = false;
  String? error;
  WebsiteInfo? website;

  WebsiteDetailProvider({required this.websiteId});

  Future<void> _ensureApi() async {
    if (_api != null) return;
    _api = await ApiClientManager.instance.getWebsiteApi();
  }

  Future<void> loadDetail() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _ensureApi();
      website = await _api!.getWebsiteDetail(websiteId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> operate(String action) async {
    await _ensureApi();
    await _api!.operateWebsite(id: websiteId, operate: action);
    await loadDetail();
  }
}

class _WebsiteDetailBody extends StatelessWidget {
  const _WebsiteDetailBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<WebsiteDetailProvider>(
      builder: (context, provider, _) {
        final title = provider.website?.displayDomain ?? '${l10n.websitesDetailTitle} #${provider.websiteId}';

        if (provider.error != null) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: _ErrorSection(
              message: provider.error!,
              onRetry: provider.loadDetail,
            ),
          );
        }

        if (provider.isLoading && provider.website == null) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final website = provider.website;
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.loadDetail,
                tooltip: l10n.commonRefresh,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OverviewCard(website: website),
              const SizedBox(height: 12),
              _InfoCard(website: website),
              const SizedBox(height: 12),
              _ActionCard(
                websiteId: provider.websiteId,
                website: website,
                onOperate: provider.operate,
              ),
              const SizedBox(height: 12),
              _ManagementCard(websiteId: provider.websiteId, website: website),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final WebsiteInfo? website;

  const _OverviewCard({required this.website});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final w = website;
    final status = w?.status ?? '-';
    final isRunning = status.toLowerCase() == 'running';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    w?.displayDomain ?? l10n.websitesUnknownDomain,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRunning ? colorScheme.tertiaryContainer : colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isRunning ? l10n.websitesStatusRunning : l10n.websitesStatusStopped,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isRunning ? colorScheme.onTertiaryContainer : colorScheme.onErrorContainer,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('${l10n.websitesTypeLabel}: ${w?.type ?? '-'}'),
            Text('${l10n.websitesProtocolLabel}: ${w?.protocol ?? '-'}'),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final WebsiteInfo? website;

  const _InfoCard({required this.website});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final w = website;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.websitesDetailInfoTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _InfoRow(label: l10n.websitesSitePathLabel, value: w?.sitePath ?? '-'),
            _InfoRow(label: l10n.websitesRuntimeLabel, value: w?.runtimeName ?? '-'),
            _InfoRow(label: l10n.websitesSslStatusLabel, value: w?.sslStatus ?? '-'),
            _InfoRow(label: l10n.websitesSslExpireLabel, value: w?.sslExpireDate ?? '-'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final int websiteId;
  final WebsiteInfo? website;
  final Future<void> Function(String action) onOperate;

  const _ActionCard({
    required this.websiteId,
    required this.website,
    required this.onOperate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = website?.status?.toLowerCase() ?? '';
    final isRunning = status == 'running';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.websitesDetailActionsTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: isRunning ? null : () => onOperate('start'),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.websitesActionStart),
                ),
                FilledButton.icon(
                  onPressed: isRunning ? () => onOperate('stop') : null,
                  icon: const Icon(Icons.stop),
                  label: Text(l10n.websitesActionStop),
                ),
                OutlinedButton.icon(
                  onPressed: isRunning ? () => onOperate('restart') : null,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.websitesActionRestart),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final int websiteId;
  final WebsiteInfo? website;

  const _ManagementCard({
    required this.websiteId,
    required this.website,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(l10n.websitesConfigPageTitle),
            subtitle: Text(l10n.websitesConfigPageSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WebsiteConfigPage(
                    websiteId: websiteId,
                    displayName: website?.displayDomain,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(l10n.websitesDomainsPageTitle),
            subtitle: Text(l10n.websitesDomainsPageSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WebsiteDomainPage(
                    websiteId: websiteId,
                    primaryDomain: website?.primaryDomain,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(l10n.websitesSslPageTitle),
            subtitle: Text(l10n.websitesSslPageSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WebsiteSslPage(
                    websiteId: websiteId,
                    primaryDomain: website?.primaryDomain,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(l10n.openrestyPageTitle),
            subtitle: Text(l10n.websitesOpenrestySubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OpenRestyPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorSection({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(l10n.commonLoadFailedTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
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
