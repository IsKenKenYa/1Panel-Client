import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';

class SshSessionCardWidget extends StatelessWidget {
  const SshSessionCardWidget({
    super.key,
    required this.item,
    required this.onDisconnect,
  });

  final SshSessionInfo item;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(item.username, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${l10n.sshSessionsTerminalLabel}: ${item.terminal}'),
            Text('${l10n.sshSessionsHostLabel}: ${item.host}'),
            Text('${l10n.sshSessionsLoginTimeLabel}: ${item.loginTime}'),
            Text('PID: ${item.pid}'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onDisconnect,
              child: Text(l10n.commonStop),
            ),
          ],
        ),
      ),
    );
  }
}
