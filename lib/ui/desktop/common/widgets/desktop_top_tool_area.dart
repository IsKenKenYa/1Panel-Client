import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';

class DesktopTopToolArea extends StatelessWidget {
  const DesktopTopToolArea({
    super.key,
    required this.selectedModule,
    this.showMenuButton = false,
    this.onOpenSettings,
    this.backgroundColor,
  });

  final ClientModule selectedModule;
  final bool showMenuButton;
  final VoidCallback? onOpenSettings;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayoutViewport(child: Builder(builder: _buildToolbar));
  }

  Widget _buildToolbar(BuildContext context) {
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
              if (showMenuButton)
                IconButton(
                  tooltip:
                      MaterialLocalizations.of(context).openAppDrawerTooltip,
                  onPressed: Scaffold.of(context).openDrawer,
                  icon: const Icon(Icons.menu),
                ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
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
