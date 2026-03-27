import 'package:flutter/material.dart';

import 'package:onepanel_client/features/backups/models/backup_record_list_item.dart';

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
            Text('${record.accountType ?? '-'} · ${record.accountName ?? '-'}'),
            const SizedBox(height: 4),
            Text('Status: ${record.status}'),
            const SizedBox(height: 4),
            Text('Size: ${item.size ?? '-'}'),
            if ((record.description ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(record.description!),
            ],
            if ((record.fileDir ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(record.fileDir!),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                    onPressed: onDownload, child: const Text('Download')),
                OutlinedButton(
                    onPressed: onRecover, child: const Text('Recover')),
                OutlinedButton(
                    onPressed: onDelete, child: const Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
