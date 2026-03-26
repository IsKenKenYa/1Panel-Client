import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';

class StageOneModulePlaceholderPage extends StatelessWidget {
  const StageOneModulePlaceholderPage({
    super.key,
    required this.title,
    required this.availableInWeek,
  });

  final String title;
  final int availableInWeek;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ServerAwarePageScaffold(
      title: title,
      body: ModuleEmptyStateWidget(
        title: title,
        description: l10n.operationsPlaceholderDescription(
          title,
          availableInWeek,
        ),
        icon: Icons.construction_outlined,
        actionLabel: l10n.operationsPlaceholderBackAction,
        onAction: () => Navigator.pushReplacementNamed(
          context,
          AppRoutes.operations,
        ),
      ),
    );
  }
}
