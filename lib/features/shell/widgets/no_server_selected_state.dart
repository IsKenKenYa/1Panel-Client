import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';

class NoServerSelectedState extends StatelessWidget {
  const NoServerSelectedState({
    super.key,
    required this.moduleName,
  });

  final String moduleName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dns_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noServerSelectedTitle(moduleName),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noServerSelectedDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => ServerSwitcherAction.showServerPicker(context),
              icon: const Icon(Icons.swap_horiz),
              label: Text(l10n.serverActionSwitch),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  openRouteRespectingShell(context, AppRoutes.server),
              child: Text(l10n.serverPageTitle),
            ),
          ],
        ),
      ),
    );
  }
}
