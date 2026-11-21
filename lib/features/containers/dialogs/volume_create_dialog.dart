import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';
import 'container_form_fields.dart';

class VolumeCreateDialog extends StatefulWidget {
  const VolumeCreateDialog({super.key});

  @override
  State<VolumeCreateDialog> createState() => _VolumeCreateDialogState();
}

class _VolumeCreateDialogState extends State<VolumeCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _labelsController = TextEditingController();
  final _optionsController = TextEditingController();

  final List<String> _drivers = ['local'];
  String _selectedDriver = 'local';

  @override
  void dispose() {
    _nameController.dispose();
    _labelsController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.orchestrationCreateVolume,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ContainerNameField(controller: _nameController),
              const SizedBox(height: 16),
              ContainerDriverField(
                selected: _selectedDriver,
                drivers: _drivers,
                onChanged: (driver) => setState(() => _selectedDriver = driver),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelsController,
                decoration: InputDecoration(
                  labelText: l10n.volumeFormLabels,
                  hintText: l10n.volumeFormLabelsHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _optionsController,
                decoration: InputDecoration(
                  labelText: l10n.volumeFormOptions,
                  hintText: l10n.volumeFormOptionsHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      confirmLabel: l10n.commonCreate,
      onConfirm: () async {
        if (_formKey.currentState!.validate()) {
          Navigator.of(context).pop({
            'name': _nameController.text,
            'driver': _selectedDriver,
            'labels': _labelsController.text,
            'options': _optionsController.text,
          });
        }
      },
    );
  }
}
