import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

class FirewallV2DataView extends StatelessWidget {
  const FirewallV2DataView({
    super.key,
    required this.data,
    required this.onRetry,
  });

  final Map<String, dynamic> data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (data.isEmpty) {
      return Center(child: Text(l10n.firewallV2Empty));
    }
    final entries = data.entries.toList();
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Card(
            child: ListTile(
              title: Text(entry.key),
              subtitle: Text(entry.value.toString()),
            ),
          );
        },
      ),
    );
  }
}

class FirewallV2ErrorView extends StatelessWidget {
  const FirewallV2ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ModuleErrorStateWidget(message: message, onRetry: onRetry);
  }
}
