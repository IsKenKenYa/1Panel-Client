import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/website_models.dart';

import 'website_common_widgets.dart';

class WebsiteWorkbenchCard extends StatelessWidget {
  const WebsiteWorkbenchCard({
    super.key,
    required this.websiteId,
    required this.website,
    required this.onOpenConfig,
    required this.onOpenDomains,
    required this.onOpenSsl,
    required this.onOpenRouting,
    required this.onOpenOpenResty,
  });

  final int websiteId;
  final WebsiteInfo? website;
  final VoidCallback onOpenConfig;
  final VoidCallback onOpenDomains;
  final VoidCallback onOpenSsl;
  final VoidCallback onOpenRouting;
  final VoidCallback onOpenOpenResty;

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
            onTap: onOpenConfig,
          ),
          const Divider(height: 1),
          WebsiteWorkbenchEntryTile(
            title: l10n.websitesDomainsPageTitle,
            subtitle: l10n.websitesDomainsPageSubtitle,
            icon: Icons.language_outlined,
            onTap: onOpenDomains,
          ),
          const Divider(height: 1),
          WebsiteWorkbenchEntryTile(
            title: l10n.websitesSslPageTitle,
            subtitle: l10n.websitesSslPageSubtitle,
            icon: Icons.verified_user_outlined,
            onTap: onOpenSsl,
          ),
          const Divider(height: 1),
          WebsiteWorkbenchEntryTile(
            title: '${l10n.websitesTabProxy} / ${l10n.websitesTabRewrite}',
            subtitle: l10n.websitesConfigScopeTitle,
            icon: Icons.route_outlined,
            onTap: onOpenRouting,
          ),
          const Divider(height: 1),
          WebsiteWorkbenchEntryTile(
            title: l10n.openrestyPageTitle,
            subtitle: l10n.websitesOpenrestySubtitle,
            icon: Icons.settings_suggest_outlined,
            onTap: onOpenOpenResty,
          ),
        ],
      ),
    );
  }
}
