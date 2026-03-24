import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/debug_error_dialog.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

void showBatchMoveDialog(
  BuildContext context,
  FilesProvider provider,
  AppLocalizations l10n,
) {
  final controller = TextEditingController(text: provider.data.currentPath);
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.filesActionMove),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.filesSelected}: ${provider.data.selectionCount}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.filesTargetPath,
              prefixIcon: const Icon(Icons.folder_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            try {
              await provider.moveSelected(controller.text);
            } catch (e, stackTrace) {
              if (context.mounted) {
                DebugErrorDialog.show(context, l10n.filesMoveFailed, e, stackTrace: stackTrace);
              }
            }
          },
          child: Text(l10n.commonConfirm),
        ),
      ],
    ),
  );
}
