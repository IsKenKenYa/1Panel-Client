import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:provider/provider.dart';

import '../providers/website_routing_rules_provider.dart';
import '../website_config_page.dart';
import '../widgets/website_section_card.dart';
import 'website_routing_rules_batch_actions.dart';
import 'website_routing_rules_single_actions.dart';

class WebsiteRoutingRulesPage extends StatelessWidget {
  const WebsiteRoutingRulesPage({
    super.key,
    required this.websiteId,
    this.displayName,
  });

  final int websiteId;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = displayName == null
        ? '${l10n.websitesTabProxy} / ${l10n.websitesTabRewrite}'
        : '${l10n.websitesTabProxy} / ${l10n.websitesTabRewrite} · $displayName';

    return ChangeNotifierProvider<WebsiteRoutingRulesProvider>(
      create: (_) =>
          WebsiteRoutingRulesProvider(websiteId: websiteId)..loadAll(),
      child: _WebsiteRoutingRulesBody(
        websiteId: websiteId,
        displayName: displayName,
        title: title,
      ),
    );
  }
}

class _WebsiteRoutingRulesBody extends StatelessWidget {
  const _WebsiteRoutingRulesBody({
    required this.websiteId,
    required this.title,
    this.displayName,
  });

  final int websiteId;
  final String title;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<WebsiteRoutingRulesProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: <Widget>[
              IconButton(
                tooltip: l10n.commonRefresh,
                onPressed: provider.loadAll,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Batch Actions',
                onPressed: () =>
                    WebsiteRoutingRulesBatchActions.showBatchDialog(
                  context,
                  provider,
                  websiteId: websiteId,
                ),
                icon: const Icon(Icons.playlist_add_check_circle_outlined),
              ),
            ],
            bottom: provider.isLoading || provider.isSubmitting
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(2),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : null,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (provider.error != null) ...<Widget>[
                Text(
                  provider.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              WebsiteSectionCard(
                title: l10n.websitesTabProxy,
                subtitle: l10n.websitesProxyHint,
                icon: Icons.swap_horiz,
                onTap: () =>
                    WebsiteRoutingRulesSingleActions.showFileEditorDialog(
                  context,
                  title: l10n.websitesTabProxy,
                  initialName: provider.proxyName,
                  initialContent: provider.proxyContent,
                  onSubmit: (name, content) =>
                      provider.saveProxy(content, name: name),
                ),
              ),
              WebsiteSectionCard(
                title: 'Proxy Status / Delete',
                subtitle: 'Enable, disable, or remove a proxy file',
                icon: Icons.toggle_on_outlined,
                trailing: Chip(label: Text(provider.proxyStatus)),
                onTap: () =>
                    WebsiteRoutingRulesSingleActions.showProxyStatusDialog(
                  context,
                  provider,
                ),
              ),
              WebsiteSectionCard(
                title: 'Redirect File',
                subtitle: 'Edit redirect file content',
                icon: Icons.alt_route_outlined,
                onTap: () =>
                    WebsiteRoutingRulesSingleActions.showFileEditorDialog(
                  context,
                  title: 'Redirect File',
                  initialName: provider.redirectName,
                  initialContent: provider.redirectContent,
                  onSubmit: (name, content) =>
                      provider.saveRedirectFile(content, name: name),
                ),
              ),
              WebsiteSectionCard(
                title: 'Load Balancer File',
                subtitle: 'Edit load balancer file content',
                icon: Icons.balance_outlined,
                onTap: () =>
                    WebsiteRoutingRulesSingleActions.showFileEditorDialog(
                  context,
                  title: 'Load Balancer File',
                  initialName: provider.loadBalancerName,
                  initialContent: provider.loadBalancerContent,
                  onSubmit: (name, content) =>
                      provider.saveLoadBalancerFile(content, name: name),
                ),
              ),
              WebsiteSectionCard(
                title: l10n.websitesTabRewrite,
                subtitle: l10n.websitesRewriteHint,
                icon: Icons.route_outlined,
                onTap: () =>
                    WebsiteRoutingRulesSingleActions.showFileEditorDialog(
                  context,
                  title: l10n.websitesTabRewrite,
                  initialName: provider.rewriteName,
                  initialContent: provider.rewriteContent,
                  onSubmit: (name, content) {
                    provider.rewriteName = name;
                    return provider.saveRewrite(content);
                  },
                ),
              ),
              WebsiteSectionCard(
                title: l10n.websitesNginxAdvancedTitle,
                subtitle: l10n.websitesConfigPageSubtitle,
                icon: Icons.settings_suggest_outlined,
                onTap: () => _openAdvanced(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAdvanced(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebsiteConfigPage(
          websiteId: websiteId,
          displayName: displayName,
        ),
      ),
    );
  }
}
