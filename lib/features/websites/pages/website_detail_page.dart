import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

import '../providers/website_detail_provider.dart';
import '../widgets/website_common_widgets.dart';
import '../widgets/website_detail_cards_widget.dart';
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
      child: const _WebsiteDetailBody(),
    );
  }
}

class _WebsiteDetailBody extends StatelessWidget {
  const _WebsiteDetailBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<WebsiteDetailProvider>(
      builder: (context, provider, _) {
        final website = provider.website;
        final title =
            website?.displayDomain ?? '${l10n.websitesDetailTitle} #${provider.websiteId}';

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
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.openrestyCenter),
                tooltip: l10n.openrestyPageTitle,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WebsiteOverviewCard(website: website),
              const SizedBox(height: 12),
              WebsiteActionCard(
                website: website,
                onOperate: provider.operate,
                onEdit: () => _openEdit(context, provider.websiteId),
                onSetDefault: provider.setDefaultServer,
                onDelete: () => _confirmDelete(context, provider),
              ),
              const SizedBox(height: 12),
              WebsiteWorkbenchCard(
                websiteId: provider.websiteId,
                website: website,
                onOpenConfig: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WebsiteConfigCenterPage(
                      websiteId: provider.websiteId,
                      displayName: website?.displayDomain,
                    ),
                  ),
                ),
                onOpenDomains: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WebsiteDomainManagementPage(
                      websiteId: provider.websiteId,
                      primaryDomain: website?.primaryDomain,
                    ),
                  ),
                ),
                onOpenSsl: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WebsiteSiteSslPage(
                      websiteId: provider.websiteId,
                      displayName: website?.displayDomain,
                    ),
                  ),
                ),
                onOpenRouting: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WebsiteRoutingRulesPage(
                      websiteId: provider.websiteId,
                      displayName: website?.displayDomain,
                    ),
                  ),
                ),
                onOpenOpenResty: () =>
                    Navigator.pushNamed(context, AppRoutes.openrestyCenter),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WebsiteDetailProvider provider,
  ) async {
    final website = provider.website;
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        title: Text(l10n.websitesDeleteTitle),
        content: Text(
          l10n.websitesDeleteMessage(
            website?.displayDomain ?? l10n.websitesUnknownDomain,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await provider.deleteWebsite();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _openEdit(BuildContext context, int websiteId) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.websiteEdit,
      arguments: {'websiteId': websiteId},
    );
    if (result == true && context.mounted) {
      await context.read<WebsiteDetailProvider>().loadDetail();
    }
  }
}
