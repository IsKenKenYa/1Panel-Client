import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/settings/panel_ssl/providers/panel_ssl_provider.dart';
import 'package:onepanel_client/features/settings/widgets/settings_scaffold.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';
import 'package:provider/provider.dart';

class PanelSslPage extends StatelessWidget {
  const PanelSslPage({super.key});

  @override
  Widget build(BuildContext context) {
    final server = context.watch<CurrentServerController>().currentServer!;
    return ChangeNotifierProvider(
      key: ValueKey((server.id, server.revision)),
      create: (_) => PanelSslProvider.forServer(server)..loadSslInfo(),
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
    final fields = {
      if (!provider.hasCertificate)
        l10n.sslSettingsStatus: l10n.systemSettingsNotSet,
      if (provider.domain case final String domain)
        l10n.sslSettingsDomain: domain,
      if (provider.expiration case final String expiration)
        l10n.sslSettingsExpiration: expiration,
      if (provider.certificatePath case final String path)
        l10n.panelTlsCertificatePathLabel: path,
    };
    final notice = switch (provider.health) {
      CertificateHealthStatus.healthy => null,
      CertificateHealthStatus.unknown => l10n.panelTlsRiskUnknownMessage,
      CertificateHealthStatus.expired => l10n.panelTlsRiskExpiredMessage,
      CertificateHealthStatus.expiringSoon =>
        l10n.panelTlsRiskExpiringSoonMessage(provider.daysRemaining!),
    };

    return SettingsScaffold(
      title: l10n.panelTlsTitle,
      actions: [
        IconButton(
          onPressed: provider.busy ? null : provider.loadSslInfo,
          icon: const Icon(Icons.refresh_outlined),
          tooltip: l10n.commonRefresh,
        ),
      ],
      body: PartialErrorToastListener(
        errorMessage: provider.loadError,
        hasCachedData: provider.hasData,
        onRetry: provider.loadSslInfo,
        child: AsyncStatePageBodyWidget(
          isLoading: !provider.hasData && provider.busy,
          errorMessage: provider.hasData ? null : provider.loadError,
          onRetry: provider.loadSslInfo,
          child: ListView(
            padding: AppDesignTokens.pagePadding,
            children: [
              SectionCard(
                title: l10n.panelTlsCertificateTitle,
                padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
                isBusy: provider.busy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final field in fields.entries)
                      LabelValueRow(label: field.key, value: field.value),
                    if (provider.hasCertificate && notice != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDesignTokens.spacingMd,
                        ),
                        child: Text(
                          notice,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: AppDesignTokens.spacingSm,
                      runSpacing: AppDesignTokens.spacingSm,
                      children: [
                        FilledButton.icon(
                          onPressed: provider.busy
                              ? null
                              : () => _upload(context, provider),
                          icon: const Icon(Icons.upload_outlined),
                          label: Text(l10n.commonUpload),
                        ),
                        if (provider.hasCertificate) ...[
                          OutlinedButton.icon(
                            onPressed: provider.busy
                                ? null
                                : () => _download(context, provider),
                            icon: const Icon(Icons.download_outlined),
                            label: Text(l10n.sslSettingsDownload),
                          ),
                          IconButton(
                            onPressed: () async {
                              final summary = fields.entries
                                  .map((field) => '${field.key}: ${field.value}')
                                  .join('\n');
                              try {
                                await Clipboard.setData(ClipboardData(text: summary));
                                if (context.mounted) {
                                  SnackBarUtils.showSuccess(context, l10n.commonCopySuccess);
                                }
                              } catch (error) {
                                if (context.mounted) _showError(context, error);
                              }
                            },
                            icon: const Icon(Icons.copy_outlined),
                            tooltip: l10n.commonCopy,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (provider.history.isNotEmpty) ...[
                const SizedBox(height: AppDesignTokens.spacingMd),
                SectionCard(
                  title: l10n.panelTlsHistoryTitle,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignTokens.spacingLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in provider.history)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(switch (entry.action) {
                            PanelSslHistoryAction.loaded =>
                              l10n.panelTlsHistoryLoaded(entry.domain ?? '—'),
                            PanelSslHistoryAction.uploaded =>
                              l10n.panelTlsHistoryUploaded(entry.domain ?? '—'),
                            PanelSslHistoryAction.downloaded =>
                              l10n.panelTlsHistoryDownloaded(entry.bytes!),
                          }),
                          subtitle: Text(
                            MaterialLocalizations.of(context).formatTimeOfDay(
                              TimeOfDay.fromDateTime(entry.createdAt),
                              alwaysUse24HourFormat:
                                  MediaQuery.alwaysUse24HourFormatOf(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _upload(BuildContext context, PanelSslProvider provider) async {
    final l10n = context.l10n;
    final form = GlobalKey<FormState>();
    var cert = '';
    var key = '';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppFormDialog(
        title: l10n.panelTlsUploadDialogTitle,
        confirmLabel: l10n.commonSave,
        onConfirm: () async {
          if (form.currentState!.validate()) {
            Navigator.of(dialogContext).pop(true);
          }
        },
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                minLines: 3,
                maxLines: 5,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l10n.panelTlsCertificatePemLabel,
                ),
                onChanged: (value) => cert = value.trim(),
                validator: (_) {
                  if (cert.isEmpty) {
                    return l10n.panelTlsValidationCertificateRequired;
                  }
                  return isPublicCertificatePem(cert)
                      ? null
                      : l10n.panelTlsValidationCertificatePemRequired;
                },
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              FormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.panelTlsValidationPrivateKeyRequired;
                  }
                  return isPrivateKeyPem(value)
                      ? null
                      : l10n.panelTlsValidationPrivateKeyPemRequired;
                },
                builder: (field) => InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.panelTlsPrivateKeyPemLabel,
                    errorText: field.errorText,
                  ),
                  child: TextButton.icon(
                    icon: Icon(key.isEmpty
                        ? Icons.content_paste_outlined
                        : Icons.check_circle_outline),
                    label: Text(
                      MaterialLocalizations.of(dialogContext).pasteButtonLabel,
                    ),
                    onPressed: () async {
                      try {
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (!field.mounted) return;
                        key = data?.text?.trim() ?? '';
                        field.didChange(key);
                        field.validate();
                      } catch (error) {
                        if (dialogContext.mounted) _showError(dialogContext, error);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              Text(l10n.panelTlsApplyUpdateMessage),
            ],
          ),
        ),
      ),
    );
    if (accepted != true || !context.mounted) return;
    try {
      await provider.uploadSsl(cert: cert, key: key);
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.commonSaveSuccess);
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _download(BuildContext context, PanelSslProvider provider) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.panelTlsDownloadDialogTitle,
      message: l10n.panelTlsDownloadDialogMessage,
      confirmLabel: l10n.sslSettingsDownload,
    );
    if (!confirmed || !context.mounted) return;
    try {
      final file = await provider.downloadSsl();
      if (!context.mounted || file.isCancelled) return;
      if (file.privateFallbackUsed) {
        SnackBarUtils.showWarning(context, l10n.fileSavePrivateFallback);
      } else {
        SnackBarUtils.showSuccess(
          context,
          l10n.fileSaveSuccessPicker(file.displayName),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    SnackBarUtils.showError(context, ErrorMessageUtils.userFacingMessage(error));
  }
}
