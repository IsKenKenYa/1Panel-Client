import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ssh_log_models.dart';

class SshLogCardWidget extends StatelessWidget {
  const SshLogCardWidget({
    super.key,
    required this.item,
    required this.onCopy,
  });

  final SshLogEntry item;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timestamp = item.date == null
        ? '-'
        : DateFormat('yyyy-MM-dd HH:mm:ss').format(item.date!.toLocal());
    return Card(
      child: ListTile(
        title: Text('${item.address}:${item.port}'),
        subtitle: Text(
          '${item.user} · ${item.authMode} · ${item.status}\n'
          '${l10n.sshLogsTimeLabel}: $timestamp\n${item.message}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_all_outlined),
          tooltip: l10n.commonCopy,
        ),
      ),
    );
  }
}
