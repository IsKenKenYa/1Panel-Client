import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class SshRawFileEditorWidget extends StatelessWidget {
  const SshRawFileEditorWidget({
    super.key,
    required this.controller,
    required this.isBusy,
    required this.onReload,
    required this.onCopy,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool isBusy;
  final Future<void> Function() onReload;
  final Future<void> Function() onCopy;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  l10n.sshSettingsRawFileSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: isBusy ? null : onCopy,
                  child: Text(l10n.commonCopy),
                ),
                TextButton(
                  onPressed: isBusy ? null : onReload,
                  child: Text(l10n.sshReloadAction),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              minLines: 12,
              maxLines: 20,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: l10n.sshRawFilePlaceholder,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isBusy ? null : onSave,
                child: Text(l10n.commonSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
