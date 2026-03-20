import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';

class VolumeCreateDialog extends StatefulWidget {
  const VolumeCreateDialog({super.key});

  @override
  State<VolumeCreateDialog> createState() => _VolumeCreateDialogState();
}

class _VolumeCreateDialogState extends State<VolumeCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  final List<String> _drivers = ['local'];
  String _selectedDriver = 'local';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.orchestrationCreateVolume),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.commonName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.serverFormRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedDriver,
                decoration: InputDecoration(
                  labelText: l10n.commonDriver,
                  border: const OutlineInputBorder(),
                ),
                items: _drivers.map((driver) {
                  return DropdownMenuItem(
                    value: driver,
                    child: Text(driver),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDriver = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text,
                'driver': _selectedDriver,
              });
            }
          },
          child: Text(l10n.commonCreate),
        ),
      ],
    );
  }
}
