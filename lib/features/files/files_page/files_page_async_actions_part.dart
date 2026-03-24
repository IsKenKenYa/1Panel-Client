part of 'package:onepanel_client/features/files/files_page.dart';

extension _FilesViewAsyncActions on _FilesViewState {
  void _startDownload(
    BuildContext context,
    FilesProvider provider,
    FileInfo file,
    AppLocalizations l10n,
  ) {
    appLogger.dWithPackage('files_page', '_startDownload: 开始下载 ${file.name}');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ListenableBuilder(
          listenable: provider,
          builder: (context, _) {
            if (provider.data.isDownloading) {
              final progress = (provider.data.downloadProgress * 100).toInt();
              return Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.filesDownloadProgress(progress))),
                ],
              );
            }
            return Text(l10n.filesDownloadSuccess);
          },
        ),
        duration: const Duration(seconds: 30),
        action: SnackBarAction(
          label: l10n.commonCancel,
          onPressed: () {
            provider.cancelDownload();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );

    provider.downloadFile(file).then((savePath) {
      if (savePath != null && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.filesDownloadSuccess),
            action: SnackBarAction(
              label: l10n.commonConfirm,
              onPressed: () {},
            ),
          ),
        );
      }
    }).catchError((e, stackTrace) async {
      appLogger.eWithPackage(
        'files_page',
        '_startDownload: 下载失败',
        error: e,
        stackTrace: stackTrace,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      final errorMsg = e.toString();
      if (errorMsg.contains('cancelled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.filesDownloadCancelled)),
        );
      } else if (errorMsg.contains('storage_permission_denied')) {
        final isPermanentlyDenied =
            await provider.isStoragePermissionPermanentlyDenied();
        if (!context.mounted) return;
        if (isPermanentlyDenied) {
          _showPermissionSettingsDialog(context, l10n);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('存储权限被拒绝，无法下载文件'),
              action: SnackBarAction(
                label: '设置',
                onPressed: () => _showPermissionSettingsDialog(context, l10n),
              ),
            ),
          );
        }
      } else {
        DebugErrorDialog.show(
          context,
          l10n.filesDownloadFailed,
          e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  void _showPermissionSettingsDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('存储权限'),
        content: const Text('请在设置中授予存储权限以保存下载文件'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Permission.storage.request().then((_) {
                Permission.manageExternalStorage.request();
              });
            },
            child: const Text('打开设置'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    FilesProvider provider,
    FileInfo file,
    AppLocalizations l10n,
  ) async {
    appLogger.dWithPackage('files_page', '_toggleFavorite: path=${file.path}');
    final isFavorite = provider.data.isFavorite(file.path);

    if (isFavorite) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.filesFavoritesAdded)),
        );
      }
      return;
    }

    try {
      await provider.addToFavorites(file);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.filesFavoritesAdded)),
        );
      }
    } on DioException catch (e) {
      appLogger.eWithPackage('files_page', '_toggleFavorite: 失败', error: e);
      if (!context.mounted) return;
      final errorMsg = e.response?.data?.toString() ?? e.message ?? '';
      if (errorMsg.contains('已收藏') || errorMsg.contains('already')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.filesFavoritesAdded)),
        );
      } else {
        DebugErrorDialog.show(context, l10n.filesFavoritesLoadFailed, e);
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'files_page',
        '_toggleFavorite: 失败',
        error: e,
        stackTrace: stackTrace,
      );
      if (!context.mounted) return;
      final errorMsg = e.toString();
      if (errorMsg.contains('已收藏') || errorMsg.contains('already')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.filesFavoritesAdded)),
        );
      } else {
        DebugErrorDialog.show(
          context,
          l10n.filesFavoritesLoadFailed,
          e,
          stackTrace: stackTrace,
        );
      }
    }
  }
}
