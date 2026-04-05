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
          child: Column(
            children: [
              if (supportsBackups)
                _ManagementActionTile(
                  icon: Icons.backup_outlined,
                  title: l10n.databaseBackupsPageTitle,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.databaseBackups,
                    arguments: item,
                  ),
                ),
              if (supportsBackups && supportsUsers)
                const SizedBox(height: AppDesignTokens.spacingSm),
              if (supportsUsers)
                _ManagementActionTile(
                  icon: Icons.manage_accounts_outlined,
                  title: l10n.databaseUsersPageTitle,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.databaseUsers,
                    arguments: item,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManagementActionTile extends StatelessWidget {
  const _ManagementActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDesignTokens.spacingMd),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: AppDesignTokens.spacingSm),
              Expanded(child: Text(title)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
