import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';
import 'package:onepanel_client/shared/i18n/backup_l10n_helper.dart';

class CronjobFormBackupTargetSectionWidget extends StatelessWidget {
  const CronjobFormBackupTargetSectionWidget({
    super.key,
    required this.backupType,
    required this.backupOptions,
    required this.appOptions,
    required this.websiteOptions,
    required this.databaseType,
    required this.databaseItems,
    required this.selectedAppIds,
    required this.selectedWebsiteIds,
    required this.selectedDatabaseIds,
    required this.isDir,
    required this.sourceDir,
    required this.files,
    required this.ignoreFiles,
    required this.withImage,
    required this.ignoreAppIDs,
    required this.sourceAccountItems,
    required this.downloadAccountID,
    required this.secret,
    required this.argItems,
    required this.onBackupTypeChanged,
    required this.onAppIdsChanged,
    required this.onWebsiteIdsChanged,
    required this.onDatabaseTypeChanged,
    required this.onDatabaseIdsChanged,
    required this.onDirectoryChanged,
    required this.onSnapshotChanged,
    required this.onAccountsChanged,
    required this.onPolicyChanged,
  });

  final String backupType;
  final List<BackupOption> backupOptions;
  final List<AppInstallInfo> appOptions;
  final List<Map<String, dynamic>> websiteOptions;
  final String databaseType;
  final List<DatabaseItemOption> databaseItems;
  final List<String> selectedAppIds;
  final List<String> selectedWebsiteIds;
  final List<String> selectedDatabaseIds;
  final bool isDir;
  final String sourceDir;
  final List<String> files;
  final List<String> ignoreFiles;
  final bool withImage;
  final List<int> ignoreAppIDs;
  final List<int> sourceAccountItems;
  final int? downloadAccountID;
  final String secret;
  final List<String> argItems;
  final ValueChanged<String> onBackupTypeChanged;
  final ValueChanged<List<String>> onAppIdsChanged;
  final ValueChanged<List<String>> onWebsiteIdsChanged;
  final ValueChanged<String> onDatabaseTypeChanged;
  final ValueChanged<List<String>> onDatabaseIdsChanged;
  final void Function({
    bool? isDir,
    String? sourceDir,
    List<String>? files,
    List<String>? ignoreFiles,
  }) onDirectoryChanged;
  final void Function({
    bool? withImage,
    List<int>? ignoreAppIDs,
  }) onSnapshotChanged;
  final void Function({
    List<int>? sourceAccountItems,
    int? downloadAccountID,
  }) onAccountsChanged;
  final void Function({
    String? secret,
    List<String>? argItems,
  }) onPolicyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: backupType,
          decoration:
              InputDecoration(labelText: l10n.cronjobFormBackupTypeLabel),
          items: <DropdownMenuItem<String>>[
            for (final item in const <String>[
              'app',
              'website',
              'database',
              'directory',
              'snapshot',
              'log',
            ])
              DropdownMenuItem<String>(
                value: item,
                child: Text(backupResourceTypeLabel(l10n, item)),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              onBackupTypeChanged(value);
            }
          },
        ),
        const SizedBox(height: 12),
        if (backupType == 'app')
          _ChipSelector(
            label: l10n.cronjobFormAppsLabel,
            options: appOptions
                .map((item) =>
                    _ChipItem(item.id?.toString() ?? '', item.name ?? ''))
                .toList(growable: false),
            selectedValues: selectedAppIds,
            onChanged: onAppIdsChanged,
          ),
        if (backupType == 'website')
          _ChipSelector(
            label: l10n.cronjobFormWebsitesLabel,
            options: websiteOptions
                .map(
                  (item) => _ChipItem(
                    item['id']?.toString() ?? '',
                    item['primaryDomain']?.toString() ??
                        item['alias']?.toString() ??
                        '',
                  ),
                )
                .toList(growable: false),
            selectedValues: selectedWebsiteIds,
            onChanged: onWebsiteIdsChanged,
          ),
        if (backupType == 'database') ...<Widget>[
          DropdownButtonFormField<String>(
            initialValue: databaseType,
            decoration:
                InputDecoration(labelText: l10n.cronjobFormDatabaseTypeLabel),
            items: <DropdownMenuItem<String>>[
              for (final item in const <String>[
                'mysql',
                'mysql-cluster',
                'mariadb',
                'postgresql',
                'postgresql-cluster',
              ])
                DropdownMenuItem<String>(
                  value: item,
                  child: Text(backupResourceTypeLabel(l10n, item)),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                onDatabaseTypeChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          _ChipSelector(
            label: l10n.cronjobFormDatabasesLabel,
            options: databaseItems
                .map(
                  (item) => _ChipItem(
                    item.id.toString(),
                    '${item.name} (${item.database})',
                  ),
                )
                .toList(growable: false),
            selectedValues: selectedDatabaseIds,
            onChanged: onDatabaseIdsChanged,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>('backup-db-args-${argItems.join(",")}'),
            initialValue: argItems.join(','),
            onChanged: (value) => onPolicyChanged(
              argItems: value
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toList(growable: false),
            ),
            decoration:
                InputDecoration(labelText: l10n.cronjobFormBackupArgsLabel),
          ),
        ],
        if (backupType == 'directory') ...<Widget>[
          SwitchListTile(
            value: isDir,
            onChanged: (value) => onDirectoryChanged(isDir: value),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.cronjobFormBackupDirectoryLabel),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>('backup-dir-$sourceDir'),
            initialValue: sourceDir,
            onChanged: (value) => onDirectoryChanged(sourceDir: value),
            decoration: InputDecoration(
              labelText: isDir
                  ? l10n.cronjobFormDirectoryPathLabel
                  : l10n.cronjobFormSelectedFilesLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>('backup-ignore-${ignoreFiles.join(",")}'),
            initialValue: ignoreFiles.join(','),
            onChanged: (value) => onDirectoryChanged(
              ignoreFiles: value
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toList(growable: false),
            ),
            decoration: InputDecoration(
                labelText: l10n.cronjobFormExcludePatternsLabel),
          ),
          if (!isDir && files.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            ...files.map((item) => ListTile(title: Text(item))),
          ],
        ],
        if (backupType == 'snapshot') ...<Widget>[
          SwitchListTile(
            value: withImage,
            onChanged: (value) => onSnapshotChanged(withImage: value),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.cronjobFormIncludeImagesLabel),
          ),
          _ChipSelector(
            label: l10n.cronjobFormIgnoreAppsLabel,
            options: appOptions
                .where((item) => item.id != null)
                .map(
                  (item) => _ChipItem(item.id!.toString(), item.name ?? ''),
                )
                .toList(growable: false),
            selectedValues: ignoreAppIDs
                .map((item) => item.toString())
                .toList(growable: false),
            onChanged: (values) => onSnapshotChanged(
              ignoreAppIDs: values
                  .map((item) => int.tryParse(item))
                  .whereType<int>()
                  .toList(growable: false),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _ChipSelector(
          label: l10n.cronjobFormSourceAccountsLabel,
          options: backupOptions
              .where((item) => item.id != 0)
              .map(
                (item) => _ChipItem(
                  item.id.toString(),
                  '${backupProviderLabel(l10n, item.type)} · ${item.name}',
                ),
              )
              .toList(growable: false),
          selectedValues: sourceAccountItems
              .map((item) => item.toString())
              .toList(growable: false),
          onChanged: (values) => onAccountsChanged(
            sourceAccountItems: values
                .map((item) => int.tryParse(item))
                .whereType<int>()
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: downloadAccountID,
          decoration:
              InputDecoration(labelText: l10n.cronjobFormDownloadAccountLabel),
          items: backupOptions
              .where((item) => sourceAccountItems.contains(item.id))
              .map(
                (item) => DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(
                      '${backupProviderLabel(l10n, item.type)} · ${item.name}'),
                ),
              )
              .toList(growable: false),
          onChanged: (value) => onAccountsChanged(downloadAccountID: value),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey<String>('backup-secret-$secret'),
          initialValue: secret,
          onChanged: (value) => onPolicyChanged(secret: value),
          decoration: InputDecoration(labelText: l10n.cronjobFormSecretLabel),
        ),
      ],
    );
  }
}

class _ChipItem {
  const _ChipItem(this.value, this.label);

  final String value;
  final String label;
}

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
  });

  final String label;
  final List<_ChipItem> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((item) {
          final selected = selectedValues.contains(item.value);
          return FilterChip(
            label: Text(item.label),
            selected: selected,
            onSelected: (value) {
              final values = List<String>.from(selectedValues);
              if (value) {
                values.add(item.value);
              } else {
                values.remove(item.value);
              }
              onChanged(values.toSet().toList(growable: false));
            },
          );
        }).toList(growable: false),
      ),
    );
  }
}
