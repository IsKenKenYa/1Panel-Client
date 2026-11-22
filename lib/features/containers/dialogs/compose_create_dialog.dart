import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/files/files_service.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/server_directory_picker_dialog.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';
import '../../../data/models/container_models.dart';
import 'container_form_fields.dart';

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

  /// 路径字段旁的浏览按钮：列出服务器目录供点选，避免手工输入出错。
  Future<void> _pickServerDirectory() async {
    final selected = await ServerDirectoryPickerDialog.show(
      context,
      filesService: FilesService(),
      initialPath: _pathController.text.trim().isEmpty
          ? '/'
          : _pathController.text.trim(),
    );
    if (selected == null || !mounted) return;
    _pathController.text = selected;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.orchestrationComposeCreateTitle,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ContainerNameField(controller: _nameController),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pathController,
                decoration: InputDecoration(
                  labelText: l10n.commonPath,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: l10n.commonBrowseServerDirectory,
                    icon: const Icon(Icons.folder_open_outlined),
                    onPressed: _pickServerDirectory,
                  ),
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
      confirmLabel: l10n.commonCreate,
      onConfirm: () async {
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
    );
  }
}
