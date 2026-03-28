import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class PhpFileEditorSectionWidget extends StatelessWidget {
  const PhpFileEditorSectionWidget({
    super.key,
    required this.path,
    required this.contentController,
    required this.onContentChanged,
    required this.onSave,
    required this.isSaving,
  });

  final String path;
  final TextEditingController contentController;
  final ValueChanged<String> onContentChanged;
  final Future<void> Function() onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        TextFormField(
          initialValue: path,
          enabled: false,
          decoration: InputDecoration(labelText: l10n.commonPath),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: contentController,
          onChanged: onContentChanged,
          maxLines: 20,
          minLines: 10,
          decoration: InputDecoration(labelText: l10n.commonContent),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isSaving ? null : onSave,
          child: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.commonSave),
        ),
      ],
    );
  }
}
