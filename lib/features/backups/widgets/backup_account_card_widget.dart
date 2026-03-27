import 'package:flutter/material.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';

class BackupAccountCardWidget extends StatelessWidget {
  const BackupAccountCardWidget({
    super.key,
    required this.account,
    required this.endpoint,
    required this.scopeLabel,
    this.onEdit,
    required this.onTest,
    required this.onBrowseFiles,
    this.onDelete,
    this.onRefreshToken,
  });

  final BackupAccountInfo account;
  final String endpoint;
  final String scopeLabel;
  final VoidCallback? onEdit;
  final VoidCallback onTest;
  final VoidCallback onBrowseFiles;
  final VoidCallback? onDelete;
  final VoidCallback? onRefreshToken;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(account.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${account.type} · $scopeLabel'),
            if ((account.bucket ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text('Bucket: ${account.bucket}'),
            ],
            if (endpoint.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text('Endpoint: $endpoint'),
            ],
            if ((account.backupPath ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text('Path: ${account.backupPath}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (onEdit != null)
                  OutlinedButton(
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                OutlinedButton(onPressed: onTest, child: const Text('Test')),
                OutlinedButton(
                  onPressed: onBrowseFiles,
                  child: const Text('Browse files'),
                ),
                if (onRefreshToken != null)
                  OutlinedButton(
                    onPressed: onRefreshToken,
                    child: const Text('Refresh token'),
                  ),
                if (onDelete != null)
                  OutlinedButton(
                    onPressed: onDelete,
                    child: const Text('Delete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
