import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';

import '../widgets/website_section_card.dart';
import '../website_config_page.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WebsiteSectionCard(
            title: l10n.websitesTabProxy,
            subtitle: l10n.websitesProxyHint,
            icon: Icons.swap_horiz,
            onTap: () => _openAdvanced(context),
          ),
          WebsiteSectionCard(
            title: l10n.websitesTabRewrite,
            subtitle: l10n.websitesRewriteHint,
            icon: Icons.route_outlined,
            onTap: () => _openAdvanced(context),
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
