import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/settings/panel_ssl/providers/panel_ssl_provider.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
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
        title: Text(l10n.panelTlsTitle),
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
            title: l10n.panelTlsOverviewTitle,
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
                      label:
                          _localizedHealthLabel(context, provider.healthStatus),
                      color: _healthColor(context, provider.healthStatus),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                _InfoRow(label: l10n.sslSettingsStatus, value: provider.status),
                _InfoRow(label: l10n.sslSettingsType, value: provider.sslType),
                _InfoRow(
                    label: l10n.sslSettingsProvider, value: provider.provider),
                _InfoRow(
                    label: l10n.sslSettingsExpiration,
                    value: provider.expiration),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _SectionCard(
            title: l10n.panelTlsCertificateTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.panelTlsUploadHint,
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
                      label: Text(l10n.sslSettingsDownload),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _copySummary(context, provider),
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(l10n.commonCopy),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                _InfoRow(
                    label: l10n.panelTlsIssuerLabel, value: provider.issuer),
                _InfoRow(
                    label: l10n.panelTlsCertificatePathLabel,
                    value: provider.certificatePath),
                _InfoRow(
                    label: l10n.panelTlsKeyPathLabel, value: provider.keyPath),
                _InfoRow(
                    label: l10n.panelTlsSerialNumberLabel,
                    value: provider.serialNumber),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          RiskNoticeBanner(
            notices: _localizedRiskNotices(context, provider.riskNotices),
            title: l10n.panelTlsRiskTitle,
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _SectionCard(
            title: l10n.panelTlsHistoryTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: l10n.panelTlsLastUpdatedLabel,
                  value: provider.updatedAt,
                ),
                const SizedBox(height: AppDesignTokens.spacingSm),
                if (provider.history.isEmpty)
                  Text(l10n.panelTlsNoRecentActions)
                else
                  for (final entry in provider.history)
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppDesignTokens.spacingSm),
                      child: Text('• ${_historyEntryText(context, entry)}'),
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
          title: Text(l10n.panelTlsUploadDialogTitle),
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
                        _localizedValidationError(context, error),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: AppDesignTokens.spacingSm),
                ],
                TextField(
                  controller: domainController,
                  decoration:
                      InputDecoration(labelText: l10n.sslSettingsDomain),
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                TextField(
                  controller: certController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: l10n.panelTlsCertificatePemLabel,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                TextField(
                  controller: keyController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: l10n.panelTlsPrivateKeyPemLabel,
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
                        title: Text(l10n.panelTlsApplyUpdateTitle),
                        content: Text(l10n.panelTlsApplyUpdateMessage),
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
            title: Text(l10n.panelTlsDownloadDialogTitle),
            content: Text(l10n.panelTlsDownloadDialogMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.panelTlsContinueAction),
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
              ? l10n.panelTlsDownloadSuccess(bytes ?? 0)
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

  String _localizedHealthLabel(
    BuildContext context,
    CertificateHealthStatus status,
  ) {
    final l10n = context.l10n;
    switch (status) {
      case CertificateHealthStatus.healthy:
        return l10n.panelTlsHealthHealthy;
      case CertificateHealthStatus.expiringSoon:
        return l10n.panelTlsHealthExpiringSoon;
      case CertificateHealthStatus.expired:
        return l10n.panelTlsHealthExpired;
      case CertificateHealthStatus.unknown:
        return l10n.panelTlsHealthUnknown;
    }
  }

  List<RiskNotice> _localizedRiskNotices(
    BuildContext context,
    List<RiskNotice> notices,
  ) {
    final l10n = context.l10n;
    return notices.map((notice) {
      switch (notice.title) {
        case 'Certificate expiry unknown':
          return RiskNotice(
            level: notice.level,
            title: l10n.panelTlsRiskUnknownTitle,
            message: l10n.panelTlsRiskUnknownMessage,
          );
        case 'Certificate expired':
          return RiskNotice(
            level: notice.level,
            title: l10n.panelTlsRiskExpiredTitle,
            message: l10n.panelTlsRiskExpiredMessage,
          );
        case 'Certificate expiring soon':
          final match = RegExp(r'(\d+)').firstMatch(notice.message);
          final days = int.tryParse(match?.group(1) ?? '') ?? 0;
          return RiskNotice(
            level: notice.level,
            title: l10n.panelTlsRiskExpiringSoonTitle,
            message: l10n.panelTlsRiskExpiringSoonMessage(days),
          );
        case 'Self-signed certificate':
          return RiskNotice(
            level: notice.level,
            title: l10n.panelTlsRiskSelfSignedTitle,
            message: l10n.panelTlsRiskSelfSignedMessage,
          );
        default:
          return notice;
      }
    }).toList(growable: false);
  }

  String _localizedValidationError(BuildContext context, String error) {
    final l10n = context.l10n;
    switch (error) {
      case 'Domain is required.':
        return l10n.panelTlsValidationDomainRequired;
      case 'Certificate content is required.':
        return l10n.panelTlsValidationCertificateRequired;
      case 'Certificate must contain a PEM certificate block.':
        return l10n.panelTlsValidationCertificatePemRequired;
      case 'Private key content is required.':
        return l10n.panelTlsValidationPrivateKeyRequired;
      case 'Private key must contain a PEM key block.':
        return l10n.panelTlsValidationPrivateKeyPemRequired;
      default:
        return error;
    }
  }

  String _historyEntryText(
    BuildContext context,
    PanelSslHistoryEntry entry,
  ) {
    final l10n = context.l10n;
    final timeText = _formatTimestamp(entry.createdAt);
    switch (entry.action) {
      case PanelSslHistoryAction.loaded:
        return '$timeText · ${l10n.panelTlsHistoryLoaded(entry.domain ?? '-')}';
      case PanelSslHistoryAction.uploaded:
        return '$timeText · ${l10n.panelTlsHistoryUploaded(entry.domain ?? '-')}';
      case PanelSslHistoryAction.downloaded:
        return '$timeText · ${l10n.panelTlsHistoryDownloaded(entry.bytes ?? 0)}';
    }
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
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
