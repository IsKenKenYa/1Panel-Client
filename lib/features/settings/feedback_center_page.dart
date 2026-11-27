import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onepanel_client/core/config/release_channel_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/core/platform/services/platform_diagnostics_service.dart';
import 'package:onepanel_client/core/services/logger/log_export_service.dart';
import 'package:onepanel_client/core/services/logger/log_format.dart';
import 'package:onepanel_client/features/settings/widgets/settings_scaffold.dart';
import 'package:onepanel_client/core/services/logger/log_file_manager_service.dart';
import 'package:onepanel_client/features/settings/widgets/app_log_level_dialog.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/services/logger/widgets/log_preview_dialog.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/settings/about_page.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

class FeedbackCenterPage extends StatefulWidget {
  const FeedbackCenterPage({super.key});

  @override
  State<FeedbackCenterPage> createState() => _FeedbackCenterPageState();
}

class _FeedbackCenterPageState extends State<FeedbackCenterPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLogLevelLocked = AppReleaseChannelConfig.forceDebugLogLevel;
    final logLevelSubtitle = isLogLevelLocked
        ? '${appLogLevelLabel(l10n, appLogger.minLogLevel)} · ${l10n.systemSettingsAppLogsLevelLocked}'
        : appLogLevelLabel(l10n, appLogger.minLogLevel);

    return SettingsScaffold(
      title: l10n.settingsFeedbackCenterTitle,
      body: ListView(
        padding: AppDesignTokens.scrollPagePadding(context),
        children: [
          SectionEntryList(
            title: l10n.settingsFeedback,
            items: [
              SectionEntryItem(
                icon: Icons.feedback_outlined,
                title: l10n.aboutFeedbackAction,
                subtitle: l10n.settingsFeedbackIssueSubtitle,
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openIssues(context),
              ),
              SectionEntryItem(
                icon: Icons.content_copy_outlined,
                title: l10n.settingsFeedbackCopyTemplate,
                subtitle: l10n.settingsFeedbackTemplateHint,
                onTap: () => _copyTemplate(context),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          SectionEntryList(
            title: l10n.settingsFeedbackLogsTitle,
            items: [
              SectionEntryItem(
                icon: Icons.preview_outlined,
                title: l10n.systemSettingsAppLogsPreviewButton,
                subtitle: l10n.systemSettingsAppLogsPreviewSubtitle,
                onTap: () => _previewLogs(context),
              ),
              SectionEntryItem(
                icon: Icons.filter_alt_outlined,
                title: l10n.systemSettingsAppLogsLevelTitle,
                subtitle: logLevelSubtitle,
                onTap: isLogLevelLocked
                    ? null
                    : () => _selectAppLogLevel(context),
              ),
              SectionEntryItem(
                icon: Icons.download_outlined,
                title: l10n.commonExport,
                subtitle: l10n.systemSettingsAppLogsExportSubtitle,
                onTap: () => _exportAppLogs(context),
              ),
              SectionEntryItem(
                icon: Icons.delete_sweep_outlined,
                title: l10n.commonClear,
                subtitle: l10n.systemSettingsAppLogsClearSubtitle,
                onTap: () => _clearAppLogs(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openIssues(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(AboutPage.issuesUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      SnackBarUtils.showError(context, context.l10n.settingsFeedbackOpenFailed);
    }
  }

  Future<void> _copyTemplate(BuildContext context) async {
    final l10n = context.l10n;
    final platformTemplate = await PlatformDiagnosticsService()
        .buildFeedbackTemplate();
    final template =
        '''
${l10n.settingsFeedbackTemplateTitle}

${l10n.settingsFeedbackTemplateSummary}
- 

${l10n.settingsFeedbackTemplateRepro}
1. 
2. 
3. 

${l10n.settingsFeedbackTemplateExpected}
- 

${l10n.settingsFeedbackTemplateActual}
- 

${l10n.settingsFeedbackTemplateLogs}
- 

${l10n.settingsFeedbackTemplateEnvironment}
- channel: ${_channelLabel(l10n)}
- app: KenPanel

---
$platformTemplate
''';
    await Clipboard.setData(ClipboardData(text: template.trim()));
    if (!context.mounted) return;
    SnackBarUtils.showSuccess(context, l10n.commonCopied);
  }

  Future<void> _previewLogs(BuildContext context) async {
    final format = await showAdaptiveFormPanel<LogFormat>(
      context,
      builder: (_) => const LogPreviewDialog(),
    );
    if (context.mounted && format != null) {
      await _exportAppLogs(context, format: format);
    }
  }

  Future<void> _exportAppLogs(
    BuildContext context, {
    LogFormat format = LogFormat.humanReadable,
  }) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.settingsFeedbackLogExportWarningTitle,
      message: l10n.settingsFeedbackLogExportWarningMessage,
      confirmLabel: l10n.settingsFeedbackLogExportConfirm,
    );

    if (confirmed != true || !context.mounted) return;

    final result = await LogExportService().exportLogs(
      minLevel: appLogger.minLogLevel,
      format: format,
    );
    if (!context.mounted) return;

    if (result.wasCancelled) return;
    if (!result.success) {
      SnackBarUtils.showError(
        context,
        ErrorMessageUtils.truncateForToast(
          result.errorMessage ?? l10n.commonSaveFailed,
        ),
      );
      return;
    }

    final displayName = result.displayName ?? result.filePath;
    if (result.privateFallbackUsed) {
      SnackBarUtils.showWarning(context, l10n.fileSavePrivateFallback);
    } else {
      SnackBarUtils.showSuccess(
        context,
        displayName == null || displayName.isEmpty
            ? l10n.fileSaveSuccessDownloads
            : l10n.fileSaveSuccessPicker(displayName),
      );
    }
  }

  Future<void> _clearAppLogs(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.systemSettingsAppLogsClearTitle,
      message: l10n.systemSettingsAppLogsClearConfirm,
      confirmLabel: l10n.commonConfirm,
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await LogFileManagerService().clearLogs();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.settings.feedback',
        'Failed to clear application logs',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          ErrorMessageUtils.userFacingMessage(error),
        );
      }
      return;
    }
    if (!context.mounted) return;
    SnackBarUtils.showSuccess(context, l10n.systemSettingsAppLogsCleared);
  }

  Future<void> _selectAppLogLevel(BuildContext context) async {
    final l10n = context.l10n;
    final selected = await showAppLogLevelDialog(
      context,
      appLogger.minLogLevel,
    );
    if (selected == null) return;

    await appLogger.setMinLogLevel(selected);
    await appLogger.applyReleaseChannelPolicy();

    if (!context.mounted) return;
    setState(() {});
    SnackBarUtils.showSuccess(
      context,
      '${l10n.commonSaveSuccess}: ${appLogLevelLabel(l10n, appLogger.minLogLevel)}',
    );
  }

  String _channelLabel(AppLocalizations l10n) {
    switch (AppReleaseChannelConfig.current) {
      case AppReleaseChannel.preview:
        return l10n.releaseChannelPreview;
      case AppReleaseChannel.alpha:
        return l10n.releaseChannelAlpha;
      case AppReleaseChannel.beta:
        return l10n.releaseChannelBeta;
      case AppReleaseChannel.preRelease:
        return l10n.releaseChannelPreRelease;
      case AppReleaseChannel.release:
        return l10n.releaseChannelRelease;
    }
  }
}
