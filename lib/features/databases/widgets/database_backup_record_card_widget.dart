import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart' as backup;
import 'package:onepanel_client/shared/widgets/app_card.dart';

class DatabaseBackupRecordCardWidget extends StatelessWidget {
  const DatabaseBackupRecordCardWidget({
    super.key,
    required this.record,
    required this.onRestore,
    required this.onDelete,
  });

  final backup.BackupRecord record;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: record.fileName ?? record.name,
      subtitle: Text(record.status),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'restore') {
            onRestore();
          } else if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'restore',
            child: Text(context.l10n.databaseBackupRestoreAction),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
      child: Text(record.createdAt ?? '-'),
    );
  }
}
