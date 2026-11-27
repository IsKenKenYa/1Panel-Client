import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

Future<String?> showPathSelectorDialog(
  BuildContext context,
  FilesProvider provider,
  String currentPath,
  AppLocalizations l10n,
) async {
  String selectedPath = currentPath;
  var files = provider.fetchFiles(selectedPath);

  return showAdaptiveFormPanel<String>(
    context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final parentPath = _getParentPath(selectedPath);

        return AppFormPanel(
          title: l10n.filesPathSelectorTitle,
          onConfirm: () async => Navigator.pop(dialogContext, selectedPath),
          content: SizedBox(
            width: AdaptiveLayoutSpec.of(context).dialogConstraints.maxWidth,
            height: math.min(400.0, MediaQuery.sizeOf(context).height * 0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (selectedPath != '/')
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          tooltip: l10n.filesActionUp,
                          style: IconButton.styleFrom(
                            minimumSize: const Size.square(
                              kMinInteractiveDimension,
                            ),
                            visualDensity: VisualDensity.standard,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectedPath = parentPath;
                              files = provider.fetchFiles(selectedPath);
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
                    future: files,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 8),
                              Text(l10n.commonError),
                            ],
                          ),
                        );
                      }

                      final allFiles = snapshot.data ?? [];
                      final folders = allFiles.where((f) => f.isDir).toList();
                      folders.sort((a, b) => a.name.compareTo(b.name));

                      if (folders.isEmpty) {
                        return Center(child: Text(l10n.filesNoSubfolders));
                      }
                      return ListView.builder(
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          final folder = folders[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.folder,
                              color: Colors.amber,
                            ),
                            title: Text(folder.name),
                            minTileHeight: kMinInteractiveDimension,
                            visualDensity: VisualDensity.standard,
                            onTap: () {
                              setDialogState(() {
                                selectedPath = folder.path;
                                files = provider.fetchFiles(selectedPath);
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
        );
      },
    ),
  );
}

String _getParentPath(String path) {
  if (path == '/') {
    return '/';
  }
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) {
    return '/';
  }
  segments.removeLast();
  if (segments.isEmpty) {
    return '/';
  }
  return '/${segments.join('/')}';
}
