import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';

import '../providers/website_ssl_accounts_provider.dart';
import '../widgets/website_async_state_view.dart';
import '../widgets/website_section_card.dart';

class WebsiteSslAccountsPage extends StatelessWidget {
  const WebsiteSslAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteSslAccountsProvider()..load(),
      child: const _WebsiteSslAccountsBody(),
    );
  }
}

class _WebsiteSslAccountsBody extends StatelessWidget {
  const _WebsiteSslAccountsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sslSettingsTitle)),
      body: Consumer<WebsiteSslAccountsProvider>(
        builder: (context, provider, _) {
          return WebsiteAsyncStateView(
            isLoading: provider.isLoading,
            error: provider.error,
            onRetry: () => provider.load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                WebsiteSectionCard(
                  title: l10n.websitesSslProviderLabel,
                  subtitle: '${provider.certificateAuthorities.length}',
                  icon: Icons.approval_outlined,
                ),
                WebsiteSectionCard(
                  title: l10n.websitesSslAcmeAccountIdLabel,
                  subtitle: '${provider.acmeAccounts.length}',
                  icon: Icons.alternate_email_outlined,
                ),
                WebsiteSectionCard(
                  title: l10n.websitesSslNameserversLabel,
                  subtitle: '${provider.dnsAccounts.length}',
                  icon: Icons.dns_outlined,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
