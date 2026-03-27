import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_draft.dart';
import 'package:onepanel_client/features/runtimes/services/runtime_service.dart';
import 'package:onepanel_client/features/runtimes/utils/runtime_l10n_helper.dart';

class RuntimeFormBasicSectionWidget extends StatelessWidget {
  const RuntimeFormBasicSectionWidget({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final RuntimeFormDraft draft;
  final void Function({
    String? type,
    String? name,
    String? resource,
    String? version,
  }) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        TextFormField(
          initialValue: draft.name,
          onChanged: (value) => onChanged(name: value),
          decoration: InputDecoration(labelText: l10n.commonName),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: draft.type,
          decoration: InputDecoration(labelText: l10n.runtimeFieldType),
          items: RuntimeService.orderedTypes
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(runtimeTypeLabel(l10n, item)),
                ),
              )
              .toList(growable: false),
          onChanged: draft.isEditing
              ? null
              : (value) {
                  if (value != null) {
                    onChanged(type: value);
                  }
                },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: draft.resource,
          decoration: InputDecoration(labelText: l10n.runtimeFieldResource),
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: 'local',
              child: Text(l10n.runtimeResourceLocal),
            ),
            DropdownMenuItem<String>(
              value: 'appstore',
              child: Text(l10n.runtimeResourceAppStore),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onChanged(resource: value);
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: draft.version,
          onChanged: (value) => onChanged(version: value),
          decoration: InputDecoration(labelText: l10n.runtimeFieldVersion),
        ),
      ],
    );
  }
}
