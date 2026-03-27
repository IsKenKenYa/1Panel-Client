import 'package:flutter/material.dart';

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
    return Column(
      children: <Widget>[
        TextFormField(
          key: ValueKey<String>('backup-name-$name'),
          initialValue: name,
          onChanged: onNameChanged,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: isPublic,
          onChanged: onPublicChanged,
          contentPadding: EdgeInsets.zero,
          title: const Text('Public scope'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: providerType,
          decoration: const InputDecoration(labelText: 'Provider type'),
          items: providerTypes
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
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
