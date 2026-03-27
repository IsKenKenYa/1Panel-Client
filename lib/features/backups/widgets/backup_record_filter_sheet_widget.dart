import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/i18n/backup_l10n_helper.dart';

class BackupRecordFilterSheetWidget extends StatefulWidget {
  const BackupRecordFilterSheetWidget({
    super.key,
    required this.initialType,
    required this.initialName,
    required this.initialDetailName,
  });

  final String initialType;
  final String initialName;
  final String initialDetailName;

  @override
  State<BackupRecordFilterSheetWidget> createState() =>
      _BackupRecordFilterSheetWidgetState();
}

class _BackupRecordFilterSheetWidgetState
    extends State<BackupRecordFilterSheetWidget> {
  late String _type;
  late TextEditingController _nameController;
  late TextEditingController _detailNameController;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _nameController = TextEditingController(text: widget.initialName);
    _detailNameController =
        TextEditingController(text: widget.initialDetailName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration:
                  InputDecoration(labelText: l10n.backupRecordsTypeLabel),
              items: <DropdownMenuItem<String>>[
                for (final item in const <String>[
                  'app',
                  'website',
                  'mysql',
                  'postgresql',
                  'redis',
                  'directory',
                  'snapshot',
                  'log',
                ])
                  DropdownMenuItem(
                    value: item,
                    child: Text(backupResourceTypeLabel(l10n, item)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration:
                  InputDecoration(labelText: l10n.backupRecordsNameLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailNameController,
              decoration: InputDecoration(
                labelText: l10n.backupRecordsDetailNameLabel,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(<String, String>{
                'type': _type,
                'name': _nameController.text,
                'detailName': _detailNameController.text,
              }),
              child: Text(l10n.backupRecordsApplyAction),
            ),
          ],
        ),
      ),
    );
  }
}
