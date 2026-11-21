import 'package:flutter/material.dart';
import 'package:onepanel_client/core/config/release_channel_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/logger/log_level.dart';

String appLogLevelLabel(AppLocalizations l10n, AppLogLevel level) =>
    switch (level) {
      AppLogLevel.trace => l10n.systemSettingsLogLevelTrace,
      AppLogLevel.debug => l10n.systemSettingsLogLevelDebug,
      AppLogLevel.info => l10n.systemSettingsLogLevelInfo,
      AppLogLevel.warning => l10n.systemSettingsLogLevelWarning,
      AppLogLevel.error => l10n.systemSettingsLogLevelError,
      AppLogLevel.fatal => l10n.systemSettingsLogLevelFatal,
    };

Future<AppLogLevel?> showAppLogLevelDialog(
  BuildContext context,
  AppLogLevel currentLevel,
) {
  final l10n = context.l10n;
  final minimum = switch (AppReleaseChannelConfig.current) {
    AppReleaseChannel.preview => AppLogLevel.debug,
    AppReleaseChannel.alpha => AppLogLevel.debug,
    AppReleaseChannel.beta => AppLogLevel.debug,
    AppReleaseChannel.preRelease => AppLogLevel.info,
    AppReleaseChannel.release => AppLogLevel.warning,
  };
  return showDialog<AppLogLevel>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.systemSettingsAppLogsLevelTitle),
      content: RadioGroup<AppLogLevel>(
        groupValue: currentLevel,
        onChanged: (value) => Navigator.of(dialogContext).pop(value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final level in AppLogLevel.values)
              if (level.weight >= minimum.weight)
                RadioListTile<AppLogLevel>(
                  value: level,
                  title: Text(appLogLevelLabel(l10n, level)),
                ),
          ],
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
}
