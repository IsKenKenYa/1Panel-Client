import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import '../../../data/models/container_models.dart';

class ComposeCreateDialog extends StatefulWidget {
  const ComposeCreateDialog({super.key});

  @override
  State<ComposeCreateDialog> createState() => _ComposeCreateDialogState();
}

class _ComposeCreateDialogState extends State<ComposeCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _pathController = TextEditingController();
  final _envController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _pathController.dispose();
    _envController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.orchestrationComposeCreateTitle),
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
              TextFormField(
                controller: _pathController,
                decoration: InputDecoration(
                  labelText: l10n.commonPath,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: l10n.orchestrationComposeContentLabel,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: l10n.orchestrationComposeContentHint,
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.serverFormRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _envController,
                decoration: InputDecoration(
                  labelText: l10n.env,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
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
              final request = ContainerComposeCreate(
                from: 'edit',
                name: _nameController.text,
                path:
                    _pathController.text.isEmpty ? null : _pathController.text,
                file: _contentController.text,
                env: _envController.text.isEmpty ? null : _envController.text,
              );
              Navigator.of(context).pop(request);
            }
          },
          child: Text(l10n.commonCreate),
        ),
      ],
    );
  }
}
