import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/backups/providers/backup_recover_provider.dart';
import 'package:onepanel_client/shared/i18n/backup_l10n_helper.dart';

class BackupRecoverConfirmStepWidget extends StatelessWidget {
  const BackupRecoverConfirmStepWidget({
    super.key,
    required this.provider,
    required this.onSubmit,
  });

  final BackupRecoverProvider provider;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        if (provider.supportsRecoverAction) ...<Widget>[
          TextFormField(
            initialValue: provider.secret,
            onChanged: provider.updateSecret,
            decoration: InputDecoration(
              labelText: l10n.backupRecoverSecretLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: provider.timeout.toString(),
            keyboardType: TextInputType.number,
            onChanged: (value) =>
                provider.updateTimeout(int.tryParse(value) ?? 3600),
            decoration: InputDecoration(
              labelText: l10n.backupRecoverTimeoutLabel,
            ),
          ),
        ] else ...<Widget>[
          Text(
            l10n.backupRecoverUnsupportedTypeSubmitHint(
              backupResourceTypeLabel(l10n, provider.recordType),
            ),
          ),
        ],
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(provider.selectedRecord?.fileName ?? '-'),
          subtitle: Text(provider.selectedRecord?.fileDir ?? ''),
        ),
        const SizedBox(height: 12),
        if (provider.supportsRecoverAction)
          FilledButton(
            onPressed: provider.canSubmit ? onSubmit : null,
            child: provider.isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.backupRecoverStartAction),
          ),
      ],
    );
  }
}
