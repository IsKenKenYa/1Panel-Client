import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';

class ImageCardPrompts {
  static Future<String?> showTextInputDialog(
    BuildContext context, {
    required String title,
    required String label,
  }) {
    return showAppTextInputDialog(
      context,
      title: title,
      labelText: label,
      autofocus: false,
      trim: false,
      allowEmpty: true,
    );
  }

  static Future<bool?> showDeleteDialog(BuildContext context) async {
    final l10n = context.l10n;
    bool force = false;

    final confirmed = await showAppFormDialog(
      context,
      title: l10n.commonDelete,
      confirmLabel: l10n.commonDelete,
      destructive: true,
      content: StatefulBuilder(
        builder: (context, setState) => Column(
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
      ),
      onConfirm: () async {},
    );
    return confirmed ? force : null;
  }
}
