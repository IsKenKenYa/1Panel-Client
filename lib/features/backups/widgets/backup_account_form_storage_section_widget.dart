import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/backups/models/backup_account_draft.dart';

class BackupAccountFormStorageSectionWidget extends StatelessWidget {
  const BackupAccountFormStorageSectionWidget({
    super.key,
    required this.draft,
    required this.bucketOptions,
    required this.isLoadingBuckets,
    required this.onCommonChanged,
    required this.onVarChanged,
    required this.onLoadBuckets,
  });

  final BackupAccountDraft draft;
  final List<String> bucketOptions;
  final bool isLoadingBuckets;
  final void Function({
    String? accessKey,
    String? credential,
    String? bucket,
    String? backupPath,
    bool? rememberAuth,
    bool? manualBucketInput,
  }) onCommonChanged;
  final void Function(String key, dynamic value) onVarChanged;
  final VoidCallback onLoadBuckets;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = draft.type;
    final objectStorage = const <String>{
      'S3',
      'MINIO',
      'OSS',
      'COS',
      'KODO',
      'UPYUN'
    }.contains(type);

    return Column(
      children: <Widget>[
        if (type == 'COS' || type == 'S3')
          TextFormField(
            key: ValueKey<String>('backup-region-${draft.stringVar('region')}'),
            initialValue: draft.stringVar('region'),
            onChanged: (value) => onVarChanged('region', value),
            decoration: InputDecoration(labelText: l10n.backupFormRegionLabel),
          ),
        if (type == 'COS' || type == 'S3') const SizedBox(height: 12),
        if (objectStorage)
          TextFormField(
            key: ValueKey<String>(
                'backup-endpoint-${draft.stringVar(type == 'KODO' ? 'domain' : 'endpoint')}'),
            initialValue:
                draft.stringVar(type == 'KODO' ? 'domain' : 'endpoint'),
            onChanged: (value) =>
                onVarChanged(type == 'KODO' ? 'domain' : 'endpoint', value),
            decoration: InputDecoration(
              labelText: type == 'KODO'
                  ? l10n.backupFormDomainLabel
                  : l10n.backupFormEndpointLabel,
            ),
          ),
        if (objectStorage) const SizedBox(height: 12),
        if (objectStorage || type == 'UPYUN')
          Row(
            children: <Widget>[
              Expanded(
                child: draft.manualBucketInput || bucketOptions.isEmpty
                    ? TextFormField(
                        key: ValueKey<String>('backup-bucket-${draft.bucket}'),
                        initialValue: draft.bucket,
                        onChanged: (value) => onCommonChanged(bucket: value),
                        decoration: InputDecoration(
                            labelText: l10n.backupFormBucketLabel),
                      )
                    : DropdownButtonFormField<String>(
                        initialValue:
                            draft.bucket.isEmpty ? null : draft.bucket,
                        decoration: InputDecoration(
                          labelText: l10n.backupFormBucketLabel,
                        ),
                        items: bucketOptions
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) => onCommonChanged(bucket: value),
                      ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: isLoadingBuckets ? null : onLoadBuckets,
                icon: isLoadingBuckets
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
        if (objectStorage || type == 'UPYUN') const SizedBox(height: 12),
        TextFormField(
          key: ValueKey<String>('backup-path-${draft.backupPath}'),
          initialValue: draft.backupPath,
          onChanged: (value) => onCommonChanged(backupPath: value),
          decoration:
              InputDecoration(labelText: l10n.backupFormBackupPathLabel),
        ),
      ],
    );
  }
}
