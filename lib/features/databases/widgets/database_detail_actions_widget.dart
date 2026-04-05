import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/databases_provider.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

class DatabaseDetailActionsWidget extends StatelessWidget {
  const DatabaseDetailActionsWidget({super.key});

  void _showSubmitResult(BuildContext context, bool success) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? l10n.commonSaveSuccess : l10n.commonSaveFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseDetailProvider>();
    final item = provider.item;
    final l10n = context.l10n;

    if (!_supportsStandardActions(item.scope)) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: AppDesignTokens.spacingMd),
        AppCard(
          title: l10n.commonMore,
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.edit_outlined,
                title: l10n.commonEdit,
                subtitle: l10n.commonDescription,
                onTap: () => _showSingleInputDialog(
                  context,
                  title: l10n.commonDescription,
                  initialValue: item.description ?? '',
                  onSubmit: provider.updateDescription,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingSm),
              _ActionTile(
                icon: Icons.password_outlined,
                title: l10n.databaseChangePasswordAction,
                subtitle: item.lookupName,
                onTap: () => _showPasswordDialog(
                  context,
                  onSubmit: provider.changePassword,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingSm),
              _ActionTile(
                icon: Icons.person_add_alt_1_outlined,
                title: l10n.databaseBindUserAction,
                subtitle: item.name,
                onTap: () => _showBindUserDialog(
                  context,
                  onSubmit: provider.bindUser,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _supportsStandardActions(DatabaseScope scope) {
    return scope == DatabaseScope.mysql || scope == DatabaseScope.postgresql;
  }

  Future<void> _showSingleInputDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required Future<bool> Function(String) onSubmit,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await onSubmit(controller.text.trim());
              if (!context.mounted) return;
              _showSubmitResult(context, ok);
              if (ok) Navigator.of(context).pop();
            },
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasswordDialog(
    BuildContext context, {
    required Future<bool> Function(String) onSubmit,
  }) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.databaseChangePasswordAction),
        content: TextField(
          controller: controller,
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await onSubmit(controller.text.trim());
              if (!context.mounted) return;
              _showSubmitResult(context, ok);
              if (ok) Navigator.of(context).pop();
            },
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _showBindUserDialog(
    BuildContext context, {
    required Future<bool> Function({
      required String username,
      required String password,
    }) onSubmit,
  }) async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.databaseBindUserAction),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                  labelText: context.l10n.databaseUsernameLabel),
            ),
            const SizedBox(height: AppDesignTokens.spacingSm),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: context.l10n.databasePasswordLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await onSubmit(
                username: usernameController.text.trim(),
                password: passwordController.text.trim(),
              );
              if (!context.mounted) return;
              _showSubmitResult(context, ok);
              if (ok) Navigator.of(context).pop();
            },
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.onSecondaryContainer, size: 20),
              ),
              const SizedBox(width: AppDesignTokens.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
