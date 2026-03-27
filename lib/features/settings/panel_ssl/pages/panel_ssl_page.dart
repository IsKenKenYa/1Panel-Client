import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/settings/panel_ssl/providers/panel_ssl_provider.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/risk_notice_banner.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/security_status_chip.dart';
import 'package:provider/provider.dart';

class PanelSslPage extends StatelessWidget {
  const PanelSslPage({super.key, this.provider});

  final PanelSslProvider? provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PanelSslProvider>(
      create: (_) => provider ?? PanelSslProvider()
        ..loadSslInfo(),
      child: const _PanelSslBody(),
    );
  }
}

class _PanelSslBody extends StatelessWidget {
  const _PanelSslBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<PanelSslProvider>();

    if (provider.isLoading && !provider.hasData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel TLS'),
        actions: [
          IconButton(
            onPressed: provider.loadSslInfo,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
          ),
        ],
      ),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          if (provider.isLoading) const LinearProgressIndicator(),
          if (provider.error != null && provider.hasData)
            Padding(
              padding: const EdgeInsets.only(top: AppDesignTokens.spacingSm),
              child: Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          _SectionCard(
            title: 'Overview',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      provider.domain,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    SecurityStatusChip(
                      label: describeCertificateHealth(provider.healthStatus),
                      color: _healthColor(context, provider.healthStatus),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                _InfoRow(label: 'Status', value: provider.status),
                _InfoRow(label: 'SSL Type', value: provider.sslType),
                _InfoRow(label: 'Provider', value: provider.provider),
                _InfoRow(label: 'Expiration', value: provider.expiration),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _SectionCard(
            title: 'Certificate',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploading a new certificate replaces the current panel TLS bundle immediately.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                Wrap(
                  spacing: AppDesignTokens.spacingSm,
                  runSpacing: AppDesignTokens.spacingSm,
                  children: [
                    FilledButton.icon(
                      onPressed: provider.isSubmitting
                          ? null
                          : () => _showUploadDialog(context, provider),
                      icon: const Icon(Icons.upload_outlined),
                      label: Text(l10n.commonUpload),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _downloadSsl(context, provider),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Download'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _copySummary(context, provider),
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(l10n.commonCopy),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                _InfoRow(label: 'Issuer', value: provider.issuer),
                _InfoRow(
                    label: 'Certificate Path', value: provider.certificatePath),
                _InfoRow(label: 'Key Path', value: provider.keyPath),
                _InfoRow(label: 'Serial Number', value: provider.serialNumber),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          RiskNoticeBanner(
            notices: provider.riskNotices,
            title: 'Risk',
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _SectionCard(
            title: 'History',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Last Updated', value: provider.updatedAt),
                const SizedBox(height: AppDesignTokens.spacingSm),
                if (provider.history.isEmpty)
                  const Text('No recent local actions yet.')
                else
                  for (final entry in provider.history)
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppDesignTokens.spacingSm),
                      child: Text('• $entry'),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadDialog(
    BuildContext context,
    PanelSslProvider provider,
  ) async {
    final l10n = context.l10n;
    final domainController = TextEditingController(
        text: provider.domain == '-' ? '' : provider.domain);
    final certController = TextEditingController();
    final keyController = TextEditingController();
    final errors = <String>[];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Upload panel certificate'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errors.isNotEmpty) ...[
                  for (final error in errors)
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppDesignTokens.spacingXs),
                      child: Text(
                        error,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: AppDesignTokens.spacingSm),
                ],
                TextField(
                  controller: domainController,
                  decoration: const InputDecoration(labelText: 'Domain'),
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                TextField(
                  controller: certController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Certificate PEM',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                TextField(
                  controller: keyController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Private Key PEM',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                errors
                  ..clear()
                  ..addAll(
                    provider.validateUploadFields(
                      domain: domainController.text.trim(),
                      cert: certController.text,
                      key: keyController.text,
                    ),
                  );
                setState(() {});
                if (errors.isNotEmpty) {
                  return;
                }

                final confirmed = await showDialog<bool>(
                      context: dialogContext,
                      builder: (confirmContext) => AlertDialog(
                        title: const Text('Apply certificate update'),
                        content: const Text(
                          'This replaces the current panel TLS certificate and may interrupt active browser sessions until the gateway reload finishes.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(confirmContext, false),
                            child: Text(l10n.commonCancel),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(confirmContext, true),
                            child: Text(l10n.commonConfirm),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (!confirmed) {
                  return;
                }

                if (!dialogContext.mounted) {
                  return;
                }
                Navigator.pop(dialogContext);
                final success = await provider.uploadSsl(
                  domain: domainController.text.trim(),
                  sslType: 'selfSigned',
                  cert: certController.text,
                  key: keyController.text,
                );
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? l10n.commonSaveSuccess
                          : (provider.error ?? l10n.commonSaveFailed),
                    ),
                  ),
                );
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadSsl(
      BuildContext context, PanelSslProvider provider) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Download certificate bundle'),
            content: const Text(
              'Use downloads for backup or external validation only. Handle private keys carefully after export.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    final success = await provider.downloadSsl();
    if (!context.mounted) {
      return;
    }
    final bytes = provider.lastDownloadedBytes;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Downloaded certificate bundle${bytes == null ? '' : ' ($bytes bytes)'}'
              : (provider.error ?? l10n.commonSaveFailed),
        ),
      ),
    );
  }

  Future<void> _copySummary(
      BuildContext context, PanelSslProvider provider) async {
    final l10n = context.l10n;
    await Clipboard.setData(
        ClipboardData(text: provider.buildCertificateSummary()));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.commonCopySuccess)),
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
