import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/website_group_models.dart';

class WebsiteLifecycleTextFieldCard extends StatelessWidget {
  const WebsiteLifecycleTextFieldCard({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class WebsiteLifecycleTypeCard extends StatelessWidget {
  const WebsiteLifecycleTypeCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration:
              InputDecoration(labelText: l10n.websitesLifecycleTypeLabel),
          items: [
            DropdownMenuItem(
              value: 'runtime',
              child: Text(l10n.websitesLifecycleTypeRuntime),
            ),
            DropdownMenuItem(
              value: 'proxy',
              child: Text(l10n.websitesLifecycleTypeProxy),
            ),
            DropdownMenuItem(
              value: 'subsite',
              child: Text(l10n.websitesLifecycleTypeSubsite),
            ),
            DropdownMenuItem(
              value: 'static',
              child: Text(l10n.websitesLifecycleTypeStatic),
            ),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

class WebsiteLifecycleGroupCard extends StatelessWidget {
  const WebsiteLifecycleGroupCard({
    super.key,
    required this.groups,
    required this.value,
    required this.onChanged,
  });

  final List<WebsiteGroup> groups;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<int>(
          initialValue: value,
          decoration: InputDecoration(labelText: l10n.websitesGroupLabel),
          items: [
            for (final group in groups)
              DropdownMenuItem(
                value: group.id,
                child: Text(group.name ?? '${group.id}'),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
