import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/debug_error_dialog.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/path_selector_dialog.dart';

void showMoveDialog(
  BuildContext context,
  FilesProvider provider,
  FileInfo file,
  AppLocalizations l10n,
) {
  appLogger.dWithPackage('move_dialog', 'showMoveDialog: 打开移动对话框, file=${file.path}');
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
            '${l10n.filesNameLabel}: ${file.name}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.filesTargetPath,
              prefixIcon: const Icon(Icons.folder_outlined),
              suffixIcon: IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: () async {
                  final selectedPath = await showPathSelectorDialog(context, provider, controller.text, l10n);
                  if (selectedPath != null) {
                    controller.text = selectedPath;
                  }
                },
                tooltip: l10n.filesSelectPath,
              ),
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
            appLogger.dWithPackage('move_dialog', 'showMoveDialog: 用户选择目标路径=${controller.text}');
            Navigator.pop(dialogContext);
            try {
              await provider.moveFile(file.path, controller.text);
              appLogger.iWithPackage('move_dialog', 'showMoveDialog: 移动成功');
            } catch (e, stackTrace) {
              appLogger.eWithPackage('move_dialog', 'showMoveDialog: 移动失败', error: e, stackTrace: stackTrace);
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
