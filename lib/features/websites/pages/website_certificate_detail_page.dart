import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

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
      create: (_) =>
          WebsiteCertificateDetailProvider(certificateId: certificateId)
            ..load(),
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                onPressed: provider.load,
                icon: const Icon(Icons.refresh_outlined),
                tooltip: l10n.commonRefresh,
              ),
            ],
          ),
          body: WebsiteAsyncStateView(
            isLoading: provider.isLoading,
            error: provider.error,
            onRetry: () => provider.load(),
            child: ListView(
              padding: AppDesignTokens.cardPadding,
              children: [
                SectionPropertyList(
                  properties: [
                    SectionProperty(
                      label: l10n.websitesSslPrimaryDomain,
                      value: cert?.primaryDomain,
                    ),
                    SectionProperty(
                      label: l10n.websitesSslProviderLabel,
                      value: cert?.provider,
                    ),
                    SectionProperty(
                      label: l10n.websitesSslStatus,
                      value: cert?.status,
                    ),
                    SectionProperty(
                      label: l10n.websitesSslExpireDate,
                      value: cert?.expireDate,
                    ),
                    SectionProperty(
                      label: l10n.websitesSslDescriptionLabel,
                      value: cert?.description,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
