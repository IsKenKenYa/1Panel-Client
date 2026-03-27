import 'package:flutter/material.dart';

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'app', child: Text('App')),
                DropdownMenuItem(value: 'website', child: Text('Website')),
                DropdownMenuItem(value: 'mysql', child: Text('MySQL')),
                DropdownMenuItem(
                    value: 'postgresql', child: Text('PostgreSQL')),
                DropdownMenuItem(value: 'redis', child: Text('Redis')),
                DropdownMenuItem(value: 'directory', child: Text('Directory')),
                DropdownMenuItem(value: 'snapshot', child: Text('Snapshot')),
                DropdownMenuItem(value: 'log', child: Text('Log')),
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
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailNameController,
              decoration: const InputDecoration(labelText: 'Detail name'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(<String, String>{
                'type': _type,
                'name': _nameController.text,
                'detailName': _detailNameController.text,
              }),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
