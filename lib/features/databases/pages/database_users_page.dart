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
      appBar: AppBar(title: Text(l10n.databaseUsersPageTitle)),
      body: !databaseSupportsUserManagement(widget.item.scope)
          ? DatabasePageUnsupportedWidget(
              message: l10n.databaseUserUnsupported,
            )
          : state.isLoading && userContext == null
              ? const Center(child: CircularProgressIndicator())
              : state.error != null && userContext == null
                  ? DatabasePageErrorWidget(
                      error: state.error!,
                      onRetry: provider.load,
                    )
                  : ListView(
                      padding: AppDesignTokens.pagePadding,
                      children: [
                        DatabaseSummaryCardWidget(item: widget.item),
                        const SizedBox(height: AppDesignTokens.spacingMd),
                        DatabaseUserCurrentCardWidget(
                          currentUsername: currentUsername,
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: AppDesignTokens.spacingMd),
                          DatabasePageErrorWidget(
                            error: state.error!,
                            onRetry: provider.load,
                          ),
                        ],
                        const SizedBox(height: AppDesignTokens.spacingMd),
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

  Future<void> _submitPrivileges(
    BuildContext context,
    DatabaseUsersProvider provider,
  ) async {
    await provider.updatePrivileges(superUser: _privilegeSuperUser);
  }
}
