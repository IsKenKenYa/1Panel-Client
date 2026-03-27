import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/i18n/backup_l10n_helper.dart';

class BackupAccountFormBasicSectionWidget extends StatelessWidget {
  const BackupAccountFormBasicSectionWidget({
    super.key,
    required this.name,
    required this.isPublic,
    required this.providerType,
    required this.providerTypes,
    required this.onNameChanged,
    required this.onPublicChanged,
    required this.onProviderChanged,
  });

  final String name;
  final bool isPublic;
  final String providerType;
  final List<String> providerTypes;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<bool> onPublicChanged;
  final ValueChanged<String> onProviderChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        TextFormField(
          key: ValueKey<String>('backup-name-$name'),
          initialValue: name,
          onChanged: onNameChanged,
          decoration: InputDecoration(labelText: l10n.commonName),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: isPublic,
          onChanged: onPublicChanged,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.backupFormPublicScopeLabel),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: providerType,
          decoration:
              InputDecoration(labelText: l10n.backupFormProviderTypeLabel),
          items: providerTypes
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(backupProviderLabel(l10n, item)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              onProviderChanged(value);
            }
          },
        ),
      ],
    );
  }
}
