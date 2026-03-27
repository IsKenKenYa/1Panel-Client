import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_draft.dart';

class RuntimeFormRuntimeSectionWidget extends StatelessWidget {
  const RuntimeFormRuntimeSectionWidget({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final RuntimeFormDraft draft;
  final void Function({
    String? image,
    String? codeDir,
    int? port,
    String? source,
    String? hostIp,
    String? containerName,
    String? execScript,
    String? packageManager,
  }) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        TextFormField(
          initialValue: draft.image,
          onChanged: (value) => onChanged(image: value),
          decoration: InputDecoration(labelText: l10n.runtimeFieldImage),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: draft.codeDir,
          onChanged: (value) => onChanged(codeDir: value),
          decoration: InputDecoration(labelText: l10n.runtimeFieldCodeDir),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: draft.port.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) => onChanged(port: int.tryParse(value) ?? 0),
          decoration: InputDecoration(labelText: l10n.runtimeFieldExternalPort),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: draft.source,
          onChanged: (value) => onChanged(source: value),
          decoration: InputDecoration(labelText: l10n.runtimeFieldSource),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: draft.hostIp,
          onChanged: (value) => onChanged(hostIp: value),
          decoration: InputDecoration(labelText: l10n.runtimeFieldHostIp),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: draft.containerName,
          onChanged: (value) => onChanged(containerName: value),
          decoration:
              InputDecoration(labelText: l10n.runtimeFieldContainerName),
        ),
        if (!draft.isPhp) ...<Widget>[
          const SizedBox(height: 16),
          TextFormField(
            initialValue: draft.execScript,
            onChanged: (value) => onChanged(execScript: value),
            decoration: InputDecoration(labelText: l10n.runtimeFieldExecScript),
          ),
        ],
        if (draft.isNode) ...<Widget>[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: draft.packageManager,
            decoration: InputDecoration(
              labelText: l10n.runtimeFieldPackageManager,
            ),
            items: const <String>['npm', 'yarn', 'pnpm']
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                onChanged(packageManager: value);
              }
            },
          ),
        ],
      ],
    );
  }
}
