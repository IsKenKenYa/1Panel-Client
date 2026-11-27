import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';
import 'package:onepanel_client/features/websites/pages/website_ssl_center_page.dart';
import 'package:onepanel_client/features/websites/providers/website_site_ssl_provider.dart';
import 'package:onepanel_client/features/websites/widgets/website_async_state_view.dart';
import 'package:onepanel_client/features/websites/website_ssl_page.dart';
import 'package:onepanel_client/features/websites/widgets/website_site_ssl_localizations.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/config_diff_preview_card.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/risk_notice_banner.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/security_status_chip.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import 'package:provider/provider.dart';

class WebsiteSiteSslPage extends StatelessWidget {
  const WebsiteSiteSslPage({
    super.key,
    required this.websiteId,
    this.displayName,
    this.provider,
  });

  final int websiteId;
  final String? displayName;
  final WebsiteSiteSslProvider? provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WebsiteSiteSslProvider>(
      create: (_) =>
          provider ??
                WebsiteSiteSslProvider(
                  websiteId: websiteId,
                  expectedDomain: displayName,
                )
            ..load(),
      child: _WebsiteSiteSslBody(
        websiteId: websiteId,
        displayName: displayName,
      ),
    );
  }
}

class _WebsiteSiteSslBody extends StatelessWidget {
  const _WebsiteSiteSslBody({required this.websiteId, this.displayName});

  final int websiteId;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = displayName == null
        ? l10n.websiteSiteSslPageTitle
        : l10n.websiteSiteSslPageTitleWithDomain(displayName!);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () => context.read<WebsiteSiteSslProvider>().load(),
            icon: const Icon(Icons.refresh_outlined),
            tooltip: l10n.commonRefresh,
          ),
        ],
      ),
      body: Consumer<WebsiteSiteSslProvider>(
        builder: (context, provider, _) {
          final notices = provider.hasPendingChanges
              ? provider.pendingRisks
              : provider.currentRisks;
          final boundCertificate = provider.boundCertificate;
          final currentConfig = provider.httpsConfig;
          final pendingDiff =
              provider.strategyDraft?.diffItems ?? const <ConfigDiffItem>[];

          return WebsiteAsyncStateView(
            isLoading: provider.isLoading,
            error: provider.error,
            onRetry: () => provider.load(),
            child: ListView(
              padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
              children: [
                RiskNoticeBanner(
                  notices: localizeWebsiteSiteSslRiskNotices(context, notices),
                  title: l10n.websiteSiteSslRiskNoticesTitle,
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                SectionCard(
                  title: l10n.websiteSiteSslCurrentCertSection,
                  padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              boundCertificate?.primaryDomain ??
                                  l10n.websiteSiteSslNoCertificateBound,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          SecurityStatusChip(
                            label: _localizedHealthLabel(
                              context,
                              resolveCertificateHealthStatus(
                                boundCertificate?.expireDate,
                              ),
                            ),
                            color: _healthColor(
                              context,
                              resolveCertificateHealthStatus(
                                boundCertificate?.expireDate,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMd),
                      LabelValueRow(
                        label: l10n.websiteSiteSslProviderRow,
                        value: boundCertificate?.provider ?? '-',
                      ),
                      LabelValueRow(
                        label: l10n.websiteSiteSslExpirationRow,
                        value: boundCertificate?.expireDate ?? '-',
                      ),
                      LabelValueRow(
                        label: l10n.websiteSiteSslCurrentModeRow,
                        value: currentConfig?.httpConfig ?? '-',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                SectionCard(
                  title: l10n.websiteSiteSslStrategySection,
                  padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabelValueRow(
                        label: l10n.openrestyTabHttps,
                        value: (currentConfig?.enable ?? false)
                            ? l10n.systemSettingsEnabled
                            : l10n.systemSettingsDisabled,
                      ),
                      LabelValueRow(
                        label: l10n.websiteSiteSslHttpModeRow,
                        value: currentConfig?.httpConfig ?? '-',
                      ),
                      LabelValueRow(
                        label: l10n.websiteSiteSslCertTypeRow,
                        value: currentConfig?.ssl?.type ?? 'existed',
                      ),
                      const SizedBox(height: AppDesignTokens.spacingSm),
                      Wrap(
                        spacing: AppDesignTokens.spacingSm,
                        runSpacing: AppDesignTokens.spacingSm,
                        children: [
                          FilledButton.icon(
                            onPressed: provider.isSaving
                                ? null
                                : () => _showStrategyDialog(context, provider),
                            icon: const Icon(Icons.tune),
                            label: Text(l10n.websiteSiteSslEditStrategyAction),
                          ),
                          if (pendingDiff.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.preview_outlined),
                              label: Text(l10n.websiteSiteSslPreviewDiffAction),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (pendingDiff.isNotEmpty) ...[
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  ConfigDiffPreviewCard(
                    title: l10n.websiteSiteSslStrategyDiffTitle,
                    items: localizeWebsiteSiteSslDiffItems(
                      context,
                      pendingDiff,
                    ),
                    onApply: provider.isSaving
                        ? null
                        : () async {
                            final success = await provider.applyHttpsStrategy();
                            if (!context.mounted) {
                              return;
                            }
                            if (success) {
                              SnackBarUtils.showSuccess(
                                context,
                                l10n.commonSaveSuccess,
                              );
                            } else {
                              SnackBarUtils.showError(
                                context,
                                provider.error ?? l10n.commonSaveFailed,
                              );
                            }
                          },
                    onDiscard: provider.discardDraft,
                  ),
                ],
                const SizedBox(height: AppDesignTokens.spacingMd),
                SectionCard(
                  title: l10n.websiteSiteSslCertActionsSection,
                  padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabelValueRow(
                        label: l10n.websiteSiteSslSelectedCertRow,
                        value:
                            provider.selectedCertificate?.primaryDomain ??
                            boundCertificate?.primaryDomain ??
                            '-',
                      ),
                      const SizedBox(height: AppDesignTokens.spacingSm),
                      Wrap(
                        spacing: AppDesignTokens.spacingSm,
                        runSpacing: AppDesignTokens.spacingSm,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WebsiteSslCenterPage(
                                  initialWebsiteId: websiteId,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.workspace_premium_outlined),
                            label: Text(
                              l10n.websiteSiteSslOpenCertCenterAction,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                provider.canRollback && !provider.isSaving
                                ? () async {
                                    final success = await provider
                                        .rollbackLastSuccessful();
                                    if (!context.mounted) {
                                      return;
                                    }
                                    if (success) {
                                      SnackBarUtils.showSuccess(
                                        context,
                                        l10n.websiteSiteSslRollbackSuccess,
                                      );
                                    } else {
                                      SnackBarUtils.showError(
                                        context,
                                        provider.error ?? l10n.commonSaveFailed,
                                      );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.history),
                            label: Text(l10n.websiteSiteSslRollbackAction),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                SectionCard(
                  title: l10n.websiteSiteSslAdvancedSection,
                  padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.websiteSiteSslAdvancedDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMd),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WebsiteSslPage(
                              websiteId: websiteId,
                              primaryDomain: displayName,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(l10n.websiteSiteSslOpenAdvancedAction),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showStrategyDialog(
    BuildContext context,
    WebsiteSiteSslProvider provider,
  ) async {
    final l10n = context.l10n;
    bool enable = provider.currentStrategy.enable ?? false;
    String httpConfig = provider.currentStrategy.httpConfig ?? 'HTTPAlso';
    int? selectedCertificateId =
        provider.selectedCertificate?.id ?? provider.boundCertificate?.id;

    await showAdaptiveFormPanel<void>(
      context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AppFormPanel(
          title: l10n.websiteSiteSslUpdateDialogTitle,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.websiteSiteSslEnableHttpsLabel),
                value: enable,
                onChanged: (value) => setState(() => enable = value),
              ),
              const SizedBox(height: AppDesignTokens.spacingSm),
              DropdownButtonFormField<String>(
                initialValue: httpConfig,
                decoration: InputDecoration(
                  labelText: l10n.websiteSiteSslHttpModeRow,
                ),
                items: const [
                  DropdownMenuItem(value: 'HTTPAlso', child: Text('HTTPAlso')),
                  DropdownMenuItem(
                    value: 'HTTPToHTTPS',
                    child: Text('HTTPToHTTPS'),
                  ),
                  DropdownMenuItem(
                    value: 'HTTPSOnly',
                    child: Text('HTTPSOnly'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => httpConfig = value ?? 'HTTPAlso'),
              ),
              const SizedBox(height: AppDesignTokens.spacingSm),
              DropdownButtonFormField<int?>(
                initialValue: selectedCertificateId,
                decoration: InputDecoration(
                  labelText: l10n.websiteSiteSslDiffLabelCertificate,
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l10n.websiteSiteSslNoCertificate),
                  ),
                  ...provider.certificates.map(
                    (certificate) => DropdownMenuItem<int?>(
                      value: certificate.id,
                      child: Text(
                        certificate.primaryDomain ??
                            'Certificate #${certificate.id ?? '-'}',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => selectedCertificateId = value),
              ),
            ],
          ),
          confirmLabel: l10n.websiteSiteSslPreviewAction,
          onConfirm: () async {
            WebsiteSSL? nextCertificate;
            for (final certificate in provider.certificates) {
              if (certificate.id == selectedCertificateId) {
                nextCertificate = certificate;
                break;
              }
            }
            provider.stageHttpsStrategy(
              enable: enable,
              httpConfig: httpConfig,
              certificate: nextCertificate,
              clearCertificate: selectedCertificateId == null,
            );
            Navigator.pop(dialogContext);
          },
        ),
      ),
    );
  }

  Color _healthColor(BuildContext context, CertificateHealthStatus status) {
    switch (status) {
      case CertificateHealthStatus.healthy:
        return AppDesignTokens.success;
      case CertificateHealthStatus.expiringSoon:
        return AppDesignTokens.warning;
      case CertificateHealthStatus.expired:
        return Theme.of(context).colorScheme.error;
      case CertificateHealthStatus.unknown:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  String _localizedHealthLabel(
    BuildContext context,
    CertificateHealthStatus status,
  ) {
    final l10n = context.l10n;
    switch (status) {
      case CertificateHealthStatus.healthy:
        return l10n.websitesSslHealthHealthy;
      case CertificateHealthStatus.expiringSoon:
        return l10n.websitesSslHealthExpiringSoon;
      case CertificateHealthStatus.expired:
        return l10n.websitesSslHealthExpired;
      case CertificateHealthStatus.unknown:
        return l10n.websitesSslHealthUnknown;
    }
  }
}
