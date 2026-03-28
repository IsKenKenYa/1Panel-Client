import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class ImageCardPrompts {
  static Future<String?> showTextInputDialog(
    BuildContext context, {
    required String title,
    required String label,
  }) {
    final l10n = context.l10n;
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showDeleteDialog(BuildContext context) async {
    final l10n = context.l10n;
    bool force = false;

    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.commonDelete),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.commonDeleteConfirm),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: force,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => force = value ?? false),
                title: Text(l10n.aiForceDelete),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, force),
              child: Text(l10n.commonDelete),
            ),
          ],
        ),
      ),
    );
  }
}
