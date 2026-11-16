import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/database_support.dart';
import 'package:onepanel_client/features/databases/providers/database_users_provider.dart';
import 'package:onepanel_client/features/databases/services/database_user_service.dart';
import 'package:onepanel_client/features/databases/widgets/database_page_feedback_widget.dart';
import 'package:onepanel_client/features/databases/widgets/database_summary_card_widget.dart';
import 'package:onepanel_client/features/databases/widgets/database_user_cards_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';

class DatabaseUsersPage extends StatelessWidget {
  const DatabaseUsersPage({
    super.key,
    required this.item,
    this.service,
  });

  final DatabaseListItem item;
  final DatabaseUserService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DatabaseUsersProvider(
        item: item,
        service: service,
      )..load(),
      child: _DatabaseUsersPageView(item: item),
    );
  }
}

class _DatabaseUsersPageView extends StatefulWidget {
  const _DatabaseUsersPageView({required this.item});

  final DatabaseListItem item;

  @override
  State<_DatabaseUsersPageView> createState() => _DatabaseUsersPageViewState();
}

class _DatabaseUsersPageViewState extends State<_DatabaseUsersPageView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _permissionController = TextEditingController(text: '%');
  bool _bindSuperUser = false;
  bool _privilegeSuperUser = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _permissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseUsersProvider>();
    final l10n = context.l10n;
    final state = provider.state;
    final userContext = state.context;
    final currentUsername =
        userContext?.currentUsername ?? widget.item.username;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(l10n.databaseUsersPageTitle)),
      body: !databaseSupportsUserManagement(widget.item.scope)
          ? DatabasePageUnsupportedWidget(
              message: l10n.databaseUserUnsupported,
            )
          : state.isLoading && userContext == null
              ? const Center(child: CircularProgressIndicator())
              : state.error != null && userContext == null
                  ? ModuleErrorStateWidget(
                      message: state.error,
                      onRetry: provider.load,
                    )
                  : PartialErrorToastListener(
                      errorMessage: state.error,
                      hasCachedData: userContext != null,
                      onRetry: provider.load,
                      child: ListView(
                      padding: AppDesignTokens.scrollPagePadding(context),
                      children: [
                        DatabaseSummaryCardWidget(item: widget.item),
                        const SizedBox(height: AppDesignTokens.spacingMd),
                        DatabaseUserCurrentCardWidget(
                          currentUsername: currentUsername,
                        ),
                        const SizedBox(height: AppDesignTokens.spacingMd),
                        if (widget.item.scope == DatabaseScope.mysql) ...[
                          DatabaseUserListCardWidget(
                            users: state.users,
                            onChangePassword: (user) =>
                                _changePassword(context, provider, user),
                            onDelete: (user) =>
                                _deleteUser(context, provider, user),
                          ),
                          const SizedBox(height: AppDesignTokens.spacingMd),
                        ],
                        DatabaseBindUserCardWidget(
                          item: widget.item,
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          permissionController: _permissionController,
                          bindSuperUser: _bindSuperUser,
                          onBindSuperUserChanged: (value) {
                            setState(() => _bindSuperUser = value);
                          },
                          onSubmit: () => _submitBind(context, provider),
                        ),
                        if (databaseSupportsPrivilegeManagement(
                            widget.item.scope)) ...[
                          const SizedBox(height: AppDesignTokens.spacingMd),
                          DatabasePrivilegeCardWidget(
                            currentUsername: currentUsername,
                            privilegeSuperUser: _privilegeSuperUser,
                            onPrivilegeChanged: (value) {
                              setState(() => _privilegeSuperUser = value);
                            },
                            onSubmit: () => _submitPrivileges(
                              context,
                              provider,
                            ),
                          ),
                        ],
                      ],
                    ),
                    ),
    );
  }

  Future<void> _submitBind(
    BuildContext context,
    DatabaseUsersProvider provider,
  ) async {
    final ok = await provider.bindUser(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      permission: _permissionController.text.trim(),
      superUser: _bindSuperUser,
    );
    if (ok) {
      _usernameController.clear();
      _passwordController.clear();
      if (widget.item.scope == DatabaseScope.postgresql && mounted) {
        setState(() => _privilegeSuperUser = _bindSuperUser);
      }
    }
  }

  Future<void> _changePassword(
    BuildContext context,
    DatabaseUsersProvider provider,
    Map<String, dynamic> user,
  ) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.databaseUserChangePassword),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.databaseUserNewPasswordLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.isEmpty) return;
    await provider.changeMysqlUserPassword(user: user, password: password);
  }

  Future<void> _deleteUser(
    BuildContext context,
    DatabaseUsersProvider provider,
    Map<String, dynamic> user,
  ) async {
    final name = user['username']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.commonDelete),
        content: Text(context.l10n.databaseUserDeleteConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.deleteMysqlUser(user);
  }

  Future<void> _submitPrivileges(
    BuildContext context,
    DatabaseUsersProvider provider,
  ) async {
    await provider.updatePrivileges(superUser: _privilegeSuperUser);
  }
}
