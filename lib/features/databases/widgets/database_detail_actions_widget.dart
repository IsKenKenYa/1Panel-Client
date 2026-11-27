import 'package:flutter/material.dart';
import 'database_tile_content.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/databases_provider.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

import '../../../core/utils/snackbar_utils.dart';

class DatabaseDetailActionsWidget extends StatelessWidget {
  const DatabaseDetailActionsWidget({super.key});

  void _showSubmitResult(BuildContext context, bool success) {
    final l10n = context.l10n;
    if (success) {
      SnackBarUtils.showSuccess(context, l10n.commonSaveSuccess);
    } else {
      SnackBarUtils.showError(context, l10n.commonSaveFailed);
    }
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
        SectionCard(
          title: l10n.commonMore,
          padding: AppDesignTokens.cardPadding,
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
    await showAppTextInputDialog(
      context,
      title: title,
      initialValue: initialValue,
      autofocus: false,
      allowEmpty: true,
      confirmLabel: context.l10n.commonSave,
      onSubmit: (value) async {
        final ok = await onSubmit(value);
        if (context.mounted) _showSubmitResult(context, ok);
        return ok;
      },
    );
  }

  Future<void> _showPasswordDialog(
    BuildContext context, {
    required Future<bool> Function(String) onSubmit,
  }) async {
    await showAppTextInputDialog(
      context,
      title: context.l10n.databaseChangePasswordAction,
      obscureText: true,
      autofocus: false,
      allowEmpty: true,
      onSubmit: (value) async {
        final ok = await onSubmit(value);
        if (context.mounted) _showSubmitResult(context, ok);
        return ok;
      },
    );
  }

  Future<void> _showBindUserDialog(
    BuildContext context, {
    required Future<bool> Function({
      required String username,
      required String password,
    }) onSubmit,
  }) async {
    await showAdaptiveFormPanel<void>(
      context,
      builder: (context) => _BindUserForm(
        onSubmit: ({required username, required password}) async {
          final ok = await onSubmit(username: username, password: password);
          if (context.mounted) _showSubmitResult(context, ok);
          return ok;
        },
      ),
    );
  }
}

class _BindUserForm extends StatefulWidget {
  const _BindUserForm({required this.onSubmit});

  final Future<bool> Function({
    required String username,
    required String password,
  }) onSubmit;

  @override
  State<_BindUserForm> createState() => _BindUserFormState();
}

class _BindUserFormState extends State<_BindUserForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final ok = await widget.onSubmit(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (ok && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.databaseBindUserAction,
      isSaving: _saving,
      onConfirm: _submit,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            enabled: !_saving,
            decoration: InputDecoration(labelText: l10n.databaseUsernameLabel),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          TextField(
            controller: _passwordController,
            enabled: !_saving,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.databasePasswordLabel),
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
          child: DatabaseTileContent.action(
            icon: icon,
            title: title,
            subtitle: subtitle,
          ),
        ),
      ),
    );
  }
}
