import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/platform/services/platform_file_service.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

void showUploadDialog(BuildContext context, FilesProvider provider) async {
  appLogger.dWithPackage('upload_dialog', 'showUploadDialog: 打开上传对话框');
  final l10n = context.l10n;
  final targetPath = provider.data.currentPath;

  final confirmed = await ConfirmActionSheetWidget.show(
    context,
    title: l10n.filesActionUpload,
    message: '${l10n.filesTargetPath}: $targetPath',
    confirmLabel: l10n.filesActionUpload,
    confirmIcon: Icons.upload_outlined,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  try {
    final result = await PlatformFileService().selectFiles(
      allowMultiple: true,
      withReadStream: kIsWeb,
    );

    if (result != null && result.files.isNotEmpty) {
      if (kIsWeb) {
        for (final file in result.files) {
          final stream = file.readStream;
          if (stream == null) {
            throw StateError('无法读取文件数据流');
          }
          await provider.uploadPickedFile(
            file.name,
            stream,
            file.size,
            targetPath: targetPath,
          );
        }
        return;
      }
      final filePaths = result.files
          .where((f) => f.path != null)
          .map((f) => f.path!)
          .toList();

      if (filePaths.isNotEmpty) {
        appLogger.dWithPackage(
          'upload_dialog',
          'showUploadDialog: 选择${filePaths.length}个文件',
        );
        await provider.uploadFiles(filePaths, targetPath: targetPath);
        appLogger.iWithPackage('upload_dialog', 'showUploadDialog: 上传成功');
      }
    }
  } catch (e, stackTrace) {
    appLogger.eWithPackage(
      'upload_dialog',
      'showUploadDialog: 上传失败',
      error: e,
      stackTrace: stackTrace,
    );
    if (context.mounted) {
      SnackBarUtils.showErrorWithDebugDetails(
        context,
        l10n.filesCreateFailed,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
