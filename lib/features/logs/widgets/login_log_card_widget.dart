import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/logs_models.dart';

class LoginLogCardWidget extends StatelessWidget {
  const LoginLogCardWidget({
    super.key,
    required this.item,
    required this.onCopy,
  });

  final LoginLogEntry item;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        title: Text(item.ip ?? '-'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if ((item.address ?? '').isNotEmpty) Text(item.address!),
            if ((item.agent ?? '').isNotEmpty) Text(item.agent!),
            if ((item.status ?? '').isNotEmpty)
              Text('${l10n.logsTaskDetailStatusLabel}: ${item.status}'),
            if ((item.createdAt ?? '').isNotEmpty)
              Text('${l10n.logsTaskDetailCreatedAtLabel}: ${item.createdAt}'),
          ],
        ),
        trailing: IconButton(
          onPressed: onCopy,
          tooltip: l10n.commonCopy,
          icon: const Icon(Icons.copy_outlined),
        ),
      ),
    );
  }
}
