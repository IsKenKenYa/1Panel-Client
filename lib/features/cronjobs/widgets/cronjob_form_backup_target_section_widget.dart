import 'package:flutter/material.dart';

import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';

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
    return Column(
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: backupType,
          decoration: const InputDecoration(labelText: 'Backup type'),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem(value: 'app', child: Text('App')),
            DropdownMenuItem(value: 'website', child: Text('Website')),
            DropdownMenuItem(value: 'database', child: Text('Database')),
            DropdownMenuItem(value: 'directory', child: Text('Directory')),
            DropdownMenuItem(value: 'snapshot', child: Text('Snapshot')),
            DropdownMenuItem(value: 'log', child: Text('Logs')),
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
            label: 'Apps',
            options: appOptions
                .map((item) =>
                    _ChipItem(item.id?.toString() ?? '', item.name ?? ''))
                .toList(growable: false),
            selectedValues: selectedAppIds,
            onChanged: onAppIdsChanged,
          ),
        if (backupType == 'website')
          _ChipSelector(
            label: 'Websites',
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
            decoration: const InputDecoration(labelText: 'Database type'),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem(value: 'mysql', child: Text('MySQL')),
              DropdownMenuItem(
                  value: 'mysql-cluster', child: Text('MySQL Cluster')),
              DropdownMenuItem(value: 'mariadb', child: Text('MariaDB')),
              DropdownMenuItem(value: 'postgresql', child: Text('PostgreSQL')),
              DropdownMenuItem(
                  value: 'postgresql-cluster',
                  child: Text('PostgreSQL Cluster')),
            ],
            onChanged: (value) {
              if (value != null) {
                onDatabaseTypeChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          _ChipSelector(
            label: 'Databases',
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
            decoration: const InputDecoration(labelText: 'Backup args'),
          ),
        ],
        if (backupType == 'directory') ...<Widget>[
          SwitchListTile(
            value: isDir,
            onChanged: (value) => onDirectoryChanged(isDir: value),
            contentPadding: EdgeInsets.zero,
            title: const Text('Backup directory'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>('backup-dir-$sourceDir'),
            initialValue: sourceDir,
            onChanged: (value) => onDirectoryChanged(sourceDir: value),
            decoration: InputDecoration(
              labelText: isDir ? 'Directory path' : 'Selected files',
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
            decoration: const InputDecoration(labelText: 'Exclude patterns'),
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
            title: const Text('Include images'),
          ),
          _ChipSelector(
            label: 'Ignore apps',
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
          label: 'Source accounts',
          options: backupOptions
              .where((item) => item.id != 0)
              .map(
                (item) => _ChipItem(
                  item.id.toString(),
                  '${item.type} · ${item.name}',
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
          decoration: const InputDecoration(labelText: 'Default download path'),
          items: backupOptions
              .where((item) => sourceAccountItems.contains(item.id))
              .map(
                (item) => DropdownMenuItem<int>(
                  value: item.id,
                  child: Text('${item.type} · ${item.name}'),
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
          decoration: const InputDecoration(labelText: 'Secret'),
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
