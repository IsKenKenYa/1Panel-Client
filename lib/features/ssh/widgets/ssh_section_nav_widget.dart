import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class SshSectionNavWidget extends StatelessWidget {
  const SshSectionNavWidget({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <({String route, String label})>[
      (route: AppRoutes.ssh, label: l10n.operationsSshTitle),
      (route: AppRoutes.sshCerts, label: l10n.operationsSshCertsTitle),
      (route: AppRoutes.sshLogs, label: l10n.operationsSshLogsTitle),
      (route: AppRoutes.sshSessions, label: l10n.operationsSshSessionsTitle),
      (route: AppRoutes.terminal, label: l10n.serverModuleTerminal),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final isSelected = currentRoute == item.route;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item.label),
              selected: isSelected,
              onSelected: isSelected
                  ? null
                  : (_) => Navigator.pushReplacementNamed(context, item.route),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
