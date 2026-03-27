import 'package:flutter/material.dart';

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isVerified ? 'Verified' : 'Not verified',
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
              label: Text(isTesting ? 'Testing...' : 'Test connection'),
            ),
          ],
        ),
      ),
    );
  }
}
