part of 'package:onepanel_client/features/files/files_page.dart';

extension _FilesViewSheets on _FilesViewState {
  void _showCreateOptions(BuildContext context) {
    final provider = context.read<FilesProvider>();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(context.l10n.filesActionNewFolder),
              onTap: () {
                Navigator.pop(sheetContext);
                showCreateDirectoryDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: Text(context.l10n.filesActionNewFile),
              onTap: () {
                Navigator.pop(sheetContext);
                showCreateFileDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(context.l10n.filesActionUpload),
              onTap: () {
                Navigator.pop(sheetContext);
                showUploadDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: Text(context.l10n.filesActionWgetDownload),
              onTap: () {
                Navigator.pop(sheetContext);
                showWgetDialog(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    final provider = context.read<FilesProvider>();
    final transferManager = context.read<TransferManager>();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Stack(
                children: [
                  const Icon(Icons.swap_vert),
                  if (transferManager.activeCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(sheetContext).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${transferManager.activeCount}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(sheetContext).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(sheetContext.l10n.transferManagerTitle),
              onTap: () {
                Navigator.pop(sheetContext);
                _openTransferManager(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(sheetContext.l10n.filesFavorites),
              onTap: () {
                Navigator.pop(sheetContext);
                _openFavorites(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: Text(sheetContext.l10n.filesActionSort),
              onTap: () {
                Navigator.pop(sheetContext);
                showSortOptionsDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(sheetContext.l10n.filesActionSearch),
              onTap: () {
                Navigator.pop(sheetContext);
                showSearchDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(sheetContext.l10n.filesUploadHistory),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: provider,
                      child: const UploadHistoryPage(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: Text(sheetContext.l10n.filesMounts),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: provider,
                      child: const MountsPage(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(sheetContext.l10n.filesRecycleBin),
              onTap: () {
                Navigator.pop(sheetContext);
                _openRecycleBin(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openTransferManager(BuildContext context) {
    appLogger.dWithPackage('files_page', '_openTransferManager: 打开传输管理器页面');
    final provider = context.read<FilesProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: provider,
          child: const TransferManagerPage(),
        ),
      ),
    );
  }

  void _openFavorites(BuildContext context, FilesProvider provider) async {
    appLogger.dWithPackage('files_page', '_openFavorites: 打开收藏夹页面');
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: provider,
          child: const FavoritesPage(),
        ),
      ),
    );

    if (result != null && mounted) {
      appLogger.dWithPackage('files_page', '_openFavorites: 导航到路径=$result');
      provider.navigateTo(result);
    }
  }

  void _openRecycleBin(BuildContext context) {
    appLogger.dWithPackage('files_page', '_openRecycleBin: 打开回收站页面');
    final provider = context.read<FilesProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: provider,
          child: const RecycleBinPage(),
        ),
      ),
    );
  }
}
