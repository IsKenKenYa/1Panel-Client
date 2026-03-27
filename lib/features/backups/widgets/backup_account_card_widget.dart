import 'package:flutter/material.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/i18n/backup_l10n_helper.dart';

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
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(account.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${backupProviderLabel(l10n, account.type)} · $scopeLabel'),
            if ((account.bucket ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text('${l10n.backupAccountCardBucketLabel}: ${account.bucket}'),
            ],
            if (endpoint.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text('${l10n.backupAccountCardEndpointLabel}: $endpoint'),
            ],
            if ((account.backupPath ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text('${l10n.backupAccountCardPathLabel}: ${account.backupPath}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (onEdit != null)
                  OutlinedButton(
                    onPressed: onEdit,
                    child: Text(l10n.commonEdit),
                  ),
                OutlinedButton(
                  onPressed: onTest,
                  child: Text(l10n.backupFormTestConnectionAction),
                ),
                OutlinedButton(
                  onPressed: onBrowseFiles,
                  child: Text(l10n.backupAccountCardBrowseFilesAction),
                ),
                if (onRefreshToken != null)
                  OutlinedButton(
                    onPressed: onRefreshToken,
                    child: Text(l10n.backupAccountCardRefreshTokenAction),
                  ),
                if (onDelete != null)
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
