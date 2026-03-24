part of 'package:onepanelapp_app/features/files/files_page.dart';

extension _FilesViewItemHelpers on _FilesViewState {
  IconData _getFileIcon(String fileName) {
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

  Color _getFileIconColor(String fileName, ColorScheme colorScheme) {
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String? _formatModifiedAt(DateTime? time) {
    if (time == null) return null;
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  bool _isCompressedFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['zip', 'tar', 'gz', 'bz2', 'xz', '7z', 'rar'].contains(ext);
  }
}
