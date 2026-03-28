import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/databases_provider.dart';

class DatabaseDetailActionsWidget extends StatelessWidget {
  const DatabaseDetailActionsWidget({super.key});

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
        Wrap(
          spacing: AppDesignTokens.spacingSm,
          runSpacing: AppDesignTokens.spacingSm,
          children: [
            OutlinedButton(
              onPressed: () => _showSingleInputDialog(
                context,
                title: l10n.commonDescription,
                initialValue: item.description ?? '',
                onSubmit: provider.updateDescription,
              ),
              child: Text(l10n.commonEdit),
            ),
            OutlinedButton(
              onPressed: () => _showPasswordDialog(
                context,
                onSubmit: provider.changePassword,
              ),
              child: Text(l10n.databaseChangePasswordAction),
            ),
            OutlinedButton(
              onPressed: () => _showBindUserDialog(
                context,
                onSubmit: provider.bindUser,
              ),
              child: Text(l10n.databaseBindUserAction),
            ),
          ],
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
              decoration:
                  InputDecoration(labelText: context.l10n.databaseUsernameLabel),
            ),
            const SizedBox(height: AppDesignTokens.spacingSm),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration:
                  InputDecoration(labelText: context.l10n.databasePasswordLabel),
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
              if (ok) Navigator.of(context).pop();
            },
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
  }
}
