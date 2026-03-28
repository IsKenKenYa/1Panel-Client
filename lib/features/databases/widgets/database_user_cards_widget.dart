import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

class DatabaseUserCurrentCardWidget extends StatelessWidget {
  const DatabaseUserCurrentCardWidget({
    super.key,
    required this.currentUsername,
  });

  final String? currentUsername;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      title: l10n.databaseUserCurrentLabel,
      child: Text(
        currentUsername?.isNotEmpty == true
            ? currentUsername!
            : l10n.databaseUserNoBinding,
      ),
    );
  }
}

class DatabaseBindUserCardWidget extends StatelessWidget {
  const DatabaseBindUserCardWidget({
    super.key,
    required this.item,
    required this.usernameController,
    required this.passwordController,
    required this.permissionController,
    required this.bindSuperUser,
    required this.onBindSuperUserChanged,
    required this.onSubmit,
  });

  final DatabaseListItem item;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController permissionController;
  final bool bindSuperUser;
  final ValueChanged<bool> onBindSuperUserChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      title: l10n.databaseBindUserAction,
      child: Column(
        children: [
          TextField(
            controller: usernameController,
            decoration: InputDecoration(labelText: l10n.databaseUsernameLabel),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.databasePasswordLabel),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          if (item.scope == DatabaseScope.mysql)
            TextField(
              controller: permissionController,
              decoration:
                  InputDecoration(labelText: l10n.databaseUserPermissionLabel),
            ),
          if (item.scope == DatabaseScope.postgresql)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.databaseUserSuperUserLabel),
              value: bindSuperUser,
              onChanged: onBindSuperUserChanged,
            ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onSubmit,
              child: Text(l10n.databaseUserBindAction),
            ),
          ),
        ],
      ),
    );
  }
}

class DatabasePrivilegeCardWidget extends StatelessWidget {
  const DatabasePrivilegeCardWidget({
    super.key,
    required this.currentUsername,
    required this.privilegeSuperUser,
    required this.onPrivilegeChanged,
    required this.onSubmit,
  });

  final String? currentUsername;
  final bool privilegeSuperUser;
  final ValueChanged<bool> onPrivilegeChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      title: l10n.databaseUserPrivilegesAction,
      child: currentUsername?.isNotEmpty == true
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l10n.databaseUsernameLabel}: $currentUsername'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.databaseUserSuperUserLabel),
                  value: privilegeSuperUser,
                  onChanged: onPrivilegeChanged,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onSubmit,
                    child: Text(l10n.databaseUserPrivilegesAction),
                  ),
                ),
              ],
            )
          : Text(l10n.databasePrivilegeUnavailable),
    );
  }
}
