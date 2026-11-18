import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';

void showDeleteConfirmDialog(
  BuildContext context,
  FilesProvider provider,
  AppLocalizations l10n, {
  FileInfo? file,
}) {
  showAppFormDialog(
    context,
    title: l10n.filesDeleteTitle,
    confirmLabel: l10n.commonDelete,
    destructive: true,
    content: Text(
      file?.path ?? l10n.filesDeleteConfirm(provider.data.selectionCount),
    ),
    onConfirm: () async {
      appLogger.dWithPackage(
          'delete_confirm_dialog', 'showDeleteConfirmDialog: 用户确认删除');
      try {
        if (file == null) {
          await provider.deleteSelected();
        } else {
          await provider.deleteFile(file.path, isDir: file.isDir);
        }
        appLogger.iWithPackage(
            'delete_confirm_dialog', 'showDeleteConfirmDialog: 删除成功');
      } catch (e, stackTrace) {
        appLogger.eWithPackage(
            'delete_confirm_dialog', 'showDeleteConfirmDialog: 删除失败',
            error: e, stackTrace: stackTrace);
        if (context.mounted) {
          SnackBarUtils.showErrorWithDebugDetails(
              context, l10n.filesDeleteFailed,
              error: e, stackTrace: stackTrace);
        }
        rethrow;
      }
    },
  );
}
