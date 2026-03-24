import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

class FilePropertiesDialog extends StatefulWidget {
  final FilesProvider provider;
  final FileInfo file;

  const FilePropertiesDialog({
    super.key,
    required this.provider,
    required this.file,
  });

  @override
  State<FilePropertiesDialog> createState() => _FilePropertiesDialogState();
}

class _FilePropertiesDialogState extends State<FilePropertiesDialog> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.filesPropertiesTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildContent(context, l10n, theme),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, dynamic l10n, ThemeData theme) {
    final props = widget.file;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPropertyItem(context, l10n.filesNameLabel, props.name, copyable: true),
          _buildPropertyItem(context, l10n.filesPathLabel, props.path, copyable: true),
          _buildPropertyItem(context, l10n.filesTypeLabel, props.type),
          _buildPropertyItem(context, l10n.filesSizeLabel, _formatSize(props.size)),
          if (props.mimeType != null)
            _buildPropertyItem(context, 'MIME Type', props.mimeType!),
          const Divider(),
          if (props.permission != null)
            _buildPropertyItem(
              context,
              l10n.filesPermissionTitle,
              props.user != null && props.group != null
                  ? '${props.permission} (${props.user}:${props.group})'
                  : props.permission!,
            ),
          if (props.createdAt != null)
            _buildPropertyItem(context, l10n.filesCreatedLabel, dateFormat.format(props.createdAt!)),
          if (props.modifiedAt != null)
            _buildPropertyItem(context, l10n.filesModifiedLabel, dateFormat.format(props.modifiedAt!)),
        ],
      ),
    );
  }

  Widget _buildPropertyItem(
    BuildContext context,
    String label,
    String value, {
    bool copyable = false,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (copyable)
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.commonCopySuccess)),
                    );
                  },
                  tooltip: context.l10n.commonCopy,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

void showFilePropertiesDialog(BuildContext context, FilesProvider provider, FileInfo file) {
  showDialog(
    context: context,
    builder: (context) => FilePropertiesDialog(
      provider: provider,
      file: file,
    ),
  );
}
