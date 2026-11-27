import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';

/// 编排模版创建/编辑对话框。
/// 对齐 1Panel 前端 `container/template/operate/index.vue`：name/description/content。
/// 返回填写完成的请求；取消时返回 null。
Future<ContainerTemplateOperate?> showComposeTemplateEditDialog(
  BuildContext context, {
  ContainerTemplate? template,
}) {
  return showAdaptiveFormPanel<ContainerTemplateOperate>(
    context,
    builder: (_) => _ComposeTemplateForm(template: template),
  );
}

class _ComposeTemplateForm extends StatefulWidget {
  const _ComposeTemplateForm({this.template});

  final ContainerTemplate? template;

  @override
  State<_ComposeTemplateForm> createState() => _ComposeTemplateFormState();
}

class _ComposeTemplateFormState extends State<_ComposeTemplateForm> {
  late final _nameController = TextEditingController(
    text: widget.template?.name ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.template?.description ?? '',
  );
  late final _contentController = TextEditingController(
    text: widget.template?.content ?? '',
  );

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
    return AppFormPanel(
      title: widget.template == null
          ? l10n.composeTemplateCreate
          : l10n.composeTemplateEdit,
      confirmLabel: l10n.commonSave,
      content: SizedBox(
        width: AdaptiveLayoutSpec.of(context).dialogConstraints.maxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.commonName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.commonDescription,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 10,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                labelText: l10n.composeTemplateContent,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      onConfirm: () async {
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          SnackBarUtils.showError(context, l10n.composeTemplateNameRequired);
          return;
        }
        Navigator.of(context).pop(
          ContainerTemplateOperate(
            id: widget.template?.id,
            name: name,
            description: _descriptionController.text.trim(),
            content: _contentController.text,
          ),
        );
      },
    );
  }
}
