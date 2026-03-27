import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/backups/models/backup_account_draft.dart';

class BackupAccountFormCredentialsSectionWidget extends StatelessWidget {
  const BackupAccountFormCredentialsSectionWidget({
    super.key,
    required this.draft,
    required this.onCommonChanged,
    required this.onVarChanged,
    required this.onOneDriveRegionChanged,
    required this.onAliyunTokenChanged,
    required this.onStartOAuth,
  });

  final BackupAccountDraft draft;
  final void Function({
    String? accessKey,
    String? credential,
    String? bucket,
    String? backupPath,
    bool? rememberAuth,
    bool? manualBucketInput,
  }) onCommonChanged;
  final void Function(String key, dynamic value) onVarChanged;
  final ValueChanged<bool> onOneDriveRegionChanged;
  final ValueChanged<String> onAliyunTokenChanged;
  final VoidCallback onStartOAuth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = draft.type;
    final isObjectStorage = const <String>{
      'S3',
      'MINIO',
      'OSS',
      'COS',
      'KODO',
      'UPYUN'
    }.contains(type);
    final isPasswordType = type == 'SFTP' || type == 'WebDAV';
    final isOAuth = type == 'OneDrive' || type == 'GoogleDrive';
    final isAliyun = type == 'ALIYUN';

    return Column(
      children: <Widget>[
        if (isObjectStorage || isPasswordType || type == 'UPYUN')
          TextFormField(
            key: ValueKey<String>('backup-access-${draft.accessKey}'),
            initialValue: draft.accessKey,
            onChanged: (value) => onCommonChanged(accessKey: value),
            decoration: InputDecoration(
              labelText: isPasswordType
                  ? l10n.backupFormUsernameAccessKeyLabel
                  : l10n.backupFormAccessKeyLabel,
            ),
          ),
        if (isObjectStorage || isPasswordType || type == 'UPYUN')
          const SizedBox(height: 12),
        if (isObjectStorage || isPasswordType || type == 'UPYUN')
          TextFormField(
            key: ValueKey<String>('backup-credential-${draft.credential}'),
            initialValue: draft.credential,
            onChanged: (value) => onCommonChanged(credential: value),
            decoration:
                InputDecoration(labelText: l10n.backupFormCredentialLabel),
          ),
        if (type == 'SFTP') ...<Widget>[
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>(
                'backup-sftp-address-${draft.stringVar('address')}'),
            initialValue: draft.stringVar('address'),
            onChanged: (value) => onVarChanged('address', value),
            decoration: InputDecoration(labelText: l10n.backupFormAddressLabel),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>(
                'backup-sftp-port-${draft.intVar('port', defaultValue: 22)}'),
            initialValue: draft.intVar('port', defaultValue: 22).toString(),
            keyboardType: TextInputType.number,
            onChanged: (value) =>
                onVarChanged('port', int.tryParse(value) ?? 22),
            decoration: InputDecoration(labelText: l10n.backupFormPortLabel),
          ),
        ],
        if (type == 'WebDAV') ...<Widget>[
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>(
                'backup-webdav-address-${draft.stringVar('address')}'),
            initialValue: draft.stringVar('address'),
            onChanged: (value) => onVarChanged('address', value),
            decoration: InputDecoration(labelText: l10n.backupFormAddressLabel),
          ),
        ],
        if (isOAuth) ...<Widget>[
          if (type == 'OneDrive')
            SwitchListTile(
              value: draft.boolVar('isCN'),
              onChanged: onOneDriveRegionChanged,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.backupFormChinaCloudLabel),
            ),
          TextFormField(
            key: ValueKey<String>(
                'backup-client-id-${draft.stringVar('client_id')}'),
            initialValue: draft.stringVar('client_id'),
            onChanged: (value) => onVarChanged('client_id', value),
            decoration:
                InputDecoration(labelText: l10n.backupFormClientIdLabel),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>(
                'backup-client-secret-${draft.stringVar('client_secret')}'),
            initialValue: draft.stringVar('client_secret'),
            onChanged: (value) => onVarChanged('client_secret', value),
            decoration:
                InputDecoration(labelText: l10n.backupFormClientSecretLabel),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>(
                'backup-redirect-${draft.stringVar('redirect_uri')}'),
            initialValue: draft.stringVar('redirect_uri'),
            onChanged: (value) => onVarChanged('redirect_uri', value),
            decoration:
                InputDecoration(labelText: l10n.backupFormRedirectUriLabel),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>('backup-code-${draft.stringVar('code')}'),
            initialValue: draft.stringVar('code'),
            onChanged: (value) => onVarChanged('code', value),
            decoration:
                InputDecoration(labelText: l10n.backupFormAuthCodeLabel),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: onStartOAuth,
              icon: const Icon(Icons.open_in_browser_outlined),
              label: Text(l10n.backupFormOpenAuthorizeAction),
            ),
          ),
        ],
        if (isAliyun) ...<Widget>[
          TextFormField(
            key: ValueKey<String>(
                'backup-aliyun-token-${draft.stringVar('token')}'),
            initialValue: draft.stringVar('token'),
            minLines: 3,
            maxLines: 6,
            onChanged: onAliyunTokenChanged,
            decoration:
                InputDecoration(labelText: l10n.backupFormTokenJsonLabel),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>(
                'backup-aliyun-drive-${draft.stringVar('drive_id')}'),
            initialValue: draft.stringVar('drive_id'),
            onChanged: (value) => onVarChanged('drive_id', value),
            decoration: InputDecoration(labelText: l10n.backupFormDriveIdLabel),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>(
                'backup-aliyun-refresh-${draft.stringVar('refresh_token')}'),
            initialValue: draft.stringVar('refresh_token'),
            onChanged: (value) => onVarChanged('refresh_token', value),
            decoration:
                InputDecoration(labelText: l10n.backupFormRefreshTokenLabel),
          ),
        ],
        if (type != 'OneDrive' &&
            type != 'GoogleDrive' &&
            type != 'ALIYUN' &&
            type != 'LOCAL')
          SwitchListTile(
            value: draft.rememberAuth,
            onChanged: (value) => onCommonChanged(rememberAuth: value),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.backupFormRememberCredentialsLabel),
          ),
      ],
    );
  }
}
