import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

class DatabaseUserCurrentCardWidget extends StatelessWidget {
  const DatabaseUserCurrentCardWidget({
    super.key,
    required this.currentUsername,
  });

  final String? currentUsername;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      title: l10n.databaseUserCurrentLabel,
      padding: AppDesignTokens.cardPadding,
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
    return SectionCard(
      title: l10n.databaseBindUserAction,
      padding: AppDesignTokens.cardPadding,
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
    return SectionCard(
      title: l10n.databaseUserPrivilegesAction,
      padding: AppDesignTokens.cardPadding,
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

/// V2 新体系：MySQL 用户列表卡（/databases/users/search）。
class DatabaseUserListCardWidget extends StatelessWidget {
  const DatabaseUserListCardWidget({
    super.key,
    required this.users,
    required this.onChangePassword,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> users;
  final void Function(Map<String, dynamic> user) onChangePassword;
  final void Function(Map<String, dynamic> user) onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      title: l10n.databaseUserListTitle,
      padding: AppDesignTokens.cardPadding,
      child: users.isEmpty
          ? Text(l10n.commonEmpty)
          : Column(
              children: [
                for (final user in users)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text(user['username']?.toString() ?? '-'),
                    subtitle: Text(
                      '${user['host'] ?? '-'}'
                      '${(user['description']?.toString() ?? '').isNotEmpty ? ' · ${user['description']}' : ''}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'password') onChangePassword(user);
                        if (value == 'delete') onDelete(user);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'password',
                          child: Text(l10n.databaseUserChangePassword),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.commonDelete),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
