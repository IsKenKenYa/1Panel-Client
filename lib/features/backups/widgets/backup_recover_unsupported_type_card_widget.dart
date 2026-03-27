import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class BackupRecoverUnsupportedTypeCardWidget extends StatelessWidget {
  const BackupRecoverUnsupportedTypeCardWidget({
    super.key,
    required this.typeLabel,
    required this.name,
    required this.detailName,
  });

  final String typeLabel;
  final String name;
  final String detailName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${l10n.backupRecoverTypeLabel}: $typeLabel',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (name.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text('${l10n.backupRecordsNameLabel}: $name'),
            ],
            if (detailName.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text('${l10n.backupRecordsDetailNameLabel}: $detailName'),
            ],
            const SizedBox(height: 8),
            Text(l10n.backupRecoverUnsupportedTypeHint(typeLabel)),
          ],
        ),
      ),
    );
  }
}
