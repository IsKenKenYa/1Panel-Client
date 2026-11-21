import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';
import 'container_form_fields.dart';

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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.template?.description ?? '');
    _contentController =
        TextEditingController(text: widget.template?.content ?? '');
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
    final spec = AdaptiveLayoutSpec.of(context);

    return AppFormPanel(
      title:
          isEdit ? l10n.commonEditTemplate : l10n.orchestrationCreateTemplate,
      isSaving: _saving,
      content: SizedBox(
        width: spec.isDesktop ? spec.dialogConstraints.maxWidth : double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ContainerNameField(controller: _nameController),
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
                    hintText: l10n.containerTemplateContentHint,
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
      onConfirm: () async {
        if (!_formKey.currentState!.validate()) {
          return;
        }
        setState(() => _saving = true);
        final navigator = Navigator.of(context);
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

        if (!context.mounted) return;
        if (success) {
          navigator.pop(true);
        } else {
          setState(() => _saving = false);
        }
      },
    );
  }
}
