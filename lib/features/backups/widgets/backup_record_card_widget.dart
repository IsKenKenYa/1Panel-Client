import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/backups/models/backup_record_list_item.dart';
import 'package:onepanel_client/shared/i18n/backup_l10n_helper.dart';

class BackupRecordCardWidget extends StatelessWidget {
  const BackupRecordCardWidget({
    super.key,
    required this.item,
    required this.onDownload,
    required this.onDelete,
    required this.onRecover,
  });

  final BackupRecordListItem item;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onRecover;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final record = item.record;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(record.fileName ?? '-',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${backupProviderLabel(l10n, record.accountType ?? '-')} · '
              '${record.accountName ?? '-'}',
            ),
            const SizedBox(height: 4),
            Text('${l10n.backupRecordsStatusLabel}: ${record.status}'),
            const SizedBox(height: 4),
            Text('${l10n.backupRecordsSizeLabel}: ${item.size ?? '-'}'),
            if ((record.description ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(record.description!),
            ],
            if ((record.fileDir ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text('${l10n.commonPath}: ${record.fileDir!}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: onDownload,
                  child: Text(l10n.backupRecordsDownloadAction),
                ),
                OutlinedButton(
                  onPressed: onRecover,
                  child: Text(l10n.backupRecordsRecoverAction),
                ),
                OutlinedButton(
                  onPressed: onDelete,
                  child: Text(l10n.commonDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
