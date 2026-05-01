import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';

class DesktopTopToolArea extends StatelessWidget {
  const DesktopTopToolArea({
    super.key,
    required this.selectedModule,
    this.onOpenSettings,
    this.backgroundColor,
  });

  final ClientModule selectedModule;
  final VoidCallback? onOpenSettings;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = selectedModule.label(context.l10n);
    final bgColor = backgroundColor ?? scheme.surface;

    return Material(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              const ServerSwitcherAction(),
              const SizedBox(width: 4),
              IconButton(
                tooltip: context.l10n.settingsPageTitle,
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
