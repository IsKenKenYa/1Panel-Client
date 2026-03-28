import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/operations_center/widgets/server_operation_entry_card_widget.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';

class ToolboxCenterPage extends StatelessWidget {
  const ToolboxCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ServerAwarePageScaffold(
      title: l10n.toolboxCenterTitle,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.toolboxCenterIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ServerOperationEntryCardWidget(
            title: l10n.toolboxDeviceTitle,
            subtitle: l10n.toolboxDeviceCardSubtitle,
            icon: Icons.developer_board_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.toolboxDevice),
          ),
        ],
      ),
    );
  }
}
