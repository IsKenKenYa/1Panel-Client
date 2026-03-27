import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';

class BackupRecoverDatabaseFieldsWidget extends StatelessWidget {
  const BackupRecoverDatabaseFieldsWidget({
    super.key,
    required this.databaseType,
    required this.databaseItems,
    required this.resourceDetailName,
    required this.onDatabaseTypeChanged,
    required this.onDatabaseItemSelected,
  });

  final String databaseType;
  final List<DatabaseItemOption> databaseItems;
  final String resourceDetailName;
  final ValueChanged<String> onDatabaseTypeChanged;
  final ValueChanged<DatabaseItemOption> onDatabaseItemSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: databaseType,
          decoration:
              InputDecoration(labelText: l10n.backupRecoverDatabaseTypeLabel),
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem(
              value: 'mysql',
              child: Text(l10n.databaseTypeMysql),
            ),
            DropdownMenuItem(
              value: 'postgresql',
              child: Text(l10n.databaseTypePostgresql),
            ),
            DropdownMenuItem(
              value: 'redis',
              child: Text(l10n.databaseTypeRedis),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onDatabaseTypeChanged(value);
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: resourceDetailName.isEmpty ? null : resourceDetailName,
          decoration:
              InputDecoration(labelText: l10n.backupRecoverDatabaseItemLabel),
          items: databaseItems
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.name,
                  child: Text('${item.name} (${item.database})'),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            final item = databaseItems.firstWhere(
              (candidate) => candidate.name == value,
            );
            onDatabaseItemSelected(item);
          },
        ),
      ],
    );
  }
}
