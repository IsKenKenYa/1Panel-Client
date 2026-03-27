import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class ScriptRunOutputSheetWidget extends StatelessWidget {
  const ScriptRunOutputSheetWidget({
    super.key,
    required this.title,
    required this.output,
    required this.isRunning,
    this.error,
  });

  final String title;
  final String output;
  final bool isRunning;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: output.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: output));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.commonCopySuccess),
                            ),
                          );
                        },
                  icon: const Icon(Icons.copy_all_outlined),
                  tooltip: context.l10n.commonCopy,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (error != null && error!.isNotEmpty)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (isRunning && output.isEmpty) ...<Widget>[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(context.l10n.scriptLibraryRunWaiting),
            ],
            if (!isRunning &&
                output.isEmpty &&
                (error == null || error!.isEmpty))
              Text(context.l10n.scriptLibraryRunNoOutput),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  output,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
