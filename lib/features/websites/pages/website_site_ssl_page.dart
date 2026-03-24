import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

import '../providers/website_site_ssl_provider.dart';
import '../widgets/website_async_state_view.dart';
import '../widgets/website_section_card.dart';
import '../website_ssl_page.dart';
import 'website_ssl_center_page.dart';

class WebsiteSiteSslPage extends StatelessWidget {
  const WebsiteSiteSslPage({
    super.key,
    required this.websiteId,
    this.displayName,
  });

  final int websiteId;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteSiteSslProvider(websiteId: websiteId)..load(),
      child: _WebsiteSiteSslBody(
        websiteId: websiteId,
        displayName: displayName,
      ),
    );
  }
}

class _WebsiteSiteSslBody extends StatelessWidget {
  const _WebsiteSiteSslBody({
    required this.websiteId,
    this.displayName,
  });

  final int websiteId;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = displayName == null
        ? l10n.websitesSslPageTitle
        : '${l10n.websitesSslPageTitle} · $displayName';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Consumer<WebsiteSiteSslProvider>(
        builder: (context, provider, _) {
          return WebsiteAsyncStateView(
            isLoading: provider.isLoading,
            error: provider.error,
            onRetry: () => provider.load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text(l10n.websitesHttpsConfigTitle),
                    subtitle: Text(
                      '${l10n.websitesHttpsEnableLabel}: '
                      '${provider.httpsConfig?.enable == true ? l10n.systemSettingsEnabled : l10n.systemSettingsDisabled}',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: Text(provider.boundCertificate?.primaryDomain ?? l10n.websitesSslNoCert),
                    subtitle: Text(provider.boundCertificate?.expireDate ?? '-'),
                  ),
                ),
                WebsiteSectionCard(
                  title: l10n.websitesSslPageTitle,
                  subtitle: l10n.websitesSslPageSubtitle,
                  icon: Icons.manage_accounts_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WebsiteSslCenterPage(
                        initialWebsiteId: websiteId,
                      ),
                    ),
                  ),
                ),
                WebsiteSectionCard(
                  title: l10n.websitesNginxAdvancedTitle,
                  subtitle: l10n.websitesSslPageSubtitle,
                  icon: Icons.tune,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WebsiteSslPage(
                        websiteId: websiteId,
                        primaryDomain: displayName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
