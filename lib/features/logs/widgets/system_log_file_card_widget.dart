import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class SystemLogFileCardWidget extends StatelessWidget {
  const SystemLogFileCardWidget({
    super.key,
    required this.fileName,
    required this.onOpen,
  });

  final String fileName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        title: Text(fileName),
        trailing: FilledButton.tonal(
          onPressed: onOpen,
          child: Text(l10n.logsSystemOpenViewerAction),
        ),
      ),
    );
  }
}
