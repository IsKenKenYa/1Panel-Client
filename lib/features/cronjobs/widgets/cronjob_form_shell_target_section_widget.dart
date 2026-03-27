import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';

class CronjobFormShellTargetSectionWidget extends StatelessWidget {
  const CronjobFormShellTargetSectionWidget({
    super.key,
    required this.executor,
    required this.user,
    required this.scriptMode,
    required this.script,
    required this.scriptID,
    required this.scriptOptions,
    required this.onExecutorChanged,
    required this.onUserChanged,
    required this.onScriptModeChanged,
    required this.onScriptChanged,
    required this.onScriptIdChanged,
  });

  final String executor;
  final String user;
  final String scriptMode;
  final String script;
  final int? scriptID;
  final List<CronjobScriptOption> scriptOptions;
  final ValueChanged<String> onExecutorChanged;
  final ValueChanged<String> onUserChanged;
  final ValueChanged<String> onScriptModeChanged;
  final ValueChanged<String> onScriptChanged;
  final ValueChanged<int?> onScriptIdChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        TextFormField(
          key: ValueKey<String>('shell-executor-$executor'),
          initialValue: executor,
          onChanged: onExecutorChanged,
          decoration: InputDecoration(labelText: l10n.cronjobFormExecutorLabel),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey<String>('shell-user-$user'),
          initialValue: user,
          onChanged: onUserChanged,
          decoration: InputDecoration(labelText: l10n.cronjobFormUserLabel),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: <ButtonSegment<String>>[
            ButtonSegment(
              value: 'input',
              label: Text(l10n.cronjobFormShellModeInline),
            ),
            ButtonSegment(
              value: 'library',
              label: Text(l10n.cronjobFormShellModeLibrary),
            ),
            ButtonSegment(
              value: 'select',
              label: Text(l10n.cronjobFormShellModePath),
            ),
          ],
          selected: <String>{scriptMode},
          onSelectionChanged: (Set<String> values) {
            onScriptModeChanged(values.first);
          },
        ),
        const SizedBox(height: 12),
        if (scriptMode == 'library')
          DropdownButtonFormField<int>(
            initialValue: scriptID,
            decoration:
                InputDecoration(labelText: l10n.cronjobFormScriptLibraryLabel),
            items: scriptOptions
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  ),
                )
                .toList(growable: false),
            onChanged: onScriptIdChanged,
          )
        else
          TextFormField(
            key: ValueKey<String>('shell-script-$script-$scriptMode'),
            initialValue: script,
            onChanged: onScriptChanged,
            minLines: scriptMode == 'input' ? 6 : 1,
            maxLines: scriptMode == 'input' ? 10 : 1,
            decoration: InputDecoration(
              labelText: scriptMode == 'select'
                  ? l10n.cronjobFormScriptPathLabel
                  : l10n.cronjobFormScriptLabel,
            ),
          ),
      ],
    );
  }
}
