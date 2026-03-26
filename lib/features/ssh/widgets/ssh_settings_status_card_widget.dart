import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';

class SshSettingsStatusCardWidget extends StatelessWidget {
  const SshSettingsStatusCardWidget({
    super.key,
    required this.info,
    required this.isBusy,
    required this.onOperate,
    required this.onToggleAutoStart,
  });

  final SshInfo info;
  final bool isBusy;
  final Future<void> Function(String operation) onOperate;
  final Future<void> Function(bool enabled) onToggleAutoStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.sshSettingsServiceSectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Chip(
                  label: Text(
                    info.isActive
                        ? l10n.hostAssetsStatusSuccess
                        : l10n.hostAssetsStatusFailed,
                  ),
                  backgroundColor: info.isActive
                      ? colorScheme.primaryContainer
                      : colorScheme.errorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info.message,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: isBusy
                      ? null
                      : () => onOperate(info.isActive ? 'stop' : 'start'),
                  child: Text(info.isActive ? l10n.commonStop : l10n.commonStart),
                ),
                FilledButton.tonal(
                  onPressed: isBusy ? null : () => onOperate('restart'),
                  child: Text(l10n.commonRestart),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sshAutoStartLabel),
              value: info.autoStart,
              onChanged: isBusy ? null : onToggleAutoStart,
            ),
          ],
        ),
      ),
    );
  }
}
