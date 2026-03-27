import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_draft.dart';

class RuntimeFormAdvancedSectionWidget extends StatelessWidget {
  const RuntimeFormAdvancedSectionWidget({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final RuntimeFormDraft draft;
  final void Function({
    String? remark,
    bool? rebuild,
  }) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        TextFormField(
          initialValue: draft.remark,
          maxLines: 3,
          onChanged: (value) => onChanged(remark: value),
          decoration: InputDecoration(labelText: l10n.runtimeFieldRemark),
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: draft.rebuild,
          onChanged: (value) => onChanged(rebuild: value),
          title: Text(l10n.runtimeFieldRebuild),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.runtimeAdvancedSummary(
            draft.exposedPorts.length,
            draft.environments.length,
            draft.volumes.length,
            draft.extraHosts.length,
          ),
        ),
      ],
    );
  }
}
