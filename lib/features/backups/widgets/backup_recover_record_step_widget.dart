import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/backups/providers/backup_recover_provider.dart';

class BackupRecoverRecordStepWidget extends StatelessWidget {
  const BackupRecoverRecordStepWidget({
    super.key,
    required this.provider,
  });

  final BackupRecoverProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        if (provider.records.isEmpty)
          Text(l10n.backupRecoverNoCandidateRecords)
        else
          DropdownButtonFormField<int>(
            initialValue: provider.selectedRecord?.id,
            decoration: InputDecoration(
              labelText: l10n.backupRecoverRecordLabel,
            ),
            items: provider.records
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.fileName ?? ''),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              provider.selectRecord(
                provider.records.firstWhere((item) => item.id == value),
              );
            },
          ),
      ],
    );
  }
}
