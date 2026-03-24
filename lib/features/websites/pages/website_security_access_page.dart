import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

import '../widgets/website_section_card.dart';
import '../website_config_page.dart';

class WebsiteSecurityAccessPage extends StatelessWidget {
  const WebsiteSecurityAccessPage({
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
        ? l10n.securitySettingsAccessControl
        : '${l10n.securitySettingsAccessControl} · $displayName';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WebsiteSectionCard(
            title: l10n.securitySettingsAllowIPs,
            subtitle: l10n.securitySettingsTitle,
            icon: Icons.security,
            onTap: () => _openAdvanced(context),
          ),
          WebsiteSectionCard(
            title: l10n.securitySettingsBindDomain,
            subtitle: l10n.websitesDomainsPageSubtitle,
            icon: Icons.domain_outlined,
            onTap: () => _openAdvanced(context),
          ),
          WebsiteSectionCard(
            title: l10n.websitesNginxAdvancedTitle,
            subtitle: l10n.websitesConfigPageSubtitle,
            icon: Icons.shield_moon_outlined,
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
