import 'package:flutter/material.dart';

class CronjobFormBasicSectionWidget extends StatelessWidget {
  const CronjobFormBasicSectionWidget({
    super.key,
    required this.name,
    required this.groupLabel,
    required this.primaryType,
    required this.onNameChanged,
    required this.onPickGroup,
    required this.onPrimaryTypeChanged,
    required this.nameLabel,
    required this.groupLabelText,
    required this.typeLabel,
    required this.shellLabel,
    required this.urlLabel,
    required this.backupLabel,
  });

  final String name;
  final String groupLabel;
  final String primaryType;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onPickGroup;
  final ValueChanged<String> onPrimaryTypeChanged;
  final String nameLabel;
  final String groupLabelText;
  final String typeLabel;
  final String shellLabel;
  final String urlLabel;
  final String backupLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextFormField(
          key: ValueKey<String>('cronjob-name-$name'),
          initialValue: name,
          onChanged: onNameChanged,
          decoration: InputDecoration(labelText: nameLabel),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(groupLabelText),
          subtitle: Text(groupLabel),
          trailing: const Icon(Icons.chevron_right),
          onTap: onPickGroup,
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: InputDecoration(labelText: typeLabel),
          child: SegmentedButton<String>(
            segments: <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'shell', label: Text(shellLabel)),
              ButtonSegment<String>(value: 'curl', label: Text(urlLabel)),
              ButtonSegment<String>(value: 'backup', label: Text(backupLabel)),
            ],
            selected: <String>{primaryType},
            onSelectionChanged: (Set<String> values) {
              onPrimaryTypeChanged(values.first);
            },
          ),
        ),
      ],
    );
  }
}
