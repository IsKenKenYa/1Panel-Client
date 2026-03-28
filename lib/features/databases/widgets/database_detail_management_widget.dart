import 'package:flutter/material.dart';

import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/database_support.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

class DatabaseDetailManagementWidget extends StatelessWidget {
  const DatabaseDetailManagementWidget({
    super.key,
    required this.item,
  });

  final DatabaseListItem item;

  @override
  Widget build(BuildContext context) {
    final supportsBackups = databaseSupportsBackups(item.scope);
    final supportsUsers = databaseSupportsUserManagement(item.scope);
    if (!supportsBackups && !supportsUsers) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    return Column(
      children: [
        const SizedBox(height: AppDesignTokens.spacingMd),
        AppCard(
          title: l10n.databaseManageTitle,
          child: Wrap(
            spacing: AppDesignTokens.spacingSm,
            runSpacing: AppDesignTokens.spacingSm,
            children: [
              if (supportsBackups)
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.databaseBackups,
                    arguments: item,
                  ),
                  icon: const Icon(Icons.backup_outlined),
                  label: Text(l10n.databaseBackupsPageTitle),
                ),
              if (supportsUsers)
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.databaseUsers,
                    arguments: item,
                  ),
                  icon: const Icon(Icons.manage_accounts_outlined),
                  label: Text(l10n.databaseUsersPageTitle),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
