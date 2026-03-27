import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/backups/providers/backup_recover_provider.dart';
import 'package:onepanel_client/features/backups/widgets/backup_recover_database_fields_widget.dart';
import 'package:onepanel_client/features/backups/widgets/backup_recover_unsupported_type_card_widget.dart';
import 'package:onepanel_client/shared/i18n/backup_l10n_helper.dart';

class BackupRecoverResourceStepWidget extends StatelessWidget {
  const BackupRecoverResourceStepWidget({
    super.key,
    required this.provider,
  });

  final BackupRecoverProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final otherTypes = <String>{
      'directory',
      'snapshot',
      'log',
      if (provider.resourceType == 'other') provider.recordType,
    }.where((item) => item.isNotEmpty).toList(growable: false);
    return Column(
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: provider.resourceType,
          decoration: InputDecoration(labelText: l10n.backupRecoverTypeLabel),
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem(
              value: 'app',
              child: Text(l10n.backupRecoverAppLabel),
            ),
            DropdownMenuItem(
              value: 'website',
              child: Text(l10n.backupRecoverWebsiteLabel),
            ),
            DropdownMenuItem(
              value: 'database',
              child: Text(l10n.backupRecoverDatabaseLabel),
            ),
            DropdownMenuItem(
              value: 'other',
              child: Text(l10n.backupRecoverOtherLabel),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              provider.updateResourceType(value);
            }
          },
        ),
        const SizedBox(height: 12),
        if (provider.resourceType == 'app') _AppField(provider: provider),
        if (provider.resourceType == 'website')
          _WebsiteField(provider: provider),
        if (provider.resourceType == 'database')
          BackupRecoverDatabaseFieldsWidget(
            databaseType: provider.databaseType,
            databaseItems: provider.databaseItems,
            resourceDetailName: provider.resourceDetailName,
            onDatabaseTypeChanged: provider.updateDatabaseType,
            onDatabaseItemSelected: provider.selectDatabaseItem,
          ),
        if (provider.resourceType == 'other')
          Column(
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: provider.recordType,
                decoration: InputDecoration(
                  labelText: l10n.backupRecoverSourceTypeLabel,
                ),
                items: otherTypes
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(backupResourceTypeLabel(l10n, item)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    provider.updateOtherType(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey<String>(
                  'backup-recover-name-${provider.resourceName}',
                ),
                initialValue: provider.resourceName,
                onChanged: provider.updateResourceName,
                decoration: InputDecoration(
                  labelText: l10n.backupRecordsNameLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey<String>(
                  'backup-recover-detail-${provider.resourceDetailName}',
                ),
                initialValue: provider.resourceDetailName,
                onChanged: provider.updateResourceDetailName,
                decoration: InputDecoration(
                  labelText: l10n.backupRecordsDetailNameLabel,
                ),
              ),
              if (!provider.supportsRecoverAction)
                BackupRecoverUnsupportedTypeCardWidget(
                  typeLabel: backupResourceTypeLabel(
                    l10n,
                    provider.recordType,
                  ),
                  name: provider.resourceName,
                  detailName: provider.resourceDetailName,
                ),
            ],
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonal(
            onPressed:
                provider.hasResourceSelection ? provider.loadRecords : null,
            child: Text(l10n.backupRecoverLoadRecordsAction),
          ),
        ),
      ],
    );
  }
}

class _AppField extends StatelessWidget {
  const _AppField({required this.provider});

  final BackupRecoverProvider provider;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue:
          provider.resourceName.isEmpty ? null : provider.resourceName,
      decoration:
          InputDecoration(labelText: context.l10n.backupRecoverAppLabel),
      items: provider.apps
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.appKey,
              child: Text(item.name ?? ''),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        final item = provider.apps.firstWhere(
          (candidate) => candidate.appKey == value,
        );
        provider.selectApp(item);
      },
    );
  }
}

class _WebsiteField extends StatelessWidget {
  const _WebsiteField({required this.provider});

  final BackupRecoverProvider provider;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue:
          provider.resourceName.isEmpty ? null : provider.resourceName,
      decoration:
          InputDecoration(labelText: context.l10n.backupRecoverWebsiteLabel),
      items: provider.websites
          .map(
            (item) => DropdownMenuItem<String>(
              value: item['alias']?.toString(),
              child: Text(
                item['primaryDomain']?.toString() ??
                    item['alias']?.toString() ??
                    '',
              ),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        final item = provider.websites.firstWhere(
          (candidate) => candidate['alias']?.toString() == value,
        );
        provider.selectWebsite(item);
      },
    );
  }
}
