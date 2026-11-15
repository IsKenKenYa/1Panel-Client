import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/file_models.dart';

class FileListItem extends StatelessWidget {
  const FileListItem({
    super.key,
    required this.file,
    this.isSelected = false,
    this.isFavorite = false,
    this.onTap,
    this.onLongPress,
    this.onAction,
  });

  final FileInfo file;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(String action)? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final isDir = file.isDir;

    final metadata = <String>[
      isDir ? l10n.filesTypeDirectory : FileUtils.formatFileSize(file.size),
    ];
    final modifiedLabel = FileUtils.formatModifiedAt(file.modifiedAt);
    if (modifiedLabel != null) {
      metadata.add(modifiedLabel);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppDesignTokens.listCardGap),
      color: isSelected ? colorScheme.secondaryContainer : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        visualDensity: AdaptiveLayoutSpec.of(context).adaptiveDensity,
        // 文件图标放进 tonal 容器：M3 图标承载惯例，识别度高于裸图标。
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
            color: isDir
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
          ),
          alignment: Alignment.center,
          child: Icon(
            isDir
                ? Icons.folder_outlined
                : FileUtils.getFileIcon(file.name),
            color: isDir
                ? colorScheme.onPrimaryContainer
                : FileUtils.getFileIconColor(file.name, colorScheme),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(file.name)),
            if (isFavorite)
              Icon(
                Icons.star,
                size: 18,
                color: colorScheme.primary,
              ),
          ],
        ),
        subtitle: Text(
          metadata.join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: PopupMenuButton<String>(
          // 文件菜单超过 10 项，限制高度避免紧凑窗口下铺满全屏。
          constraints: const BoxConstraints(minWidth: 200, maxHeight: 420),
          onSelected: onAction,
          itemBuilder: (context) =>
              _buildMenuItems(context, l10n, colorScheme, isDir),
        ),
        onLongPress: onLongPress,
        onTap: onTap,
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    bool isDir,
  ) {
    return [
      if (isDir)
        PopupMenuItem(value: 'open', child: Text(l10n.filesActionOpen)),
      if (!isDir)
        PopupMenuItem(value: 'download', child: Text(l10n.filesActionDownload)),
      PopupMenuItem(
        value: 'favorite',
        child: Text(isFavorite
            ? l10n.filesRemoveFromFavorites
            : l10n.filesAddToFavorites),
      ),
      PopupMenuItem(value: 'rename', child: Text(l10n.filesActionRename)),
      PopupMenuItem(value: 'copy', child: Text(l10n.filesActionCopy)),
      PopupMenuItem(value: 'move', child: Text(l10n.filesActionMove)),
      if (!isDir && FileUtils.isCompressedFile(file.name))
        PopupMenuItem(value: 'extract', child: Text(l10n.filesActionExtract)),
      PopupMenuItem(value: 'compress', child: Text(l10n.filesActionCompress)),
      PopupMenuItem(
          value: 'permission', child: Text(l10n.filesPermissionTitle)),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'delete',
        child: Text(
          l10n.filesActionDelete,
          style: TextStyle(color: colorScheme.error),
        ),
      ),
    ];
  }
}

class FileUtils {
  FileUtils._();

  static IconData getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_outlined;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Icons.video_file_outlined;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file_outlined;
      case 'zip':
      case 'tar':
      case 'gz':
      case '7z':
      case 'rar':
        return Icons.folder_zip_outlined;
      case 'dart':
      case 'js':
      case 'ts':
      case 'py':
      case 'java':
      case 'swift':
      case 'kt':
        return Icons.code_outlined;
      case 'json':
      case 'yaml':
      case 'yml':
      case 'xml':
        return Icons.data_object_outlined;
      case 'md':
      case 'txt':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  static Color getFileIconColor(String fileName, ColorScheme colorScheme) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return colorScheme.error;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return colorScheme.primary;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return colorScheme.tertiary;
      case 'mp3':
      case 'wav':
      case 'flac':
        return colorScheme.secondary;
      case 'zip':
      case 'tar':
      case 'gz':
      case '7z':
      case 'rar':
        return colorScheme.tertiaryContainer;
      case 'dart':
        return colorScheme.primary;
      case 'js':
      case 'ts':
        return colorScheme.secondary;
      case 'py':
        return colorScheme.tertiary;
      case 'json':
      case 'yaml':
      case 'yml':
        return colorScheme.secondaryContainer;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Returns "YYYY-MM-DD HH:mm" — intentionally omits seconds to keep
  // the subtitle compact in file list items.
  static String? formatModifiedAt(DateTime? time) {
    if (time == null) return null;
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  static bool isCompressedFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['zip', 'tar', 'gz', 'bz2', 'xz', '7z', 'rar'].contains(ext);
  }
}
