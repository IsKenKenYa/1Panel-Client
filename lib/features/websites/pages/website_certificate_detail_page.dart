import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';

import '../providers/website_certificate_detail_provider.dart';
import '../widgets/website_async_state_view.dart';

class WebsiteCertificateDetailPage extends StatelessWidget {
  const WebsiteCertificateDetailPage({
    super.key,
    required this.certificateId,
  });

  final int certificateId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteCertificateDetailProvider(certificateId: certificateId)..load(),
      child: const _WebsiteCertificateDetailBody(),
    );
  }
}

class _WebsiteCertificateDetailBody extends StatelessWidget {
  const _WebsiteCertificateDetailBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<WebsiteCertificateDetailProvider>(
      builder: (context, provider, _) {
        final cert = provider.certificate;
        final title = cert?.primaryDomain == null
            ? '${l10n.websitesSslInfoTitle} #${provider.certificateId}'
            : '${l10n.websitesSslInfoTitle} · ${cert!.primaryDomain}';

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                onPressed: provider.load,
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
              ),
            ],
          ),
          body: WebsiteAsyncStateView(
            isLoading: provider.isLoading,
            error: provider.error,
            onRetry: () => provider.load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: Text(l10n.websitesSslPrimaryDomain),
                    subtitle: Text(cert?.primaryDomain ?? '-'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text(l10n.websitesSslProviderLabel),
                    subtitle: Text(cert?.provider ?? '-'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text(l10n.websitesSslStatus),
                    subtitle: Text(cert?.status ?? '-'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text(l10n.websitesSslExpireDate),
                    subtitle: Text(cert?.expireDate ?? '-'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text(l10n.websitesSslDescriptionLabel),
                    subtitle: Text(cert?.description ?? '-'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
