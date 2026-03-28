import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

Future<String?> showPathSelectorDialog(
  BuildContext context,
  FilesProvider provider,
  String currentPath,
  AppLocalizations l10n,
) async {
  String selectedPath = currentPath;

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final parentPath = _getParentPath(selectedPath);

        return AlertDialog(
          title: Text(l10n.filesPathSelectorTitle),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current path display and navigation
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (selectedPath != '/')
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          tooltip: l10n.filesActionUp,
                          onPressed: () {
                            setDialogState(() {
                              selectedPath = parentPath;
                            });
                          },
                        ),
                      if (selectedPath == '/')
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.home),
                        ),
                      Expanded(
                        child: Text(
                          selectedPath,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<List<FileInfo>>(
                    future: provider.fetchFiles(selectedPath),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error),
                              const SizedBox(height: 8),
                              Text(l10n.commonError),
                            ],
                          ),
                        );
                      }

                      final allFiles = snapshot.data ?? [];
                      final folders = allFiles.where((f) => f.isDir).toList();
                      // Sort folders by name
                      folders.sort((a, b) => a.name.compareTo(b.name));

                      if (folders.isEmpty) {
                        return Center(child: Text(l10n.filesNoSubfolders));
                      }
                      return ListView.builder(
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          final folder = folders[index];
                          return ListTile(
                            leading:
                                const Icon(Icons.folder, color: Colors.amber),
                            title: Text(folder.name),
                            onTap: () {
                              setDialogState(() {
                                selectedPath = folder.path;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selectedPath),
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    ),
  );
}

String _getParentPath(String path) {
  if (path == '/') return '/';
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return '/';
  segments.removeLast();
  if (segments.isEmpty) return '/';
  return '/${segments.join('/')}';
}
