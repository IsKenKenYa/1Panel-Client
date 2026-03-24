import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/debug_error_dialog.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

void showDeleteConfirmDialog(
  BuildContext context,
  FilesProvider provider,
  AppLocalizations l10n,
) {
  appLogger.dWithPackage('delete_confirm_dialog', 'showDeleteConfirmDialog: 打开删除确认对话框, 选中${provider.data.selectionCount}个文件');
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.filesDeleteTitle),
      content: Text(l10n.filesDeleteConfirm(provider.data.selectionCount)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            appLogger.dWithPackage('delete_confirm_dialog', 'showDeleteConfirmDialog: 用户确认删除');
            Navigator.pop(dialogContext);
            try {
              await provider.deleteSelected();
              appLogger.iWithPackage('delete_confirm_dialog', 'showDeleteConfirmDialog: 删除成功');
            } catch (e, stackTrace) {
              appLogger.eWithPackage('delete_confirm_dialog', 'showDeleteConfirmDialog: 删除失败', error: e, stackTrace: stackTrace);
              if (context.mounted) {
                DebugErrorDialog.show(context, l10n.filesDeleteFailed, e, stackTrace: stackTrace);
              }
            }
          },
          child: Text(l10n.commonDelete),
        ),
      ],
    ),
  );
}
