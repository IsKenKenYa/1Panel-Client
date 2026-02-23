import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/container_models.dart';
import 'package:onepanelapp_app/features/containers/containers_provider.dart';

class TemplateCreateDialog extends StatefulWidget {
  final ContainerTemplate? template;

  const TemplateCreateDialog({super.key, this.template});

  @override
  State<TemplateCreateDialog> createState() => _TemplateCreateDialogState();
}

class _TemplateCreateDialogState extends State<TemplateCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _descriptionController = TextEditingController(text: widget.template?.description ?? '');
    _contentController = TextEditingController(text: widget.template?.content ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.template != null;

    return AlertDialog(
      title: Text(isEdit ? l10n.commonEditTemplate : l10n.orchestrationCreateTemplate),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
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
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.commonDescription,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: l10n.commonContent,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                    hintText: 'YAML content',
                  ),
                  maxLines: 15,
                  style: const TextStyle(fontFamily: 'monospace'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.serverFormRequired;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final request = ContainerTemplateOperate(
                id: widget.template?.id,
                name: _nameController.text,
                description: _descriptionController.text,
                content: _contentController.text,
              );

              final provider = context.read<ContainersProvider>();
              final success = isEdit
                  ? await provider.updateTemplate(request)
                  : await provider.createTemplate(request);

              if (success && mounted) {
                Navigator.pop(context, true);
              }
            }
          },
          child: Text(l10n.commonConfirm),
        ),
      ],
    );
  }
}
