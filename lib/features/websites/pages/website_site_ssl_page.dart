import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';
import 'package:onepanel_client/features/websites/pages/website_ssl_center_page.dart';
import 'package:onepanel_client/features/websites/providers/website_site_ssl_provider.dart';
import 'package:onepanel_client/features/websites/widgets/website_async_state_view.dart';
import 'package:onepanel_client/features/websites/website_ssl_page.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/config_diff_preview_card.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/risk_notice_banner.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/security_status_chip.dart';
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
      create: (_) => provider ??
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
        ? 'HTTPS Strategy'
        : 'HTTPS Strategy · $displayName';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () => context.read<WebsiteSiteSslProvider>().load(),
            icon: const Icon(Icons.refresh),
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
                RiskNoticeBanner(notices: notices, title: 'Risk notices'),
                const SizedBox(height: AppDesignTokens.spacingMd),
                _SectionCard(
                  title: 'Current Certificate',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              boundCertificate?.primaryDomain ??
                                  'No certificate bound',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          SecurityStatusChip(
                            label: describeCertificateHealth(
                              resolveCertificateHealthStatus(
                                  boundCertificate?.expireDate),
                            ),
                            color: _healthColor(
                              context,
                              resolveCertificateHealthStatus(
                                  boundCertificate?.expireDate),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMd),
                      _InfoRow(
                          label: 'Provider',
                          value: boundCertificate?.provider ?? '-'),
                      _InfoRow(
                          label: 'Expiration',
                          value: boundCertificate?.expireDate ?? '-'),
                      _InfoRow(
                          label: 'Current Mode',
                          value: currentConfig?.httpConfig ?? '-'),
                    ],
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                _SectionCard(
                  title: 'HTTPS Strategy',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        label: 'HTTPS',
                        value: (currentConfig?.enable ?? false)
                            ? 'Enabled'
                            : 'Disabled',
                      ),
                      _InfoRow(
                          label: 'HTTP Mode',
                          value: currentConfig?.httpConfig ?? '-'),
                      _InfoRow(
                        label: 'Certificate Type',
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
                            label: const Text('Edit strategy'),
                          ),
                          if (pendingDiff.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.preview_outlined),
                              label: const Text('Preview diff'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (pendingDiff.isNotEmpty) ...[
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  ConfigDiffPreviewCard(
                    title: 'Strategy diff preview',
                    items: pendingDiff,
                    onApply: provider.isSaving
                        ? null
                        : () async {
                            final success = await provider.applyHttpsStrategy();
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? l10n.commonSaveSuccess
                                      : (provider.error ??
                                          l10n.commonSaveFailed),
                                ),
                              ),
                            );
                          },
                    onDiscard: provider.discardDraft,
                  ),
                ],
                const SizedBox(height: AppDesignTokens.spacingMd),
                _SectionCard(
                  title: 'Certificate Actions',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        label: 'Selected Certificate',
                        value: provider.selectedCertificate?.primaryDomain ??
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
                                    initialWebsiteId: websiteId),
                              ),
                            ),
                            icon: const Icon(Icons.workspace_premium_outlined),
                            label: const Text('Open certificate center'),
                          ),
                          OutlinedButton.icon(
                            onPressed: provider.canRollback &&
                                    !provider.isSaving
                                ? () async {
                                    final success =
                                        await provider.rollbackLastSuccessful();
                                    if (!context.mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Rolled back last successful HTTPS strategy.'
                                              : (provider.error ??
                                                  l10n.commonSaveFailed),
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.history),
                            label: const Text('Rollback last change'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                _SectionCard(
                  title: 'Advanced',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use the advanced page for certificate obtain/upload/update flows that are outside the binding strategy path.',
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
                        label: const Text('Open advanced SSL page'),
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
    bool enable = provider.currentStrategy.enable ?? false;
    String httpConfig = provider.currentStrategy.httpConfig ?? 'HTTPAlso';
    int? selectedCertificateId =
        provider.selectedCertificate?.id ?? provider.boundCertificate?.id;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update HTTPS strategy'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable HTTPS'),
                  value: enable,
                  onChanged: (value) => setState(() => enable = value),
                ),
                const SizedBox(height: AppDesignTokens.spacingSm),
                DropdownButtonFormField<String>(
                  initialValue: httpConfig,
                  decoration: const InputDecoration(labelText: 'HTTP Mode'),
                  items: const [
                    DropdownMenuItem(
                        value: 'HTTPAlso', child: Text('HTTPAlso')),
                    DropdownMenuItem(
                        value: 'HTTPToHTTPS', child: Text('HTTPToHTTPS')),
                    DropdownMenuItem(
                        value: 'HTTPSOnly', child: Text('HTTPSOnly')),
                  ],
                  onChanged: (value) =>
                      setState(() => httpConfig = value ?? 'HTTPAlso'),
                ),
                const SizedBox(height: AppDesignTokens.spacingSm),
                DropdownButtonFormField<int?>(
                  initialValue: selectedCertificateId,
                  decoration: const InputDecoration(labelText: 'Certificate'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No certificate'),
                    ),
                    ...provider.certificates.map(
                      (certificate) => DropdownMenuItem<int?>(
                        value: certificate.id,
                        child: Text(certificate.primaryDomain ??
                            'Certificate #${certificate.id ?? '-'}'),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedCertificateId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
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
              child: const Text('Preview'),
            ),
          ],
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
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
