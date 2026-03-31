import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onepanel_client/core/config/release_channel_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/file_save_service.dart' as fs;
import 'package:onepanel_client/core/services/logger/log_export_service.dart';
import 'package:onepanel_client/core/services/logger/log_file_manager_service.dart';
import 'package:onepanel_client/core/services/logger/log_level.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/settings/about_page.dart';

class FeedbackCenterPage extends StatefulWidget {
  const FeedbackCenterPage({super.key});

  @override
  State<FeedbackCenterPage> createState() => _FeedbackCenterPageState();
}

class _FeedbackCenterPageState extends State<FeedbackCenterPage> {
  final fs.FileSaveService _fileSaveService = fs.FileSaveService();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLogLevelLocked = AppReleaseChannelConfig.forceDebugLogLevel;
    final logLevelSubtitle = isLogLevelLocked
        ? '${_logLevelLabel(l10n, appLogger.minLogLevel)} · ${l10n.systemSettingsAppLogsLevelLocked}'
        : _logLevelLabel(l10n, appLogger.minLogLevel);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsFeedbackCenterTitle),
      ),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.settingsFeedbackCenterIntro),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Text(
            l10n.settingsFeedbackGuideTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. ${l10n.settingsFeedbackGuideStep1}'),
                  const SizedBox(height: 8),
                  Text('2. ${l10n.settingsFeedbackGuideStep2}'),
                  const SizedBox(height: 8),
                  Text('3. ${l10n.settingsFeedbackGuideStep3}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Text(
            l10n.settingsFeedback,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: Text(l10n.aboutFeedbackAction),
                  subtitle: Text(l10n.settingsFeedbackIssueSubtitle),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openIssues(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.content_copy_outlined),
                  title: Text(l10n.settingsFeedbackCopyTemplate),
                  subtitle: Text(l10n.settingsFeedbackTemplateHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _copyTemplate(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Text(
            l10n.settingsFeedbackLogsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.filter_alt_outlined),
                  title: Text(l10n.systemSettingsAppLogsLevelTitle),
                  subtitle: Text(logLevelSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => isLogLevelLocked
                      ? _showLogLevelLockedHint(context)
                      : _selectAppLogLevel(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text(l10n.commonExport),
                  subtitle: Text(l10n.systemSettingsAppLogsExportSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportAppLogs(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: Text(l10n.commonClear),
                  subtitle: Text(l10n.systemSettingsAppLogsClearSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _clearAppLogs(context),
                ),
              ],
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsFeedbackOpenFailed)),
      );
    }
  }

  Future<void> _copyTemplate(BuildContext context) async {
    final l10n = context.l10n;
    final template = '''
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
- app: 1Panel Client
''';
    await Clipboard.setData(ClipboardData(text: template.trim()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.commonCopied)),
    );
  }

  Future<void> _exportAppLogs(BuildContext context) async {
    final l10n = context.l10n;
    final result =
        await LogExportService().exportLogs(minLevel: appLogger.minLogLevel);
    if (!context.mounted) return;

    if (!result.success &&
        result.permissionStatus == fs.PermissionStatus.permanentlyDenied) {
      await _showPermissionSettingsDialog(context);
      return;
    }

    if (!result.success &&
        result.permissionStatus == fs.PermissionStatus.denied) {
      final permissionStatus = await _fileSaveService.requestStoragePermission();
      if (!context.mounted) return;
      if (permissionStatus == fs.PermissionStatus.granted) {
        final retryResult =
            await LogExportService().exportLogs(minLevel: appLogger.minLogLevel);
        if (!context.mounted) return;
        _showExportResultSnackBar(context, retryResult);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.permissionStorageRequired)),
        );
      }
      return;
    }

    _showExportResultSnackBar(context, result);
  }

  Future<void> _showPermissionSettingsDialog(
      BuildContext dialogParentContext) async {
    final l10n = dialogParentContext.l10n;
    await showDialog<void>(
      context: dialogParentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.permissionRequired),
        content: Text(l10n.permissionStorageRequired),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              openAppSettings();
            },
            child: Text(l10n.permissionGoToSettings),
          ),
        ],
      ),
    );
  }

  void _showExportResultSnackBar(BuildContext context, fs.FileSaveResult result) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? '${l10n.commonSaveSuccess}: ${result.filePath ?? ''}'
              : '${l10n.commonSaveFailed}: ${result.errorMessage ?? ''}',
        ),
      ),
    );
  }

  Future<void> _clearAppLogs(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.systemSettingsAppLogsClearTitle),
            content: Text(l10n.systemSettingsAppLogsClearConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.commonConfirm),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await LogFileManagerService().clearLogs();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.systemSettingsAppLogsCleared)),
    );
  }

  String _logLevelLabel(AppLocalizations l10n, AppLogLevel level) {
    switch (level) {
      case AppLogLevel.trace:
        return l10n.systemSettingsLogLevelTrace;
      case AppLogLevel.debug:
        return l10n.systemSettingsLogLevelDebug;
      case AppLogLevel.info:
        return l10n.systemSettingsLogLevelInfo;
      case AppLogLevel.warning:
        return l10n.systemSettingsLogLevelWarning;
      case AppLogLevel.error:
        return l10n.systemSettingsLogLevelError;
      case AppLogLevel.fatal:
        return l10n.systemSettingsLogLevelFatal;
    }
  }

  Future<void> _selectAppLogLevel(BuildContext context) async {
    final l10n = context.l10n;
    final channelFloor = _channelMinLogLevelFloor();
    final selectableLevels = AppLogLevel.values
        .where((level) => level.weight >= channelFloor.weight)
        .toList();

    final selected = await showDialog<AppLogLevel>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.systemSettingsAppLogsLevelTitle),
        content: RadioGroup<AppLogLevel>(
          groupValue: appLogger.minLogLevel,
          onChanged: (value) => Navigator.of(dialogContext).pop(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: selectableLevels
                .map(
                  (level) => RadioListTile<AppLogLevel>(
                    value: level,
                    title: Text(_logLevelLabel(l10n, level)),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
        ],
      ),
    );
    if (selected == null) return;

    await appLogger.setMinLogLevel(selected);
    await appLogger.applyReleaseChannelPolicy();

    if (!context.mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${l10n.commonSaveSuccess}: ${_logLevelLabel(l10n, appLogger.minLogLevel)}',
        ),
      ),
    );
  }

  AppLogLevel _channelMinLogLevelFloor() {
    switch (AppReleaseChannelConfig.current) {
      case AppReleaseChannel.preview:
      case AppReleaseChannel.alpha:
      case AppReleaseChannel.beta:
        return AppLogLevel.debug;
      case AppReleaseChannel.preRelease:
        return AppLogLevel.info;
      case AppReleaseChannel.release:
        return AppLogLevel.warning;
    }
  }

  void _showLogLevelLockedHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.systemSettingsAppLogsLevelLocked)),
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
