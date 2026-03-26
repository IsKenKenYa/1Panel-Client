import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ssh_cert_models.dart';

class SshCertCardWidget extends StatelessWidget {
  const SshCertCardWidget({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final SshCertInfo item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final createdAt = item.createdAt == null
        ? '-'
        : DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt!.toLocal());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(item.encryptionMode),
            if (item.description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(item.description),
            ],
            const SizedBox(height: 8),
            Text('${l10n.sshCertCreatedAtLabel}: $createdAt'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: onEdit,
                  child: Text(l10n.commonEdit),
                ),
                OutlinedButton(
                  onPressed: onDelete,
                  child: Text(l10n.commonDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
