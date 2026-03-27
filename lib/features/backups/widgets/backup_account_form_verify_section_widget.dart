import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class BackupAccountFormVerifySectionWidget extends StatelessWidget {
  const BackupAccountFormVerifySectionWidget({
    super.key,
    required this.isTesting,
    required this.isVerified,
    required this.testMessage,
    required this.onTest,
  });

  final bool isTesting;
  final bool isVerified;
  final String? testMessage;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isVerified
                  ? l10n.backupFormVerifiedLabel
                  : l10n.backupFormNotVerifiedLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (testMessage?.isNotEmpty == true) ...<Widget>[
              const SizedBox(height: 8),
              Text(testMessage!),
            ],
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: isTesting ? null : onTest,
              icon: const Icon(Icons.network_check_outlined),
              label: Text(
                isTesting
                    ? l10n.backupFormTestingLabel
                    : l10n.backupFormTestConnectionAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
