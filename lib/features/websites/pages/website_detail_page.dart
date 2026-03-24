import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import '../../../data/models/website_models.dart';
import '../providers/website_detail_provider.dart';
import '../widgets/website_common_widgets.dart';
import 'website_config_center_page.dart';
import 'website_domain_management_page.dart';
import 'website_routing_rules_page.dart';
import 'website_site_ssl_page.dart';

class WebsiteDetailPage extends StatelessWidget {
  const WebsiteDetailPage({
    super.key,
    required this.websiteId,
  });

  final int websiteId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteDetailProvider(websiteId: websiteId)..loadDetail(),
      child: const _WebsiteWorkbenchBody(),
    );
  }
}

class _WebsiteWorkbenchBody extends StatelessWidget {
  const _WebsiteWorkbenchBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<WebsiteDetailProvider>(
      builder: (context, provider, _) {
        final website = provider.website;
        final title = website?.displayDomain ?? '${l10n.websitesDetailTitle} #${provider.websiteId}';

        if (provider.isLoading && website == null) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null && website == null) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: WebsiteErrorSection(
              message: provider.error!,
              onRetry: provider.loadDetail,
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.loadDetail,
                tooltip: l10n.commonRefresh,
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.pushNamed(context, '/openresty'),
                tooltip: l10n.openrestyPageTitle,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OverviewCard(website: website),
              const SizedBox(height: 12),
              _ActionCard(website: website, onOperate: provider.operate),
              const SizedBox(height: 12),
              _WorkbenchCard(websiteId: provider.websiteId, website: website),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.website});

  final WebsiteInfo? website;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final status = website?.status ?? '-';
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
                    website?.displayDomain ?? l10n.websitesUnknownDomain,
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
            Text('${l10n.websitesTypeLabel}: ${website?.type ?? '-'}'),
            Text('${l10n.websitesProtocolLabel}: ${website?.protocol ?? '-'}'),
            Text('${l10n.websitesSitePathLabel}: ${website?.sitePath ?? '-'}'),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.website,
    required this.onOperate,
  });

  final WebsiteInfo? website;
  final Future<void> Function(String action) onOperate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRunning = website?.status?.toLowerCase() == 'running';

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

class _WorkbenchCard extends StatelessWidget {
  const _WorkbenchCard({
    required this.websiteId,
    required this.website,
  });

  final int websiteId;
  final WebsiteInfo? website;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Column(
        children: [
          WebsiteWorkbenchEntryTile(
            title: l10n.websitesConfigPageTitle,
            subtitle: l10n.websitesConfigPageSubtitle,
            icon: Icons.tune,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WebsiteConfigCenterPage(
                  websiteId: websiteId,
                  displayName: website?.displayDomain,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          WebsiteWorkbenchEntryTile(
            title: l10n.websitesDomainsPageTitle,
            subtitle: l10n.websitesDomainsPageSubtitle,
            icon: Icons.language_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WebsiteDomainManagementPage(
                  websiteId: websiteId,
                  primaryDomain: website?.primaryDomain,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          WebsiteWorkbenchEntryTile(
            title: l10n.websitesSslPageTitle,
            subtitle: l10n.websitesSslPageSubtitle,
            icon: Icons.verified_user_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WebsiteSiteSslPage(
                  websiteId: websiteId,
                  displayName: website?.displayDomain,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          WebsiteWorkbenchEntryTile(
            title: '${l10n.websitesTabProxy} / ${l10n.websitesTabRewrite}',
            subtitle: l10n.websitesConfigScopeTitle,
            icon: Icons.route_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WebsiteRoutingRulesPage(
                  websiteId: websiteId,
                  displayName: website?.displayDomain,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          WebsiteWorkbenchEntryTile(
            title: l10n.openrestyPageTitle,
            subtitle: l10n.websitesOpenrestySubtitle,
            icon: Icons.settings_suggest_outlined,
            onTap: () => Navigator.pushNamed(context, '/openresty'),
          ),
        ],
      ),
    );
  }
}
